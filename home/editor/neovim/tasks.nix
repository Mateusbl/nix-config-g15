# Tasks (overseer.nvim): .vscode/tasks.json, npm scripts, make, just, ... and your own.
#
# overseer reads .vscode/tasks.json by itself (its "vscode" template), and also wires
# nvim-dap so `preLaunchTask` / `postDebugTask` in launch.json run those tasks.
# Every task runs with the project's devshell environment (hook below).
{
  config,
  lib,
  ...
}:

let
  cfg = config.my.neovim;
in
{
  options.my.neovim.tasks.enable = lib.mkEnableOption "running tasks with overseer.nvim" // {
    default = true;
  };

  config.programs.nixvim = lib.mkIf cfg.tasks.enable {
    plugins.overseer.enable = true;

    extraConfigLuaPost = ''
      -- Run every task (any template: vscode, npm, make, ...) inside its project's devshell.
      require("overseer").add_template_hook(nil, function(task_defn)
        local devshell = require("devshell")
        local env = devshell.env(task_defn.cwd or vim.uv.cwd())
        if env then
          task_defn.env = vim.tbl_extend("force", env, task_defn.env or {})
        end
      end)
    '';

    keymaps = [
      {
        mode = "n";
        key = "<leader>or";
        action = "<cmd>OverseerRun<cr>";
        options.desc = "Run Task";
      }
      {
        mode = "n";
        key = "<leader>ot";
        action = "<cmd>OverseerToggle<cr>";
        options.desc = "Toggle Task List";
      }
      {
        mode = "n";
        key = "<leader>oa";
        action = "<cmd>OverseerTaskAction<cr>";
        options.desc = "Task Action";
      }
    ];
  };
}
