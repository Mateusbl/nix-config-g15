# Core editing keymaps (windows, buffers, moving lines, save). Plugin keymaps live next to their plugin.
{ pkgs, ... }:

{
  programs.nixvim = {
    keymaps = [
      # --- VS Code aliases (additions; the original keymaps are unchanged) ---
      # <C-S-...> keys only reach Neovim if the terminal reports them (Ghostty does,
      # via the kitty keyboard protocol that Neovim enables).
      {
        mode = "n";
        key = "<C-p>";
        action = "<cmd>FzfLua files<cr>";
        options.desc = "Quick Open (files)";
      }
      {
        mode = "n";
        key = "<C-S-p>";
        action = "<cmd>FzfLua commands<cr>";
        options.desc = "Command Palette";
      }
      {
        mode = "n";
        key = "<C-S-f>";
        action = "<cmd>FzfLua live_grep<cr>";
        options.desc = "Search in Files";
      }
      {
        mode = "n";
        key = "<C-S-m>";
        action = "<cmd>Trouble diagnostics toggle<cr>";
        options.desc = "Problems Panel";
      }
      {
        mode = "n";
        key = "<F2>";
        action.__raw = "function() vim.lsp.buf.rename() end";
        options.desc = "Rename Symbol";
      }
      {
        mode = "n";
        key = "<F12>";
        action.__raw = "function() vim.lsp.buf.definition() end";
        options.desc = "Go to Definition";
      }
      {
        mode = "n";
        key = "<S-F12>";
        action.__raw = "function() vim.lsp.buf.references() end";
        options.desc = "Find References";
      }
      {
        mode = [
          "n"
          "v"
        ];
        key = "<C-.>";
        action.__raw = "function() vim.lsp.buf.code_action() end";
        options.desc = "Code Action";
      }

      # --- Up/Down on wrapped lines ---
      {
        mode = [
          "n"
          "x"
        ];
        key = "j";
        action = "v:count == 0 ? 'gj' : 'j'";
        options = {
          expr = true;
          silent = true;
        };
      }
      {
        mode = [
          "n"
          "x"
        ];
        key = "k";
        action = "v:count == 0 ? 'gk' : 'k'";
        options = {
          expr = true;
          silent = true;
        };
      }

      # --- Windows ---
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w>h";
        options.desc = "Go to Left Window";
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w>j";
        options.desc = "Go to Lower Window";
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w>k";
        options.desc = "Go to Upper Window";
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w>l";
        options.desc = "Go to Right Window";
      }
      {
        mode = "n";
        key = "<C-Up>";
        action = "<cmd>resize +2<cr>";
        options.desc = "Increase Window Height";
      }
      {
        mode = "n";
        key = "<C-Down>";
        action = "<cmd>resize -2<cr>";
        options.desc = "Decrease Window Height";
      }
      {
        mode = "n";
        key = "<C-Left>";
        action = "<cmd>vertical resize -2<cr>";
        options.desc = "Decrease Window Width";
      }
      {
        mode = "n";
        key = "<C-Right>";
        action = "<cmd>vertical resize +2<cr>";
        options.desc = "Increase Window Width";
      }
      {
        mode = "n";
        key = "<leader>-";
        action = "<C-W>s";
        options.desc = "Split Window Below";
      }
      {
        mode = "n";
        key = "<leader>|";
        action = "<C-W>v";
        options.desc = "Split Window Right";
      }
      {
        mode = "n";
        key = "<leader>wd";
        action = "<C-W>c";
        options.desc = "Delete Window";
      }

      # --- Move lines ---
      {
        mode = "n";
        key = "<A-j>";
        action = "<cmd>execute 'move .+' . v:count1<cr>==";
        options.desc = "Move Down";
      }
      {
        mode = "n";
        key = "<A-k>";
        action = "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==";
        options.desc = "Move Up";
      }
      {
        mode = "i";
        key = "<A-j>";
        action = "<esc><cmd>m .+1<cr>==gi";
        options.desc = "Move Down";
      }
      {
        mode = "i";
        key = "<A-k>";
        action = "<esc><cmd>m .-2<cr>==gi";
        options.desc = "Move Up";
      }
      {
        mode = "v";
        key = "<A-j>";
        action = ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv";
        options.desc = "Move Down";
      }
      {
        mode = "v";
        key = "<A-k>";
        action = ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv";
        options.desc = "Move Up";
      }

      # --- Buffers ---
      {
        mode = "n";
        key = "<S-h>";
        action = "<cmd>bprevious<cr>";
        options.desc = "Prev Buffer";
      }
      {
        mode = "n";
        key = "<S-l>";
        action = "<cmd>bnext<cr>";
        options.desc = "Next Buffer";
      }
      {
        mode = "n";
        key = "[b";
        action = "<cmd>bprevious<cr>";
        options.desc = "Prev Buffer";
      }
      {
        mode = "n";
        key = "]b";
        action = "<cmd>bnext<cr>";
        options.desc = "Next Buffer";
      }
      {
        mode = "n";
        key = "<leader>bb";
        action = "<cmd>e #<cr>";
        options.desc = "Switch to Other Buffer";
      }
      {
        mode = "n";
        key = "<leader>bd";
        action.__raw = "function() require('mini.bufremove').delete(0, false) end";
        options.desc = "Delete Buffer";
      }
      {
        mode = "n";
        key = "<leader>bo";
        action = "<cmd>%bdelete|edit #|bdelete #<cr>";
        options.desc = "Delete Other Buffers";
      }
      {
        mode = "n";
        key = "<leader>bD";
        action = "<cmd>bd<cr>";
        options.desc = "Delete Buffer and Window";
      }

      # --- Escape / save / indent ---
      {
        mode = [
          "i"
          "n"
          "s"
        ];
        key = "<esc>";
        action = "<cmd>noh<cr><esc>";
        options.desc = "Escape and Clear hlsearch";
      }
      {
        mode = [
          "i"
          "x"
          "n"
          "s"
        ];
        key = "<C-s>";
        action = "<cmd>w<cr><esc>";
        options.desc = "Save File";
      }
      {
        mode = "v";
        key = "<";
        action = "<gv";
        options.desc = "Indent Left";
      }
      {
        mode = "v";
        key = ">";
        action = ">gv";
        options.desc = "Indent Right";
      }
    ];
  };
}
