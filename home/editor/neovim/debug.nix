# Debugging (nvim-dap). Language adapters are set in languages/*.nix.
{
  config,
  lib,
  ...
}:

let
  cfg = config.my.neovim;
in
{
  programs.nixvim = lib.mkIf cfg.debug.enable {
    plugins = {
      # --- Debugging ---
      dap.enable = true;
      dap-ui.enable = true;
      dap-virtual-text.enable = true;
    };

    # Open the DAP UI when a session starts and close it when it ends.
    # .vscode/launch.json needs no setup: nvim-dap reads it on demand when you start
    # debugging (dap.ext.vscode.load_launchjs is deprecated for that reason).
    extraConfigLuaPost = ''
      do
        local dap, dapui = require("dap"), require("dapui")
        dap.listeners.after.event_initialized["dapui"] = function() dapui.open() end
        dap.listeners.before.event_terminated["dapui"] = function() dapui.close() end
        dap.listeners.before.event_exited["dapui"] = function() dapui.close() end
      end
    '';
    keymaps = [
      # --- DAP ---
      # Additions (the original <leader>d maps below are unchanged)
      {
        mode = "n";
        key = "<leader>dB";
        action.__raw = "function() require('dap').set_breakpoint(vim.fn.input('Condition: ')) end";
        options.desc = "Conditional Breakpoint";
      }
      {
        mode = "n";
        key = "<leader>dl";
        action.__raw = "function() require('dap').run_last() end";
        options.desc = "Run Last";
      }
      {
        mode = "n";
        key = "<leader>dC";
        action.__raw = "function() require('dap').run_to_cursor() end";
        options.desc = "Run to Cursor";
      }
      {
        mode = "n";
        key = "<leader>dp";
        action.__raw = "function() require('dap').pause() end";
        options.desc = "Pause";
      }
      {
        mode = "n";
        key = "<leader>dr";
        action.__raw = "function() require('dap').repl.toggle() end";
        options.desc = "Toggle REPL";
      }
      # VS Code debug keys
      {
        mode = "n";
        key = "<F5>";
        action.__raw = "function() require('dap').continue() end";
        options.desc = "Debug: Start/Continue";
      }
      {
        mode = "n";
        key = "<S-F5>";
        action.__raw = "function() require('dap').terminate() end";
        options.desc = "Debug: Stop";
      }
      {
        mode = "n";
        key = "<F9>";
        action.__raw = "function() require('dap').toggle_breakpoint() end";
        options.desc = "Debug: Toggle Breakpoint";
      }
      {
        mode = "n";
        key = "<F10>";
        action.__raw = "function() require('dap').step_over() end";
        options.desc = "Debug: Step Over";
      }
      {
        mode = "n";
        key = "<F11>";
        action.__raw = "function() require('dap').step_into() end";
        options.desc = "Debug: Step Into";
      }
      {
        mode = "n";
        key = "<S-F11>";
        action.__raw = "function() require('dap').step_out() end";
        options.desc = "Debug: Step Out";
      }
      {
        mode = "n";
        key = "<leader>db";
        action.__raw = "function() require('dap').toggle_breakpoint() end";
        options.desc = "Toggle Breakpoint";
      }
      {
        mode = "n";
        key = "<leader>dc";
        action.__raw = "function() require('dap').continue() end";
        options.desc = "Run/Continue";
      }
      {
        mode = "n";
        key = "<leader>di";
        action.__raw = "function() require('dap').step_into() end";
        options.desc = "Step Into";
      }
      {
        mode = "n";
        key = "<leader>do";
        action.__raw = "function() require('dap').step_out() end";
        options.desc = "Step Out";
      }
      {
        mode = "n";
        key = "<leader>dO";
        action.__raw = "function() require('dap').step_over() end";
        options.desc = "Step Over";
      }
      {
        mode = "n";
        key = "<leader>dt";
        action.__raw = "function() require('dap').terminate() end";
        options.desc = "Terminate";
      }
      {
        mode = "n";
        key = "<leader>du";
        action.__raw = "function() require('dapui').toggle({}) end";
        options.desc = "Dap UI";
      }
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>de";
        action.__raw = "function() require('dapui').eval() end";
        options.desc = "Eval";
      }
    ];
  };
}
