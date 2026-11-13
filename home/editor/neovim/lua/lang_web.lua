-- lang_web.lua: JavaScript/TypeScript debugging with js-debug (vscode-js-debug).
--
-- js-debug is project-owned: it comes from the project's devenv, either as the
-- `js-debug` program on PATH or through JS_DEBUG_PATH (see docs/devshell-contract.md).
-- Nothing is downloaded at runtime.

local devshell = require("devshell")
local M = {}

-- Command that starts js-debug's DAP server for `where`, as { cmd, args... }, or nil.
-- JS_DEBUG_PATH may be the program, the directory it is in, or dapDebugServer.js.
function M.js_debug_cmd(where)
  local p = devshell.getenv(where, "JS_DEBUG_PATH")
  if p and p ~= "" then
    if p:match("%.js$") then
      return { devshell.resolve(where, "node") or "node", p }
    end
    if vim.fn.isdirectory(p) == 1 then
      for _, candidate in ipairs({ p .. "/bin/js-debug", p .. "/js-debug", p .. "/src/dapDebugServer.js" }) do
        if vim.fn.filereadable(candidate) == 1 then
          return M.js_debug_cmd_from(candidate, where)
        end
      end
    elseif vim.fn.executable(p) == 1 then
      return { p }
    end
  end
  local bin = devshell.resolve(where, "js-debug")
  return bin and { bin } or nil
end

function M.js_debug_cmd_from(path, where)
  if path:match("%.js$") then
    return { devshell.resolve(where, "node") or "node", path }
  end
  return { path }
end

function M.setup_dap()
  local ok, dap = pcall(require, "dap")
  if not ok then
    return
  end

  -- One adapter function for every js-debug type: it starts the server on a free port.
  local function adapter(cb, config)
    local where = config.cwd or vim.api.nvim_buf_get_name(0)
    devshell.load(where, function(entry)
      local cmd = M.js_debug_cmd(where)
      if not cmd then
        return devshell.warn_missing(where, "js-debug (or JS_DEBUG_PATH)", entry)
      end
      local args = vim.list_slice(cmd, 2)
      table.insert(args, "${port}")
      cb({
        type = "server",
        host = "127.0.0.1",
        port = "${port}",
        executable = {
          command = cmd[1],
          args = args,
          env = devshell.full_env(where),
        },
      })
    end)
  end
  for _, t in ipairs({ "pwa-node", "pwa-chrome", "node-terminal" }) do
    dap.adapters[t] = adapter
  end
  -- launch.json files often say "node"/"chrome"; map them to js-debug.
  dap.adapters.node = adapter
  dap.adapters.chrome = adapter

  local configs = {
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch current file (node)",
      program = "${file}",
      cwd = "${workspaceFolder}",
    },
    {
      type = "pwa-node",
      request = "attach",
      name = "Attach to node process",
      processId = function()
        return require("dap.utils").pick_process()
      end,
      cwd = "${workspaceFolder}",
    },
    {
      type = "pwa-chrome",
      request = "launch",
      name = "Launch Chrome on Vite dev server (localhost:5173)",
      url = "http://localhost:5173",
      webRoot = "${workspaceFolder}",
    },
  }
  for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
    dap.configurations[ft] = configs
  end
end

return M
