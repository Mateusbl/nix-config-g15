# Git: gutter signs and blame (gitsigns), lazygit.
{ pkgs, ... }:

{
  programs.nixvim = {
    plugins = {
      # Side-by-side diffs and file history (VS Code's diff editor / timeline).
      diffview.enable = true;

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
        key = "<leader>gd";
        action = "<cmd>DiffviewOpen<cr>";
        options.desc = "Diff View (working tree)";
      }
      {
        mode = "n";
        key = "<leader>gD";
        action = "<cmd>DiffviewClose<cr>";
        options.desc = "Close Diff View";
      }
      {
        mode = "n";
        key = "<leader>gh";
        action = "<cmd>DiffviewFileHistory %<cr>";
        options.desc = "File History";
      }
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
