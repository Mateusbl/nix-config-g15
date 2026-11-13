# Optional features, all off by default. Turn one on in home/default.nix, e.g.
#   my.neovim.optional.http.enable = true;
{ config, lib, ... }:

let
  cfg = config.my.neovim.optional;
in
{
  options.my.neovim.optional = {
    http.enable = lib.mkEnableOption "kulala.nvim: run HTTP requests from .http files";
    database.enable = lib.mkEnableOption ''
      vim-dadbod-ui: browse and query databases. Connections come from your environment
      (DATABASE_URL / DBUI_URL, e.g. set by a project's devenv) or are added in the UI, which
      saves them under ~/.local/share/db_ui. Never put credentials in this repository'';
    claude.enable = lib.mkEnableOption "claudecode.nvim: Claude Code integration (needs the `claude` CLI on PATH)";
  };

  config.programs.nixvim = lib.mkMerge [
    (lib.mkIf cfg.http.enable {
      plugins.kulala.enable = true;
      keymaps = [
        {
          mode = "n";
          key = "<leader>Rs";
          action.__raw = "function() require('kulala').run() end";
          options.desc = "Send HTTP Request";
        }
        {
          mode = "n";
          key = "<leader>Ra";
          action.__raw = "function() require('kulala').run_all() end";
          options.desc = "Send All HTTP Requests";
        }
      ];
    })

    (lib.mkIf cfg.database.enable {
      plugins.vim-dadbod.enable = true;
      plugins.vim-dadbod-ui.enable = true;
      plugins.vim-dadbod-completion.enable = true;
      # Table/column completion in SQL buffers through blink.cmp.
      plugins.blink-cmp.settings.sources = {
        per_filetype.sql = [
          "dadbod"
          "snippets"
          "buffer"
        ];
        providers.dadbod = {
          name = "Dadbod";
          module = "vim_dadbod_completion.blink";
        };
      };
      keymaps = [
        {
          mode = "n";
          key = "<leader>Du";
          action = "<cmd>DBUIToggle<cr>";
          options.desc = "Toggle Database UI";
        }
      ];
    })

    (lib.mkIf cfg.claude.enable {
      plugins.claudecode.enable = true;
      # nixvim would install the claude-code CLI (unfree, and nixvim's own nixpkgs does not
      # allow unfree). Use the `claude` already on your PATH instead.
      dependencies.claude-code.enable = false;
      keymaps = [
        {
          mode = "n";
          key = "<leader>ac";
          action = "<cmd>ClaudeCode<cr>";
          options.desc = "Toggle Claude";
        }
        {
          mode = "v";
          key = "<leader>as";
          action = "<cmd>ClaudeCodeSend<cr>";
          options.desc = "Send Selection to Claude";
        }
      ];
    })
  ];
}
