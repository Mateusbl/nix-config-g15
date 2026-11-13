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
    };

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
