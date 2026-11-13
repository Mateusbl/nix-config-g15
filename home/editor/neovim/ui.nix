# Look and feel: colours, dashboard, notifications, statusline, bufferline, which-key.
#
# Colours come from Stylix (modules/nixos/stylix.nix), not from a colorscheme plugin.
# Stylix's nixvim target loads mini.base16 with that palette; mini.base16 also themes
# bufferline, which-key, neo-tree, blink.cmp, fzf-lua, noice, trouble, gitsigns and dap-ui.
{ config, ... }:

let
  # The same base16 palette Stylix uses everywhere else (Ghostty, Waybar, GTK, ...).
  c = config.lib.stylix.colors.withHashtag;

  # A lualine theme built from the palette. lualine's "auto" theme guesses from
  # highlight groups and gets confused once Normal has no background.
  # Section "c" has no background so the statusline shows the terminal through it.
  mode = color: {
    a = {
      fg = c.base00;
      bg = color;
      gui = "bold";
    };
    b = {
      fg = c.base05;
      bg = c.base02;
    };
    c = {
      fg = c.base04;
      bg = "NONE";
    };
  };
  lualineTheme = {
    normal = mode c.base0D;
    insert = mode c.base0B;
    visual = mode c.base0E;
    replace = mode c.base08;
    command = mode c.base0A;
    terminal = mode c.base0C;
    inactive = {
      a = {
        fg = c.base04;
        bg = "NONE";
      };
      b = {
        fg = c.base04;
        bg = "NONE";
      };
      c = {
        fg = c.base03;
        bg = "NONE";
      };
    };
  };

  # Highlight groups that would otherwise paint an opaque block inside Ghostty
  # (terminal opacity 0.85). Floats and menus keep their base01 background on purpose:
  # they need contrast to be readable.
  #
  # nixvim applies these with nvim_set_hl, which replaces the whole group, so each one
  # also restores its palette foreground (otherwise line numbers etc. turn bright white).
  clear = fg: {
    inherit fg;
    bg = "none";
    ctermbg = "none";
  };
in
{
  # Stylix makes Normal, the sign column and the number column transparent.
  stylix.targets.nixvim.transparentBackground = {
    main = true;
    signColumn = true;
    numberLine = true;
  };

  programs.nixvim = {
    highlightOverride = {
      # Stylix makes these transparent; the fg values put the palette colours back.
      Normal = clear c.base05;
      NonText = clear c.base03;
      SignColumn = clear c.base03;
      LineNr = clear c.base03;
      LineNrAbove = clear c.base03;
      LineNrBelow = clear c.base03;
      # Extra groups Stylix does not cover.
      NormalNC = clear c.base05; # unfocused windows
      EndOfBuffer = clear c.base03;
      FoldColumn = clear c.base0C;
      WinSeparator = clear c.base02;
      CursorLineNr = clear c.base0D;
      StatusLine = clear c.base04;
      StatusLineNC = clear c.base03;
      TabLineFill = clear c.base03;
      # neo-tree copies Normal when it starts, so it needs its own entries.
      NeoTreeNormal = clear c.base05;
      NeoTreeNormalNC = clear c.base05;
      NeoTreeEndOfBuffer = clear c.base03;
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
        settings = {
          timeout = 3000;
          # nvim-notify needs a real colour to fade from when Normal is transparent.
          background_colour = c.base00;
        };
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
          theme = lualineTheme;
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
              __unkeyed-1 = "<leader>o";
              group = "tasks (overseer)";
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
