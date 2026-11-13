# Debugging (nvim-dap). Language adapters are set in languages/*.nix.
{
  config,
  lib,
  pkgs,
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
    keymaps = [
      # --- DAP ---
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
