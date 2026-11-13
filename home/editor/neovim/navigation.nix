# Moving around: file explorer, oil, fuzzy finder, flash, search/replace, sessions, terminal.
{ pkgs, ... }:

{
  programs.nixvim = {
    plugins = {
      # Visual undo history (branches included).
      undotree.enable = true;

      # --- File explorer ---
      neo-tree = {
        enable = true;
        settings = {
          close_if_last_window = true;
          filesystem.follow_current_file.enabled = true;
        };
      };

      # --- Oil on `-` for quick parent dir edits ---
      oil = {
        enable = true;
        settings = {
          default_file_explorer = false; # neo-tree handles directory opening
          columns = [ "icon" ];
          view_options.show_hidden = true;
        };
      };

      # --- Terminal, git UI, notifications, small UI helpers ---
      toggleterm = {
        enable = true;
        settings = {
          direction = "float";
          shade_terminals = false;
        };
      };
      # --- Fuzzy finder ---
      fzf-lua = {
        enable = true;
        profile = "default";
        settings.winopts.tittle_pos = "center";
      };
      # --- mini.nvim ---
      mini = {
        enable = true;
        modules = {
          ai.n_lines = 500;
          pairs = { };
          bufremove = { };
          surround.mappings = {
            add = "gsa";
            delete = "gsd";
            find = "gsf";
            find_left = "gsF";
            highlight = "gsh";
            replace = "gsr";
            update_n_lines = "gsn";
          };
        };
      };

      # --- Navigation, search/replace, diagnostics ---
      flash.enable = true;
      grug-far.enable = true;
      trouble.enable = true;
      todo-comments.enable = true;
      persistence.enable = true;
    };
    keymaps = [
      {
        mode = "n";
        key = "<leader>uu";
        action = "<cmd>UndotreeToggle<cr>";
        options.desc = "Toggle Undo Tree";
      }
      # --- Oil ---
      {
        mode = "n";
        key = "-";
        action = "<cmd>Oil<cr>";
        options.desc = "Open parent directory in Oil";
      }
      # --- Explorer, terminal, git ---
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>Neotree toggle<cr>";
        options.desc = "Explorer";
      }
      {
        mode = "n";
        key = "<leader>E";
        action = "<cmd>Neotree reveal<cr>";
        options.desc = "Explorer (current file)";
      }
      {
        mode = [
          "n"
          "t"
        ];
        key = "<c-/>";
        action = "<cmd>ToggleTerm<cr>";
        options.desc = "Toggle Terminal";
      }
      {
        mode = [
          "n"
          "t"
        ];
        key = "<c-_>";
        action = "<cmd>ToggleTerm<cr>";
        options.desc = "which_key_ignore";
      }
      {
        mode = "n";
        key = "<leader>ft";
        action = "<cmd>ToggleTerm<cr>";
        options.desc = "Terminal";
      }
      # --- fzf-lua ---
      {
        mode = "n";
        key = "<leader><space>";
        action = "<cmd>FzfLua files<cr>";
        options.desc = "Find Files";
      }
      {
        mode = "n";
        key = "<leader>,";
        action = "<cmd>FzfLua buffers sort_mru=true sort_lastused=true<cr>";
        options.desc = "Switch Buffer";
      }
      {
        mode = "n";
        key = "<leader>/";
        action = "<cmd>FzfLua live_grep<cr>";
        options.desc = "Grep";
      }
      {
        mode = "n";
        key = "<leader>:";
        action = "<cmd>FzfLua command_history<cr>";
        options.desc = "Command History";
      }
      {
        mode = "n";
        key = "<leader>ff";
        action = "<cmd>FzfLua files<cr>";
        options.desc = "Find Files";
      }
      {
        mode = "n";
        key = "<leader>fg";
        action = "<cmd>FzfLua git_files<cr>";
        options.desc = "Find Files (git-files)";
      }
      {
        mode = "n";
        key = "<leader>fr";
        action = "<cmd>FzfLua oldfiles<cr>";
        options.desc = "Recent";
      }
      {
        mode = "n";
        key = "<leader>fb";
        action = "<cmd>FzfLua buffers sort_mru=true sort_lastused=true<cr>";
        options.desc = "Buffers";
      }
      {
        mode = "n";
        key = "<leader>gc";
        action = "<cmd>FzfLua git_commits<cr>";
        options.desc = "Commits";
      }
      {
        mode = "n";
        key = "<leader>gs";
        action = "<cmd>FzfLua git_status<cr>";
        options.desc = "Status";
      }
      {
        mode = "n";
        key = "<leader>sb";
        action = "<cmd>FzfLua lgrep_curbuf<cr>";
        options.desc = "Buffer Lines";
      }
      {
        mode = "n";
        key = "<leader>sd";
        action = "<cmd>FzfLua diagnostics_document<cr>";
        options.desc = "Document Diagnostics";
      }
      {
        mode = "n";
        key = "<leader>sD";
        action = "<cmd>FzfLua diagnostics_workspace<cr>";
        options.desc = "Workspace Diagnostics";
      }
      {
        mode = "n";
        key = "<leader>sg";
        action = "<cmd>FzfLua live_grep<cr>";
        options.desc = "Grep";
      }
      {
        mode = "n";
        key = "<leader>sh";
        action = "<cmd>FzfLua help_tags<cr>";
        options.desc = "Help Pages";
      }
      {
        mode = "n";
        key = "<leader>sk";
        action = "<cmd>FzfLua keymaps<cr>";
        options.desc = "Key Maps";
      }
      {
        mode = "n";
        key = "<leader>sm";
        action = "<cmd>FzfLua marks<cr>";
        options.desc = "Jump to Mark";
      }
      {
        mode = "n";
        key = "<leader>sR";
        action = "<cmd>FzfLua resume<cr>";
        options.desc = "Resume";
      }
      {
        mode = "n";
        key = "<leader>ss";
        action = "<cmd>FzfLua lsp_document_symbols<cr>";
        options.desc = "Goto Symbol";
      }
      {
        mode = "n";
        key = "<leader>sS";
        action = "<cmd>FzfLua lsp_live_workspace_symbols<cr>";
        options.desc = "Goto Symbol (Workspace)";
      }
      {
        mode = "n";
        key = "<leader>sw";
        action = "<cmd>FzfLua grep_cword<cr>";
        options.desc = "Word";
      }

      # --- Flash ---
      {
        mode = [
          "n"
          "x"
          "o"
        ];
        key = "s";
        action.__raw = "function() require('flash').jump() end";
        options.desc = "Flash";
      }
      {
        mode = [
          "n"
          "o"
          "x"
        ];
        key = "S";
        action.__raw = "function() require('flash').treesitter() end";
        options.desc = "Flash Treesitter";
      }
      {
        mode = "o";
        key = "r";
        action.__raw = "function() require('flash').remote() end";
        options.desc = "Remote Flash";
      }
      {
        mode = [
          "o"
          "x"
        ];
        key = "R";
        action.__raw = "function() require('flash').treesitter_search() end";
        options.desc = "Treesitter Search";
      }

      # --- Grug-far ---
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>sr";
        action = "<cmd>GrugFar<cr>";
        options.desc = "Search and Replace";
      }

      # --- Trouble & todo-comments ---
      {
        mode = "n";
        key = "<leader>xx";
        action = "<cmd>Trouble diagnostics toggle<cr>";
        options.desc = "Diagnostics (Trouble)";
      }
      {
        mode = "n";
        key = "<leader>xX";
        action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
        options.desc = "Buffer Diagnostics (Trouble)";
      }
      {
        mode = "n";
        key = "<leader>cs";
        action = "<cmd>Trouble symbols toggle<cr>";
        options.desc = "Symbols (Trouble)";
      }
      {
        mode = "n";
        key = "<leader>xL";
        action = "<cmd>Trouble loclist toggle<cr>";
        options.desc = "Location List (Trouble)";
      }
      {
        mode = "n";
        key = "<leader>xQ";
        action = "<cmd>Trouble qflist toggle<cr>";
        options.desc = "Quickfix List (Trouble)";
      }
      {
        mode = "n";
        key = "<leader>xt";
        action = "<cmd>Trouble todo toggle<cr>";
        options.desc = "Todo (Trouble)";
      }
      {
        mode = "n";
        key = "<leader>st";
        action = "<cmd>TodoFzfLua<cr>";
        options.desc = "Todo (FzfLua)";
      }
      {
        mode = "n";
        key = "]t";
        action.__raw = "function() require('todo-comments').jump_next() end";
        options.desc = "Next Todo Comment";
      }
      {
        mode = "n";
        key = "[t";
        action.__raw = "function() require('todo-comments').jump_prev() end";
        options.desc = "Previous Todo Comment";
      }
      # --- Session / quit ---
      {
        mode = "n";
        key = "<leader>qs";
        action.__raw = "function() require('persistence').load() end";
        options.desc = "Restore Session";
      }
      {
        mode = "n";
        key = "<leader>ql";
        action.__raw = "function() require('persistence').load({ last = true }) end";
        options.desc = "Restore Last Session";
      }
      {
        mode = "n";
        key = "<leader>qd";
        action.__raw = "function() require('persistence').stop() end";
        options.desc = "Don't Save Current Session";
      }
      {
        mode = "n";
        key = "<leader>qq";
        action = "<cmd>qa<cr>";
        options.desc = "Quit All";
      }
    ];
  };
}
