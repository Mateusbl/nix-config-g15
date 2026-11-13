# Git: gutter signs and blame (gitsigns), lazygit.
{ pkgs, ... }:

{
  programs.nixvim = {
    plugins = {
      lazygit.enable = true;
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
    };
    keymaps = [
      {
        mode = "n";
        key = "<leader>gg";
        action = "<cmd>LazyGit<cr>";
        options.desc = "Lazygit";
      }
      {
        mode = "n";
        key = "<leader>gb";
        action = "<cmd>Gitsigns blame_line<cr>";
        options.desc = "Git Blame Line";
      }
      {
        mode = "n";
        key = "<leader>gf";
        action = "<cmd>LazyGitFilterCurrentFile<cr>";
        options.desc = "Lazygit Current File History";
      }
    ];
  };
}
