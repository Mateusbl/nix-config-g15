-- lang_java.lua: Java pieces that need the project's environment.
--
-- The jars jdtls loads as plugins (debugger, test runner, Lombok) come from the
-- project's devenv through environment variables. Nix store paths are never written
-- into the editor config, so each project decides its own versions.
--   JDTLS_DEBUG_BUNDLE  com.microsoft.java.debug.plugin-*.jar (file, directory or glob)
--   JDTLS_TEST_BUNDLES  vscode-java-test server jars, ':'-separated (files, directories or globs)
--   JDTLS_LOMBOK_JAR    lombok.jar, used as a -javaagent

local devshell = require("devshell")
local M = {}

-- Expand one entry: a directory gives its *.jar files, anything else is globbed.
local function jars(entry)
  if entry == nil or entry == "" then
    return {}
  end
  local pattern = vim.fn.isdirectory(entry) == 1 and (entry .. "/*.jar") or entry
  return vim.fn.glob(pattern, true, true)
end

-- Bundles for jdtls' initializationOptions, from the project at `root`.
function M.bundles(root)
  local list = {}
  local function add(entry)
    for _, jar in ipairs(jars(entry)) do
      -- Same filter the VS Code Java test extension uses: these jars are not plugins.
      if not jar:match("runner%-jar%-with%-dependencies") and not jar:match("jacocoagent") then
        table.insert(list, jar)
      end
    end
  end
  add(devshell.getenv(root, "JDTLS_DEBUG_BUNDLE"))
  for _, entry in ipairs(vim.split(devshell.getenv(root, "JDTLS_TEST_BUNDLES") or "", ":", { trimempty = true })) do
    add(entry)
  end
  return list
end

-- Extra jdtls command-line arguments for `root`.
function M.extra_args(root)
  local args = {}
  local lombok = devshell.getenv(root, "JDTLS_LOMBOK_JAR")
  if lombok and lombok ~= "" then
    table.insert(args, "--jvm-arg=-javaagent:" .. lombok)
  end
  return args
end

function M.setup()
  devshell.wrap_lsp("jdtls", { extra_args = M.extra_args })
  vim.lsp.config("jdtls", {
    -- Runs just before the server is initialised, once per project root.
    before_init = function(params, config)
      params.initializationOptions = params.initializationOptions or {}
      params.initializationOptions.bundles = M.bundles(config.root_dir)
    end,
  })
end

return M
