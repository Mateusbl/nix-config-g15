{ pkgs, ... }:

let
  # conform: use the first formatter that is available instead of running both
  prettier = {
    __unkeyed-1 = "prettierd";
    __unkeyed-2 = "prettier";
    stop_after_first = true;
  };
in
{
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

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

    # ==========================================
    # Autocommands
    # ==========================================
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
      {
        # Java: DAP hot-code-replace + refactor/test keymaps once jdtls attaches
        event = [ "LspAttach" ];
        desc = "jdtls DAP and Java keymaps";
        callback.__raw = ''
          function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if not client or client.name ~= "jdtls" then
              return
            end
            local ok, jdtls = pcall(require, "jdtls")
            if not ok then
              return
            end
            jdtls.setup_dap({ hotcodereplace = "auto" })
            pcall(function() require("jdtls.dap").setup_dap_main_class_configs() end)

            local map = function(mode, lhs, rhs, desc)
              vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = desc })
            end
            map("n", "<leader>co", jdtls.organize_imports, "Organize Imports")
            map("n", "<leader>crv", jdtls.extract_variable, "Extract Variable")
            map("v", "<leader>crv", function() jdtls.extract_variable(true) end, "Extract Variable")
            map("n", "<leader>crc", jdtls.extract_constant, "Extract Constant")
            map("v", "<leader>crc", function() jdtls.extract_constant(true) end, "Extract Constant")
            map("v", "<leader>crm", function() jdtls.extract_method(true) end, "Extract Method")
            map("n", "<leader>tc", jdtls.test_class, "Run Test Class (JDTLS)")
            map("n", "<leader>tm", jdtls.test_nearest_method, "Run Nearest Test (JDTLS)")
          end
        '';
      }
    ];

    # ==========================================
    # Plugins
    # ==========================================
    plugins = {
      # --- Icons & core UI ---
      web-devicons.enable = true;
      nui.enable = true;

      # --- Dashboard ---
      alpha = {
        enable = true;
        theme = "dashboard";
      };

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

      lazygit.enable = true;

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
            { __unkeyed-1 = "<leader>b"; group = "buffer"; }
            { __unkeyed-1 = "<leader>c"; group = "code"; }
            { __unkeyed-1 = "<leader>cr"; group = "refactor (java)"; }
            { __unkeyed-1 = "<leader>d"; group = "debug"; }
            { __unkeyed-1 = "<leader>f"; group = "file/find"; }
            { __unkeyed-1 = "<leader>g"; group = "git"; }
            { __unkeyed-1 = "<leader>q"; group = "quit/session"; }
            { __unkeyed-1 = "<leader>s"; group = "search"; }
            { __unkeyed-1 = "<leader>t"; group = "test"; }
            { __unkeyed-1 = "<leader>u"; group = "ui/toggle"; }
            { __unkeyed-1 = "<leader>w"; group = "windows"; }
            { __unkeyed-1 = "<leader>x"; group = "diagnostics/quickfix"; }
            { __unkeyed-1 = "["; group = "prev"; }
            { __unkeyed-1 = "]"; group = "next"; }
            { __unkeyed-1 = "g"; group = "goto"; }
            { __unkeyed-1 = "gs"; group = "surround"; }
          ];
        };
      };

      # --- Fuzzy finder ---
      fzf-lua = {
        enable = true;
        profile = "default";
	settings.winopts.tittle_pos = "center";
      };

      # --- Completion ---
      friendly-snippets.enable = true;
      blink-cmp = {
        enable = true;
        settings = {
          keymap.preset = "enter";
          appearance = {
            use_nvim_cmp_as_default = false;
            nerd_font_variant = "mono";
          };
          completion = {
            accept.auto_brackets.enabled = true;
            menu.draw.treesitter = [ "lsp" ];
            documentation = {
              auto_show = true;
              auto_show_delay_ms = 200;
            };
          };
          sources.default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
          ];
        };
      };

      # --- Treesitter ---
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
          incremental_selection = {
            enable = true;
            keymaps = {
              init_selection = "<C-space>";
              node_incremental = "<C-space>";
              scope_incremental = false;
              node_decremental = "<bs>";
            };
          };
        };
      };

      treesitter-textobjects = {
  enable = true;
  settings.move = {
    enable = true;
    set_jumps = true;
    goto_next_start = {
      "]f" = "@function.outer";
      "]c" = "@class.outer";
      "]a" = "@parameter.inner";
    };
    goto_next_end = {
      "]F" = "@function.outer";
      "]C" = "@class.outer";
      "]A" = "@parameter.inner";
    };
    goto_previous_start = {
      "[f" = "@function.outer";
      "[c" = "@class.outer";
      "[a" = "@parameter.inner";
    };
    goto_previous_end = {
      "[F" = "@function.outer";
      "[C" = "@class.outer";
      "[A" = "@parameter.inner";
    };
  };
};

      ts-autotag.enable = true;
      ts-comments.enable = true;

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

      # --- Git ---
      gitsigns = {
        enable = true;
        settings = {
          current_line_blame = true;
          signs = {
            add.text = "▎";
            change.text = "▎";
            delete.text = "▁";
            topdelete.text = "▔";
            changedelete.text = "▎";
            untracked.text = "▎";
          };
        };
      };

      # --- Java: nvim-jdtls (server + Java tooling come from the project's devenv shell) ---
      jdtls = {
        enable = true;
        jdtLanguageServerPackage = null; # `package` would be the nvim-jdtls plugin itself, keep it
        settings = {
          cmd = [
            "jdtls"
            "--jvm-arg=-javaagent:${pkgs.lombok}/share/java/lombok.jar"
          ];

          root_dir.__raw = "vim.fs.root(0, { 'gradlew', 'mvnw', 'pom.xml', 'build.gradle', '.git' })";

          init_options.bundles.__raw = ''
            (function()
              local bundles = {}
              local function add_jars(pattern)
                for _, jar in ipairs(vim.split(vim.fn.glob(pattern, true), "\n")) do
                  if jar ~= ""
                    and not jar:match("runner%-jar%-with%-dependencies")
                    and not jar:match("jacocoagent") then
                    table.insert(bundles, jar)
                  end
                end
              end
              add_jars("${pkgs.vscode-extensions.vscjava.vscode-java-debug}/share/vscode/extensions/vscjava.vscode-java-debug/server/com.microsoft.java.debug.plugin-*.jar")
              add_jars("${pkgs.vscode-extensions.vscjava.vscode-java-test}/share/vscode/extensions/vscjava.vscode-java-test/server/*.jar")
              return bundles
            end)()
          '';

          settings.java = {
            inlayHints.parameterNames.enabled = "all";
            autobuild.enabled = true;
            signatureHelp.enabled = true;
            contentProvider.preferred = "fernflower";
            saveActions.organizeImports = true;
            completion.favoriteStaticMembers = [
              "org.hamcrest.MatcherAssert.assertThat"
              "org.hamcrest.Matchers.*"
              "org.junit.jupiter.api.Assertions.*"
              "org.assertj.core.api.Assertions.*"
              "org.mockito.Mockito.*"
              "org.mockito.ArgumentMatchers.*"
              "org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*"
              "org.springframework.test.web.servlet.result.MockMvcResultMatchers.*"
            ];
          };
        };
      };

      # --- LSP (project servers come from devenv via package = null) ---
      lsp = {
        enable = true;
        inlayHints = true;
        keymaps = {
          diagnostic = {
            "]d" = "goto_next";
            "[d" = "goto_prev";
            "<leader>cd" = "open_float";
          };
          lspBuf = {
            "gd" = "definition";
            "gD" = "declaration";
            "gr" = "references";
            "gI" = "implementation";
            "gy" = "type_definition";
            "K" = "hover";
            "gK" = "signature_help";
            "<leader>ca" = "code_action";
            "<leader>cR" = "rename"; # <leader>cr is the Java refactor group
          };
        };
        servers = {
          # Global servers
          nil_ls.enable = true;
          lua_ls.enable = true;

          # Provided by devenv
          pyright = {
            enable = true;
            package = null;
          };
          ruff = {
            enable = true;
            package = null;
          };
          vtsls = {
            enable = true;
            package = null;
            settings = {
              vtsls = {
                enableMoveToFileCodeAction = true;
                autoUseWorkspaceTsdk = true;
                experimental.completion.enableServerSideFuzzyMatch = true;
              };
              typescript = {
                updateImportsOnFileMove.enabled = "always";
                suggest.completeFunctionCalls = true;
                inlayHints = {
                  enumMemberValues.enabled = true;
                  functionLikeReturnTypes.enabled = true;
                  parameterNames.enabled = "literals";
                  parameterTypes.enabled = true;
                  propertyDeclarationTypes.enabled = true;
                  variableTypes.enabled = false;
                };
              };
            };
          };
          angularls = {
            enable = true;
            package = null;
          };
          eslint = {
            enable = true;
            package = null;
          };
          tailwindcss = {
            enable = true;
            package = null;
          };
          html = {
            enable = true;
            package = null;
          };
          cssls = {
            enable = true;
            package = null;
          };
          jsonls = {
            enable = true;
            package = null;
          };
          yamlls = {
            enable = true;
            package = null;
          };
        };
      };

      # --- Formatting (binaries come from PATH / devenv) ---
      conform-nvim = {
        enable = true;
        settings = {
          formatters_by_ft = {
            nix = [ "nixfmt" ];
            lua = [ "stylua" ];
            python = [
              "ruff_organize_imports"
              "ruff_format"
            ];
            java = [ "google-java-format" ];
            javascript = prettier;
            typescript = prettier;
            javascriptreact = prettier;
            typescriptreact = prettier;
            html = prettier;
            htmlangular = prettier;
            css = prettier;
            scss = prettier;
            json = prettier;
            yaml = prettier;
          };
          format_on_save.__raw = ''
            function(bufnr)
              if not vim.g.autoformat then
                return
              end
              return { timeout_ms = 500, lsp_format = "fallback" }
            end
          '';
        };
      };

      # --- Debugging ---
      dap.enable = true;
      dap-ui.enable = true;
      dap-virtual-text.enable = true;
      dap-python.enable = true;

      # --- Testing ---
      neotest = {
        enable = true;
        adapters = {
          python.enable = true;
          jest.enable = true;
          vitest.enable = true;
          java.enable = true;
        };
      };
    };

    # ==========================================
    # Keymaps
    # ==========================================
    keymaps = [
      # --- Oil ---
      { mode = "n"; key = "-"; action = "<cmd>Oil<cr>"; options.desc = "Open parent directory in Oil"; }

      # --- Up/Down on wrapped lines ---
      { mode = [ "n" "x" ]; key = "j"; action = "v:count == 0 ? 'gj' : 'j'"; options = { expr = true; silent = true; }; }
      { mode = [ "n" "x" ]; key = "k"; action = "v:count == 0 ? 'gk' : 'k'"; options = { expr = true; silent = true; }; }

      # --- Windows ---
      { mode = "n"; key = "<C-h>"; action = "<C-w>h"; options.desc = "Go to Left Window"; }
      { mode = "n"; key = "<C-j>"; action = "<C-w>j"; options.desc = "Go to Lower Window"; }
      { mode = "n"; key = "<C-k>"; action = "<C-w>k"; options.desc = "Go to Upper Window"; }
      { mode = "n"; key = "<C-l>"; action = "<C-w>l"; options.desc = "Go to Right Window"; }
      { mode = "n"; key = "<C-Up>"; action = "<cmd>resize +2<cr>"; options.desc = "Increase Window Height"; }
      { mode = "n"; key = "<C-Down>"; action = "<cmd>resize -2<cr>"; options.desc = "Decrease Window Height"; }
      { mode = "n"; key = "<C-Left>"; action = "<cmd>vertical resize -2<cr>"; options.desc = "Decrease Window Width"; }
      { mode = "n"; key = "<C-Right>"; action = "<cmd>vertical resize +2<cr>"; options.desc = "Increase Window Width"; }
      { mode = "n"; key = "<leader>-"; action = "<C-W>s"; options.desc = "Split Window Below"; }
      { mode = "n"; key = "<leader>|"; action = "<C-W>v"; options.desc = "Split Window Right"; }
      { mode = "n"; key = "<leader>wd"; action = "<C-W>c"; options.desc = "Delete Window"; }

      # --- Move lines ---
      { mode = "n"; key = "<A-j>"; action = "<cmd>execute 'move .+' . v:count1<cr>=="; options.desc = "Move Down"; }
      { mode = "n"; key = "<A-k>"; action = "<cmd>execute 'move .-' . (v:count1 + 1)<cr>=="; options.desc = "Move Up"; }
      { mode = "i"; key = "<A-j>"; action = "<esc><cmd>m .+1<cr>==gi"; options.desc = "Move Down"; }
      { mode = "i"; key = "<A-k>"; action = "<esc><cmd>m .-2<cr>==gi"; options.desc = "Move Up"; }
      { mode = "v"; key = "<A-j>"; action = ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv"; options.desc = "Move Down"; }
      { mode = "v"; key = "<A-k>"; action = ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv"; options.desc = "Move Up"; }

      # --- Buffers ---
      { mode = "n"; key = "<S-h>"; action = "<cmd>bprevious<cr>"; options.desc = "Prev Buffer"; }
      { mode = "n"; key = "<S-l>"; action = "<cmd>bnext<cr>"; options.desc = "Next Buffer"; }
      { mode = "n"; key = "[b"; action = "<cmd>bprevious<cr>"; options.desc = "Prev Buffer"; }
      { mode = "n"; key = "]b"; action = "<cmd>bnext<cr>"; options.desc = "Next Buffer"; }
      { mode = "n"; key = "<leader>bb"; action = "<cmd>e #<cr>"; options.desc = "Switch to Other Buffer"; }
      { mode = "n"; key = "<leader>bd"; action.__raw = "function() require('mini.bufremove').delete(0, false) end"; options.desc = "Delete Buffer"; }
      { mode = "n"; key = "<leader>bo"; action = "<cmd>%bdelete|edit #|bdelete #<cr>"; options.desc = "Delete Other Buffers"; }
      { mode = "n"; key = "<leader>bD"; action = "<cmd>bd<cr>"; options.desc = "Delete Buffer and Window"; }

      # --- Escape / save / indent ---
      { mode = [ "i" "n" "s" ]; key = "<esc>"; action = "<cmd>noh<cr><esc>"; options.desc = "Escape and Clear hlsearch"; }
      { mode = [ "i" "x" "n" "s" ]; key = "<C-s>"; action = "<cmd>w<cr><esc>"; options.desc = "Save File"; }
      { mode = "v"; key = "<"; action = "<gv"; options.desc = "Indent Left"; }
      { mode = "v"; key = ">"; action = ">gv"; options.desc = "Indent Right"; }

      # --- Explorer, terminal, git ---
      { mode = "n"; key = "<leader>e"; action = "<cmd>Neotree toggle<cr>"; options.desc = "Explorer"; }
      { mode = "n"; key = "<leader>E"; action = "<cmd>Neotree reveal<cr>"; options.desc = "Explorer (current file)"; }
      { mode = [ "n" "t" ]; key = "<c-/>"; action = "<cmd>ToggleTerm<cr>"; options.desc = "Toggle Terminal"; }
      { mode = [ "n" "t" ]; key = "<c-_>"; action = "<cmd>ToggleTerm<cr>"; options.desc = "which_key_ignore"; }
      { mode = "n"; key = "<leader>ft"; action = "<cmd>ToggleTerm<cr>"; options.desc = "Terminal"; }
      { mode = "n"; key = "<leader>gg"; action = "<cmd>LazyGit<cr>"; options.desc = "Lazygit"; }
      { mode = "n"; key = "<leader>gb"; action = "<cmd>Gitsigns blame_line<cr>"; options.desc = "Git Blame Line"; }
      { mode = "n"; key = "<leader>gf"; action = "<cmd>LazyGitFilterCurrentFile<cr>"; options.desc = "Lazygit Current File History"; }

      # --- fzf-lua ---
      { mode = "n"; key = "<leader><space>"; action = "<cmd>FzfLua files<cr>"; options.desc = "Find Files"; }
      { mode = "n"; key = "<leader>,"; action = "<cmd>FzfLua buffers sort_mru=true sort_lastused=true<cr>"; options.desc = "Switch Buffer"; }
      { mode = "n"; key = "<leader>/"; action = "<cmd>FzfLua live_grep<cr>"; options.desc = "Grep"; }
      { mode = "n"; key = "<leader>:"; action = "<cmd>FzfLua command_history<cr>"; options.desc = "Command History"; }
      { mode = "n"; key = "<leader>ff"; action = "<cmd>FzfLua files<cr>"; options.desc = "Find Files"; }
      { mode = "n"; key = "<leader>fg"; action = "<cmd>FzfLua git_files<cr>"; options.desc = "Find Files (git-files)"; }
      { mode = "n"; key = "<leader>fr"; action = "<cmd>FzfLua oldfiles<cr>"; options.desc = "Recent"; }
      { mode = "n"; key = "<leader>fb"; action = "<cmd>FzfLua buffers sort_mru=true sort_lastused=true<cr>"; options.desc = "Buffers"; }
      { mode = "n"; key = "<leader>gc"; action = "<cmd>FzfLua git_commits<cr>"; options.desc = "Commits"; }
      { mode = "n"; key = "<leader>gs"; action = "<cmd>FzfLua git_status<cr>"; options.desc = "Status"; }
      { mode = "n"; key = "<leader>sb"; action = "<cmd>FzfLua lgrep_curbuf<cr>"; options.desc = "Buffer Lines"; }
      { mode = "n"; key = "<leader>sd"; action = "<cmd>FzfLua diagnostics_document<cr>"; options.desc = "Document Diagnostics"; }
      { mode = "n"; key = "<leader>sD"; action = "<cmd>FzfLua diagnostics_workspace<cr>"; options.desc = "Workspace Diagnostics"; }
      { mode = "n"; key = "<leader>sg"; action = "<cmd>FzfLua live_grep<cr>"; options.desc = "Grep"; }
      { mode = "n"; key = "<leader>sh"; action = "<cmd>FzfLua help_tags<cr>"; options.desc = "Help Pages"; }
      { mode = "n"; key = "<leader>sk"; action = "<cmd>FzfLua keymaps<cr>"; options.desc = "Key Maps"; }
      { mode = "n"; key = "<leader>sm"; action = "<cmd>FzfLua marks<cr>"; options.desc = "Jump to Mark"; }
      { mode = "n"; key = "<leader>sR"; action = "<cmd>FzfLua resume<cr>"; options.desc = "Resume"; }
      { mode = "n"; key = "<leader>ss"; action = "<cmd>FzfLua lsp_document_symbols<cr>"; options.desc = "Goto Symbol"; }
      { mode = "n"; key = "<leader>sS"; action = "<cmd>FzfLua lsp_live_workspace_symbols<cr>"; options.desc = "Goto Symbol (Workspace)"; }
      { mode = "n"; key = "<leader>sw"; action = "<cmd>FzfLua grep_cword<cr>"; options.desc = "Word"; }

      # --- Flash ---
      { mode = [ "n" "x" "o" ]; key = "s"; action.__raw = "function() require('flash').jump() end"; options.desc = "Flash"; }
      { mode = [ "n" "o" "x" ]; key = "S"; action.__raw = "function() require('flash').treesitter() end"; options.desc = "Flash Treesitter"; }
      { mode = "o"; key = "r"; action.__raw = "function() require('flash').remote() end"; options.desc = "Remote Flash"; }
      { mode = [ "o" "x" ]; key = "R"; action.__raw = "function() require('flash').treesitter_search() end"; options.desc = "Treesitter Search"; }

      # --- Grug-far ---
      { mode = [ "n" "v" ]; key = "<leader>sr"; action = "<cmd>GrugFar<cr>"; options.desc = "Search and Replace"; }

      # --- Formatting ---
      { mode = [ "n" "v" ]; key = "<leader>cf"; action.__raw = "function() require('conform').format({ async = true, lsp_format = 'fallback' }) end"; options.desc = "Format Document"; }

      # --- Trouble & todo-comments ---
      { mode = "n"; key = "<leader>xx"; action = "<cmd>Trouble diagnostics toggle<cr>"; options.desc = "Diagnostics (Trouble)"; }
      { mode = "n"; key = "<leader>xX"; action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>"; options.desc = "Buffer Diagnostics (Trouble)"; }
      { mode = "n"; key = "<leader>cs"; action = "<cmd>Trouble symbols toggle<cr>"; options.desc = "Symbols (Trouble)"; }
      { mode = "n"; key = "<leader>xL"; action = "<cmd>Trouble loclist toggle<cr>"; options.desc = "Location List (Trouble)"; }
      { mode = "n"; key = "<leader>xQ"; action = "<cmd>Trouble qflist toggle<cr>"; options.desc = "Quickfix List (Trouble)"; }
      { mode = "n"; key = "<leader>xt"; action = "<cmd>Trouble todo toggle<cr>"; options.desc = "Todo (Trouble)"; }
      { mode = "n"; key = "<leader>st"; action = "<cmd>TodoFzfLua<cr>"; options.desc = "Todo (FzfLua)"; }
      { mode = "n"; key = "]t"; action.__raw = "function() require('todo-comments').jump_next() end"; options.desc = "Next Todo Comment"; }
      { mode = "n"; key = "[t"; action.__raw = "function() require('todo-comments').jump_prev() end"; options.desc = "Previous Todo Comment"; }

      # --- UI toggles ---
      { mode = "n"; key = "<leader>uf"; action.__raw = "function() vim.g.autoformat = not vim.g.autoformat; vim.notify('Autoformat: ' .. tostring(vim.g.autoformat)) end"; options.desc = "Toggle Auto Format"; }
      { mode = "n"; key = "<leader>uw"; action = "<cmd>set wrap!<cr>"; options.desc = "Toggle Word Wrap"; }
      { mode = "n"; key = "<leader>ul"; action = "<cmd>set relativenumber!<cr>"; options.desc = "Toggle Relative Number"; }
      { mode = "n"; key = "<leader>uh"; action.__raw = "function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end"; options.desc = "Toggle Inlay Hints"; }
      { mode = "n"; key = "<leader>uz"; action = "<cmd>ZenMode<cr>"; options.desc = "Toggle Zen Mode"; }
      { mode = "n"; key = "<leader>un"; action.__raw = "function() require('notify').dismiss({ silent = true, pending = true }) end"; options.desc = "Dismiss All Notifications"; }

      # --- DAP ---
      { mode = "n"; key = "<leader>db"; action.__raw = "function() require('dap').toggle_breakpoint() end"; options.desc = "Toggle Breakpoint"; }
      { mode = "n"; key = "<leader>dc"; action.__raw = "function() require('dap').continue() end"; options.desc = "Run/Continue"; }
      { mode = "n"; key = "<leader>di"; action.__raw = "function() require('dap').step_into() end"; options.desc = "Step Into"; }
      { mode = "n"; key = "<leader>do"; action.__raw = "function() require('dap').step_out() end"; options.desc = "Step Out"; }
      { mode = "n"; key = "<leader>dO"; action.__raw = "function() require('dap').step_over() end"; options.desc = "Step Over"; }
      { mode = "n"; key = "<leader>dt"; action.__raw = "function() require('dap').terminate() end"; options.desc = "Terminate"; }
      { mode = "n"; key = "<leader>du"; action.__raw = "function() require('dapui').toggle({}) end"; options.desc = "Dap UI"; }
      { mode = [ "n" "v" ]; key = "<leader>de"; action.__raw = "function() require('dapui').eval() end"; options.desc = "Eval"; }

      # --- Neotest ---
      { mode = "n"; key = "<leader>tt"; action.__raw = "function() require('neotest').run.run(vim.fn.expand('%')) end"; options.desc = "Run File (Neotest)"; }
      { mode = "n"; key = "<leader>tT"; action.__raw = "function() require('neotest').run.run(vim.uv.cwd()) end"; options.desc = "Run All Test Files (Neotest)"; }
      { mode = "n"; key = "<leader>tr"; action.__raw = "function() require('neotest').run.run() end"; options.desc = "Run Nearest (Neotest)"; }
      { mode = "n"; key = "<leader>tl"; action.__raw = "function() require('neotest').run.run_last() end"; options.desc = "Run Last (Neotest)"; }
      { mode = "n"; key = "<leader>ts"; action.__raw = "function() require('neotest').summary.toggle() end"; options.desc = "Toggle Summary (Neotest)"; }
      { mode = "n"; key = "<leader>to"; action.__raw = "function() require('neotest').output.open({ enter = true, auto_close = true }) end"; options.desc = "Show Output (Neotest)"; }
      { mode = "n"; key = "<leader>tO"; action.__raw = "function() require('neotest').output_panel.toggle() end"; options.desc = "Toggle Output Panel (Neotest)"; }
      { mode = "n"; key = "<leader>tS"; action.__raw = "function() require('neotest').run.stop() end"; options.desc = "Stop (Neotest)"; }

      # --- Session / quit ---
      { mode = "n"; key = "<leader>qs"; action.__raw = "function() require('persistence').load() end"; options.desc = "Restore Session"; }
      { mode = "n"; key = "<leader>ql"; action.__raw = "function() require('persistence').load({ last = true }) end"; options.desc = "Restore Last Session"; }
      { mode = "n"; key = "<leader>qd"; action.__raw = "function() require('persistence').stop() end"; options.desc = "Don't Save Current Session"; }
      { mode = "n"; key = "<leader>qq"; action = "<cmd>qa<cr>"; options.desc = "Quit All"; }
    ];

    # ==========================================
    # Extra plugins & global tooling
    # ==========================================
    extraPlugins = with pkgs.vimPlugins; [
      direnv-vim
    ];

    # Editor-level tools stay global; project toolchains live in devenv
    extraPackages = with pkgs; [
      ripgrep
      fd
      fzf
      lazygit
      tree-sitter
      nixfmt
      stylua
    ];
  };
}
