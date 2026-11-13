# Test runner (neotest). Language adapters are set in languages/*.nix.
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
  programs.nixvim = lib.mkIf cfg.test.enable {
    plugins = {
      # --- Testing ---
      neotest = {
        enable = true;
      };
    };
    keymaps = [
      # --- Neotest ---
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
