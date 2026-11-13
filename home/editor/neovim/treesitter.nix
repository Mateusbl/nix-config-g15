# Syntax trees: highlighting, indentation, text objects, auto-closing tags, comments.
{ pkgs, ... }:

{
  programs.nixvim = {
    plugins = {
      # Sticky scroll: keeps the enclosing function/class header visible at the top.
      treesitter-context = {
        enable = true;
        settings.max_lines = 3;
      };

      # --- Treesitter ---
      # Grammars: nixvim's default `grammarPackages` = every grammar built by nixpkgs
      # (nvim-treesitter.allGrammars), so nothing is compiled or downloaded at runtime.
      treesitter = {
        enable = true;
        settings = {
          # Never download a missing grammar when a file is opened.
          auto_install = false;
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
    };

    # :TSInstall / :TSUpdate download and compile grammars at runtime, which this config
    # does not allow (CLAUDE.md). nvim-treesitter defines them from its plugin/ file after
    # init.lua runs, so they are replaced once startup is done.
    extraConfigLuaPost = ''
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          for _, cmd in ipairs({ "TSInstall", "TSInstallFromGrammar", "TSUpdate", "TSUninstall" }) do
            vim.api.nvim_create_user_command(cmd, function()
              vim.notify("Treesitter grammars come from nixpkgs (home/editor/neovim/treesitter.nix); :" .. cmd .. " is disabled.", vim.log.levels.WARN)
            end, { nargs = "*", force = true, desc = "Disabled: grammars come from nixpkgs" })
          end
        end,
      })
    '';

    keymaps = [
      {
        mode = "n";
        key = "<leader>uc";
        action = "<cmd>TSContext toggle<cr>";
        options.desc = "Toggle Sticky Scroll";
      }
    ];
  };
}
