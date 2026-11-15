-- lang_python.lua: debugging and tests use the project's Python.
--
-- nvim-dap-python and neotest-python would otherwise use whatever `python3` Neovim
-- itself sees. Here both ask lua/devshell.lua for the project's interpreter, so
-- debugpy, pytest and Django come from the project's devenv/venv.

local devshell = require("devshell")
local M = {}

-- The project's python for `where` (buffer, file or directory), or nil.
function M.python(where)
  return devshell.resolve(where, "python") or devshell.resolve(where, "python3")
end

-- Make nvim-dap-python start debugpy with the project's python and environment.
function M.setup_dap()
  local ok, dap = pcall(require, "dap")
  if not ok or not dap.adapters.python then
    return
  end
  local orig = dap.adapters.python -- created by require("dap-python").setup()

  dap.adapters.python = function(cb, config)
    if config.request == "attach" then
      return orig(cb, config) -- attaching to a running debugpy: nothing to start
    end
    local where = config.cwd or vim.api.nvim_buf_get_name(0)
    devshell.load(where, function(entry)
      local python = M.python(where)
      if not python then
        return devshell.warn_missing(where, "python", entry)
      end
      orig(function(adapter)
        adapter.command = python
        adapter.options = vim.tbl_extend("force", adapter.options or {}, {
          env = devshell.full_env(where), -- nvim-dap replaces the environment, so pass all of it
          cwd = devshell.envrc_dir(where),
        })
        cb(adapter)
      end, config)
    end)
  end
  dap.adapters.debugpy = dap.adapters.python

  -- The debugged program's interpreter (`pythonPath` in launch configurations).
  require("dap-python").resolve_python = function()
    return M.python(0)
  end
end

return M
