# Test runner (neotest). Language adapters are set in languages/*.nix.
{
  config,
  lib,
  ...
}:

let
  cfg = config.my.neovim;
in
{
  programs.nixvim = lib.mkIf cfg.test.enable {
    plugins = {
      # --- Testing ---
      neotest = {
        enable = true;
      };
    };

    # Every test adapter runs its commands with the project's devshell environment
    # (lua/devshell.lua). Adapters are added in languages/*.nix.
    extraConfigLuaPost = ''
      for _, adapter in ipairs(require("neotest.config").adapters or {}) do
        require("devshell").neotest(adapter)
      end
    '';
    keymaps = [
      # --- Neotest ---
      # Additions (the original <leader>t maps below are unchanged)
      {
        mode = "n";
        key = "<leader>td";
        action.__raw = "function() require('neotest').run.run({ strategy = 'dap' }) end";
        options.desc = "Debug Nearest (Neotest)";
      }
      {
        mode = "n";
        key = "<leader>tw";
        action.__raw = "function() require('neotest').watch.toggle(vim.fn.expand('%')) end";
        options.desc = "Toggle Watch File (Neotest)";
      }
      {
        mode = "n";
        key = "<leader>tt";
        action.__raw = "function() require('neotest').run.run(vim.fn.expand('%')) end";
        options.desc = "Run File (Neotest)";
      }
      {
        mode = "n";
        key = "<leader>tT";
        action.__raw = "function() require('neotest').run.run(vim.uv.cwd()) end";
        options.desc = "Run All Test Files (Neotest)";
      }
      {
        mode = "n";
        key = "<leader>tr";
        action.__raw = "function() require('neotest').run.run() end";
        options.desc = "Run Nearest (Neotest)";
      }
      {
        mode = "n";
        key = "<leader>tl";
        action.__raw = "function() require('neotest').run.run_last() end";
        options.desc = "Run Last (Neotest)";
      }
      {
        mode = "n";
        key = "<leader>ts";
        action.__raw = "function() require('neotest').summary.toggle() end";
        options.desc = "Toggle Summary (Neotest)";
      }
      {
        mode = "n";
        key = "<leader>to";
        action.__raw = "function() require('neotest').output.open({ enter = true, auto_close = true }) end";
        options.desc = "Show Output (Neotest)";
      }
      {
        mode = "n";
        key = "<leader>tO";
        action.__raw = "function() require('neotest').output_panel.toggle() end";
        options.desc = "Toggle Output Panel (Neotest)";
      }
      {
        mode = "n";
        key = "<leader>tS";
        action.__raw = "function() require('neotest').run.stop() end";
        options.desc = "Stop (Neotest)";
      }
    ];
  };
}
