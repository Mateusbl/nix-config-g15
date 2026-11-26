# Editor options, globals, clipboard and generic autocommands.
_:

{
  programs.nixvim = {
    # ==========================================
    # Clipboard providers (needed for clipboard = "unnamedplus")
    # ==========================================
    clipboard.providers = {
      wl-copy.enable = true;
      xclip.enable = true;
    };

    # ==========================================
    # Globals & Options
    # ==========================================
    globals = {
      mapleader = " ";
      maplocalleader = "\\";
      autoformat = true; # read by the conform format_on_save hook below
    };

    opts = {
      autowrite = true;
      clipboard = "unnamedplus";
      completeopt = "menu,menuone,noselect";
      conceallevel = 2;
      confirm = true;
      cursorline = true;
      expandtab = true;
      fillchars = {
        foldopen = "▾";
        foldclose = "▸";
        fold = " ";
        foldsep = " ";
        diff = "╱";
        eob = " ";
      };
      foldlevel = 99;
      ignorecase = true;
      inccommand = "nosplit";
      jumpoptions = "view";
      laststatus = 3; # global statusline
      linebreak = true;
      list = true;
      mouse = "a";
      number = true;
      pumblend = 10;
      pumheight = 10;
      relativenumber = true;
      scrolloff = 4;
      sessionoptions = [
        "buffers"
        "curdir"
        "tabpages"
        "winsize"
        "help"
        "globals"
        "skiprtp"
        "folds"
      ];
      shiftround = true;
      shiftwidth = 2;
      shortmess = "ltToOCFIc";
      showmode = false;
      sidescrolloff = 8;
      signcolumn = "yes";
      smartcase = true;
      smartindent = true;
      smoothscroll = true;
      splitbelow = true;
      splitkeep = "screen";
      splitright = true;
      tabstop = 2;
      termguicolors = true;
      timeoutlen = 300;
      undofile = true;
      undolevels = 10000;
      updatetime = 200;
      virtualedit = "block";
      wildmode = "longest:full,full";
      winminwidth = 5;
      wrap = false;
    };
    autoCmd = [
      {
        event = [ "TextYankPost" ];
        desc = "Highlight on yank";
        callback.__raw = ''
          function()
            (vim.hl or vim.highlight).on_yank()
          end
        '';
      }
      {
        event = [ "VimResized" ];
        desc = "Resize splits if window got resized";
        callback.__raw = ''
          function()
            local current_tab = vim.fn.tabpagenr()
            vim.cmd("tabdo wincmd =")
            vim.cmd("tabnext " .. current_tab)
          end
        '';
      }
      {
        event = [ "FileType" ];
        pattern = [
          "help"
          "lspinfo"
          "man"
          "notify"
          "qf"
          "checkhealth"
          "grug-far"
          "neotest-output"
          "neotest-summary"
          "neotest-output-panel"
        ];
        desc = "Close utility buffers with <q>";
        callback.__raw = ''
          function(event)
            vim.bo[event.buf].buflisted = false
            vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
          end
        '';
      }
    ];
  };
}
