-- devshell.lua: run project tools inside the project's direnv/devenv environment.
--
-- Why: language servers, formatters, test runners and debug adapters belong to the
-- project (its JDK, its Python, its node_modules). Neovim itself is started from
-- anywhere, often outside any devshell, and may have several projects open at once.
-- So instead of changing Neovim's own environment, every project tool is started
-- with the environment of the directory it belongs to.
--
-- How:
--   1. Find the nearest .envrc above the file (that is what direnv itself does).
--   2. Ask direnv for that directory's environment once (`direnv export json`) and
--      keep it in a cache. This is the same environment `direnv exec <dir>` would
--      give, but computed once per project instead of once per command (formatting
--      on save would otherwise pay the direnv startup cost every time).
--   3. Look the tool up on that environment's PATH and start it with that environment.
--   4. No .envrc, direnv missing, or .envrc not allowed: fall back to Neovim's PATH.
--      A blocked .envrc is reported; this module never runs `direnv allow`.

local M = {}

-- Set from Nix (default.nix) to the direnv in the Nix store; "direnv" as a fallback.
M.direnv = "direnv"

-- cache[envrc_dir] = { state = "loading"|"ready"|"blocked"|"denied"|"error",
--                      env = { VAR = value } (only the variables direnv changes),
--                      unset = { VAR = true }, err = "...", waiters = { fn, ... } }
local cache = {}
local warned = {} -- one-time warnings, keyed by text
local tools_by_ft = {} -- filled by M.register()

-- ---------------------------------------------------------------------------
-- Small helpers
-- ---------------------------------------------------------------------------

local function notify(msg, level)
  vim.schedule(function()
    vim.notify(msg, level or vim.log.levels.WARN, { title = "devshell" })
  end)
end

-- Warn only once per message, so a missing tool does not spam every buffer.
local function warn_once(msg)
  if warned[msg] then
    return
  end
  warned[msg] = true
  notify(msg)
end

-- Directory of a buffer number, file path or directory path.
local function dir_of(where)
  if where == nil or where == 0 then
    where = vim.api.nvim_get_current_buf()
  end
  if type(where) == "number" then
    where = vim.api.nvim_buf_get_name(where)
  end
  if where == "" then
    return vim.uv.cwd()
  end
  if vim.fn.isdirectory(where) == 1 then
    return vim.fs.normalize(where)
  end
  return vim.fs.dirname(vim.fs.normalize(where))
end

-- Nearest directory (upwards) that has an .envrc, or nil.
function M.envrc_dir(where)
  local found = vim.fs.find(".envrc", { upward = true, path = dir_of(where), type = "file" })[1]
  return found and vim.fs.dirname(found) or nil
end

-- ---------------------------------------------------------------------------
-- Loading environments
-- ---------------------------------------------------------------------------

local function finish(entry)
  local waiters = entry.waiters or {}
  entry.waiters = nil
  for _, fn in ipairs(waiters) do
    fn(entry)
  end
end

local function first_line(s)
  return (vim.split(vim.trim(s or ""), "\n")[1] or ""):gsub("\27%[[%d;]*m", "")
end

-- Step 2: export the environment (only called for an allowed .envrc).
local function export_env(dir, entry)
  vim.system({ M.direnv, "export", "json" }, { cwd = dir, text = true }, function(res)
    if res.code ~= 0 then
      entry.state, entry.err = "error", first_line(res.stderr)
      notify(("Loading %s/.envrc failed: %s\nUsing Neovim's PATH instead."):format(dir, entry.err))
      return vim.schedule(function()
        finish(entry)
      end)
    end
    local ok, diff = pcall(vim.json.decode, res.stdout ~= "" and res.stdout or "{}")
    entry.env, entry.unset = {}, {}
    for k, v in pairs(ok and diff or {}) do
      if v == vim.NIL then
        entry.unset[k] = true
      else
        entry.env[k] = v
      end
    end
    entry.state = "ready"
    vim.schedule(function()
      finish(entry)
    end)
  end)
end

-- Load (or reuse) the environment for `where`, then call cb(entry).
-- cb gets nil when there is no .envrc: use Neovim's own environment.
function M.load(where, cb)
  cb = cb or function() end
  local dir = M.envrc_dir(where)
  if not dir then
    return cb(nil)
  end
  local entry = cache[dir]
  if entry and entry.state ~= "loading" then
    return cb(entry)
  end
  if entry then -- already loading: wait for it
    table.insert(entry.waiters, cb)
    return
  end
  entry = { dir = dir, state = "loading", waiters = { cb } }
  cache[dir] = entry

  if vim.fn.executable(M.direnv) ~= 1 then
    entry.state, entry.err = "error", "direnv is not installed"
    warn_once("direnv not found; project tools use Neovim's PATH.")
    return finish(entry)
  end

  -- Step 1: is the .envrc allowed? `direnv status --json` answers without running it.
  vim.system({ M.direnv, "status", "--json" }, { cwd = dir, text = true }, function(res)
    local ok, status = pcall(vim.json.decode, res.stdout or "")
    local rc = ok and status.state and status.state.foundRC
    local allowed = rc and rc ~= vim.NIL and rc.allowed
    if allowed == 0 then
      return export_env(dir, entry)
    end
    entry.state = allowed == 2 and "denied" or "blocked"
    warn_once(
      ("%s/.envrc is not allowed, so project tools use Neovim's PATH.\nRun `direnv allow` in %s, then :DevshellReload.")
        :format(dir, dir)
    )
    vim.schedule(function()
      finish(entry)
    end)
  end)
end

-- Cached entry without waiting. Starts loading in the background if needed.
-- Returns nil when there is no .envrc or it is still loading.
function M.get(where)
  local dir = M.envrc_dir(where)
  if not dir then
    return nil
  end
  local entry = cache[dir]
  if not entry then
    M.load(where)
    return nil
  end
  return entry.state == "ready" and entry or nil
end

-- Variables to add when starting a process (vim.system / LSP merge them into
-- Neovim's environment). nil = nothing to add.
function M.env(where)
  local entry = M.get(where)
  return entry and entry.env or nil
end

-- The complete environment as a table, for APIs that replace the environment
-- instead of extending it (nvim-dap). Variables direnv unsets are removed.
function M.full_env(where)
  local env = vim.fn.environ()
  local entry = M.get(where)
  if entry then
    for k in pairs(entry.unset) do
      env[k] = nil
    end
    for k, v in pairs(entry.env) do
      env[k] = v
    end
  end
  return env
end

-- ---------------------------------------------------------------------------
-- Finding tools
-- ---------------------------------------------------------------------------

-- Absolute path of `bin` on the PATH of `env_path`, or nil.
local function search_path(bin, env_path)
  if bin:find("/") then
    return vim.fn.executable(bin) == 1 and bin or nil
  end
  for _, d in ipairs(vim.split(env_path or "", ":", { trimempty = true })) do
    local candidate = d .. "/" .. bin
    if vim.fn.executable(candidate) == 1 then
      return candidate
    end
  end
  return nil
end

-- Absolute path of a tool for `where`: the project's environment when there is one,
-- otherwise Neovim's PATH. `entry` may be passed when the caller already has it.
function M.resolve(where, bin, entry)
  entry = entry or M.get(where)
  -- Only a loaded environment has `env`; blocked/failed ones fall back to Neovim's PATH.
  local path = (entry and entry.env and entry.env.PATH) or vim.env.PATH
  return search_path(bin, path)
end

-- A clear, one-time message when a tool is missing.
function M.warn_missing(where, bin, entry)
  local dir = M.envrc_dir(where)
  if entry and entry.state == "ready" then
    warn_once(("%s not found in this project's devenv (%s).\nAdd it to devenv.nix; see docs/devshell-contract.md."):format(bin, dir))
  elseif entry then
    -- blocked / denied / error: the reason was already reported once
    warn_once(("%s not found: %s/.envrc is not loaded (%s), and it is not on Neovim's PATH."):format(bin, dir, entry.state))
  else
    warn_once(("%s not found: no devshell here (no .envrc above %s) and it is not on Neovim's PATH."):format(bin, dir_of(where)))
  end
end

-- Async: load the environment for `where`, then call on_found(path, entry) if `bin`
-- exists there. Otherwise warn once.
function M.ensure(where, bin, on_found)
  M.load(where, function(entry)
    local path = M.resolve(where, bin, entry)
    if path then
      on_found(path, entry)
    else
      M.warn_missing(where, bin, entry)
    end
  end)
end

-- ---------------------------------------------------------------------------
-- Language servers
-- ---------------------------------------------------------------------------

-- Make an already configured server (vim.lsp.config) start through the devshell.
-- Its root detection is kept; the server only starts once its binary is found in
-- that root's environment, and it is started with that environment.
-- opts.extra_args(root) may return more command-line arguments for that root.
function M.wrap_lsp(name, opts)
  opts = opts or {}
  local base = vim.lsp.config[name] or {}
  local orig_root, markers, orig_cmd = base.root_dir, base.root_markers, base.cmd
  if type(orig_cmd) ~= "table" then
    return -- nothing to wrap (cmd is already a function)
  end
  local bin = orig_cmd[1]

  vim.lsp.config(name, {
    root_dir = function(bufnr, on_dir)
      local function start(root)
        root = root or dir_of(bufnr)
        M.ensure(root, bin, function()
          on_dir(root)
        end)
      end
      if type(orig_root) == "function" then
        orig_root(bufnr, start) -- the server decides; if it never calls back, nothing starts
      elseif type(orig_root) == "string" then
        start(orig_root)
      else
        start(vim.fs.root(bufnr, markers or { ".git" }))
      end
    end,

    cmd = function(dispatchers, config)
      local root = config.root_dir or vim.uv.cwd()
      local argv = vim.deepcopy(orig_cmd)
      argv[1] = M.resolve(root, bin) or bin
      if opts.extra_args then
        vim.list_extend(argv, opts.extra_args(root))
      end
      return vim.lsp.rpc.start(argv, dispatchers, {
        cwd = config.cmd_cwd or root,
        env = vim.tbl_extend("force", M.env(root) or {}, config.cmd_env or {}),
        detached = config.detached,
      })
    end,
  })
end

-- ---------------------------------------------------------------------------
-- Formatters (conform.nvim)
-- ---------------------------------------------------------------------------

-- node_modules/.bin/<bin> above `dir`, if the project has it installed.
local function node_bin(dir, bin)
  local found = vim.fs.find("node_modules/.bin/" .. bin, { upward = true, path = dir })[1]
  return found and vim.fn.executable(found) == 1 and found or nil
end

-- Run a conform formatter from the project: node_modules/.bin first (when `node` is
-- true), then the devshell, then Neovim's PATH. If none has it, the formatter is
-- skipped (conform moves on to the next one, or to LSP formatting) and you are told once.
-- `needs_file` (optional): only use the formatter when one of these files exists above.
-- `warn_ft` (optional): only warn about a missing formatter for these filetypes (e.g.
-- prettier is expected for TypeScript, but optional for JSON, which falls back to LSP).
function M.conform(name, opts)
  opts = opts or {}
  local conform = require("conform")
  local builtin = require("conform.formatters." .. name)
  local bin = opts.bin or (type(builtin.command) == "string" and builtin.command) or name

  local function find(ctx)
    return (opts.node and node_bin(ctx.dirname, bin)) or M.resolve(ctx.dirname, bin)
  end

  conform.formatters[name] = {
    inherit = true,
    command = function(_, ctx)
      return find(ctx) or bin
    end,
    env = function(_, ctx)
      return M.env(ctx.dirname)
    end,
    condition = function(_, ctx)
      if opts.needs_file and not vim.fs.find(opts.needs_file, { upward = true, path = ctx.dirname })[1] then
        return false
      end
      if find(ctx) then
        return true
      end
      local ft = vim.bo[ctx.buf].filetype
      local wanted = not opts.warn_ft or vim.tbl_contains(opts.warn_ft, ft)
      if wanted and (M.get(ctx.dirname) or not M.envrc_dir(ctx.dirname)) then
        M.warn_missing(ctx.dirname, bin, M.get(ctx.dirname)) -- env is known: really missing
      end
      return false
    end,
  }
end

-- ---------------------------------------------------------------------------
-- Tests (neotest) and debugging (nvim-dap)
-- ---------------------------------------------------------------------------

-- Make a neotest adapter run its commands with the project's environment.
function M.neotest(adapter)
  local build = adapter.build_spec
  adapter.build_spec = function(args)
    local spec = build(args)
    local function patch(s)
      if type(s) ~= "table" or not s.command then
        return
      end
      local dir = s.cwd or (args.tree and args.tree:data().path) or vim.uv.cwd()
      local env = M.env(dir)
      if env then
        s.env = vim.tbl_extend("force", env, s.env or {})
      end
      if type(s.command) == "table" then
        s.command[1] = M.resolve(dir, s.command[1]) or s.command[1]
      end
    end
    if type(spec) == "table" and spec.command == nil then
      for _, s in ipairs(spec) do
        patch(s)
      end
    else
      patch(spec)
    end
    return spec
  end
  return adapter
end

-- A value from the project's environment (falls back to Neovim's environment).
function M.getenv(where, name)
  local env = M.env(where)
  return (env and env[name]) or vim.env[name]
end

-- ---------------------------------------------------------------------------
-- :DevshellStatus
-- ---------------------------------------------------------------------------

-- Each language registers the tools it expects, for :DevshellStatus.
-- tools = { { bin = "jdtls", what = "language server", version = { "--version" } }, ... }
-- `version` is the argument list used to print a version (default { "--version" });
-- false means "don't run it" (language servers that would just start and wait).
-- `node = true` also looks in the project's node_modules/.bin.
-- `vars` lists environment variables that should be set (e.g. JDTLS_DEBUG_BUNDLE).
function M.register(filetypes, tools, vars)
  for _, ft in ipairs(filetypes) do
    tools_by_ft[ft] = tools_by_ft[ft] or { tools = {}, vars = {} }
    vim.list_extend(tools_by_ft[ft].tools, tools)
    vim.list_extend(tools_by_ft[ft].vars, vars or {})
  end
end

local function version_of(path, args, where)
  local ok, res = pcall(function()
    return vim.system(vim.list_extend({ path }, args or { "--version" }), {
      text = true,
      env = M.env(where),
      cwd = M.envrc_dir(where) or dir_of(where),
    }):wait(5000)
  end)
  if not ok or not res then
    return "?"
  end
  -- Some tools print the version on stderr (java -version); skip JVM notices.
  local text = (res.stdout ~= "" and res.stdout) or res.stderr or ""
  text = text:gsub("Picked up [^\n]*\n", "")
  local out = first_line(text)
  return out ~= "" and out or ("exit " .. tostring(res.code))
end

function M.status_lines(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  local dir = M.envrc_dir(bufnr)
  local entry = dir and cache[dir]
  local lines = {
    "# Devshell",
    "",
    "- file: `" .. (vim.api.nvim_buf_get_name(bufnr) ~= "" and vim.api.nvim_buf_get_name(bufnr) or "[no name]") .. "`",
    "- root: `" .. (dir or (vim.fs.root(bufnr, { ".git" }) or dir_of(bufnr))) .. "`",
  }
  if not dir then
    table.insert(lines, "- .envrc: none (tools come from Neovim's PATH)")
  else
    local state = entry and entry.state or "not loaded yet"
    local hint = ({
      ready = "allowed and loaded",
      blocked = "NOT allowed: run `direnv allow` in that directory, then :DevshellReload",
      denied = "denied with `direnv deny`",
      loading = "loading…",
      error = "failed: " .. tostring(entry and entry.err),
    })[state] or state
    table.insert(lines, "- .envrc: `" .. dir .. "/.envrc` (" .. hint .. ")")
  end
  table.insert(lines, "- filetype: `" .. (ft ~= "" and ft or "none") .. "`")
  table.insert(lines, "")

  local reg = tools_by_ft[ft]
  if not reg then
    table.insert(lines, "No project tools registered for this filetype.")
    return lines
  end
  table.insert(lines, "| tool | for | found | version |")
  table.insert(lines, "| --- | --- | --- | --- |")
  for _, t in ipairs(reg.tools) do
    local path = (t.node and node_bin(dir_of(bufnr), t.bin))
      or M.resolve(bufnr, t.bin, entry and entry.state == "ready" and entry or nil)
    table.insert(lines, ("| `%s` | %s | %s | %s |"):format(
      t.bin,
      t.what or "",
      path and ("`" .. path .. "`") or "**missing**",
      (path and t.version ~= false) and version_of(path, t.version, bufnr) or ""
    ))
  end
  if #reg.vars > 0 then
    table.insert(lines, "")
    table.insert(lines, "| variable | value |")
    table.insert(lines, "| --- | --- |")
    for _, v in ipairs(reg.vars) do
      local value = M.getenv(bufnr, v)
      table.insert(lines, ("| `%s` | %s |"):format(v, value and ("`" .. value .. "`") or "not set"))
    end
  end
  return lines
end

function M.status()
  local bufnr = vim.api.nvim_get_current_buf()
  M.load(bufnr, function()
    local lines = M.status_lines(bufnr)
    vim.lsp.util.open_floating_preview(lines, "markdown", { border = "rounded", focus_id = "devshell", max_width = 120 })
  end)
end

-- Forget cached environments (all, or the one for `where`).
function M.reload(where)
  if where then
    local dir = M.envrc_dir(where)
    if dir then
      cache[dir] = nil
    end
  else
    cache = {}
  end
  warned = {}
end

function M.setup(opts)
  M.direnv = (opts and opts.direnv) or M.direnv

  vim.api.nvim_create_user_command("DevshellStatus", M.status, {
    desc = "Show the devshell (.envrc) and project tools for this buffer",
  })
  vim.api.nvim_create_user_command("DevshellReload", function()
    M.reload()
    notify("Environments will be reloaded. Restart language servers with :lsp restart.", vim.log.levels.INFO)
  end, { desc = "Forget cached devshell environments" })

  -- Editing the devshell definition makes the cached environment stale.
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("devshell", { clear = true }),
    pattern = { ".envrc", "devenv.nix", "devenv.yaml", "devenv.lock", "flake.nix", "flake.lock", "shell.nix" },
    callback = function(ev)
      M.reload(ev.file)
      notify("Devshell changed; it will be reloaded. Restart language servers with :lsp restart.", vim.log.levels.INFO)
    end,
  })

  -- Start loading as soon as a file is opened, so the environment is usually ready
  -- by the time a server, formatter or test needs it.
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = "devshell",
    callback = function(ev)
      M.load(ev.buf)
    end,
  })
end

return M
