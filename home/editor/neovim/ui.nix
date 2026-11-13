# Look and feel: colorscheme, dashboard, notifications, statusline, bufferline, which-key.
{ pkgs, ... }:

{
  programs.nixvim = {
    # ==========================================
    # Colorscheme
    # ==========================================
    colorschemes.tokyonight = {
      enable = true;
      settings = {
        style = "night";
        transparent = false;
        terminal_colors = true;
      };
    };
    plugins = {
      # --- Icons & core UI ---
      web-devicons.enable = true;
      nui.enable = true;

      # --- Dashboard ---
      alpha = {
        enable = true;
        theme = "dashboard";
      };
      notify = {
        enable = true;
        settings.timeout = 3000;
      };

      indent-blankline.enable = true;
      illuminate.enable = true;
      zen-mode.enable = true;

      # --- Noice ---
      noice = {
        enable = true;
        settings = {
          lsp.override = {
            "vim.lsp.util.convert_input_to_markdown_lines" = true;
            "vim.lsp.util.stylize_markdown" = true;
          };
          presets = {
            bottom_search = true;
            command_palette = true;
            long_message_to_split = true;
            lsp_doc_border = true;
          };
        };
      };

      # --- Bufferline & Lualine ---
      bufferline = {
        enable = true;
        settings.options = {
          diagnostics = "nvim_lsp";
          always_show_bufferline = false;
          offsets = [
            {
              filetype = "neo-tree";
              text = "Explorer";
              highlight = "Directory";
              text_align = "left";
            }
          ];
        };
      };

      lualine = {
        enable = true;
        settings.options = {
          theme = "auto";
          globalstatus = true;
          disabled_filetypes.statusline = [
            "dashboard"
            "alpha"
          ];
        };
      };

      # --- Which-Key ---
      which-key = {
        enable = true;
        settings = {
          preset = "helix";
          spec = [
            {
              __unkeyed-1 = "<leader>b";
              group = "buffer";
            }
            {
              __unkeyed-1 = "<leader>c";
              group = "code";
            }
            {
              __unkeyed-1 = "<leader>cr";
              group = "refactor (java)";
            }
            {
              __unkeyed-1 = "<leader>d";
              group = "debug";
            }
            {
              __unkeyed-1 = "<leader>f";
              group = "file/find";
            }
            {
              __unkeyed-1 = "<leader>g";
              group = "git";
            }
            {
              __unkeyed-1 = "<leader>q";
              group = "quit/session";
            }
            {
              __unkeyed-1 = "<leader>s";
              group = "search";
            }
            {
              __unkeyed-1 = "<leader>t";
              group = "test";
            }
            {
              __unkeyed-1 = "<leader>u";
              group = "ui/toggle";
            }
            {
              __unkeyed-1 = "<leader>w";
              group = "windows";
            }
            {
              __unkeyed-1 = "<leader>x";
              group = "diagnostics/quickfix";
            }
            {
              __unkeyed-1 = "[";
              group = "prev";
            }
            {
              __unkeyed-1 = "]";
              group = "next";
            }
            {
              __unkeyed-1 = "g";
              group = "goto";
            }
            {
              __unkeyed-1 = "gs";
              group = "surround";
            }
          ];
        };
      };

    };
    keymaps = [
      {
        mode = "n";
        key = "<leader>uw";
        action = "<cmd>set wrap!<cr>";
        options.desc = "Toggle Word Wrap";
      }
      {
        mode = "n";
        key = "<leader>ul";
        action = "<cmd>set relativenumber!<cr>";
        options.desc = "Toggle Relative Number";
      }
      {
        mode = "n";
        key = "<leader>uh";
        action.__raw = "function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end";
        options.desc = "Toggle Inlay Hints";
      }
      {
        mode = "n";
        key = "<leader>uz";
        action = "<cmd>ZenMode<cr>";
        options.desc = "Toggle Zen Mode";
      }
      {
        mode = "n";
        key = "<leader>un";
        action.__raw = "function() require('notify').dismiss({ silent = true, pending = true }) end";
        options.desc = "Dismiss All Notifications";
      }
    ];
  };
}
