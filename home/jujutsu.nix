# Jujutsu (jj): a Git-compatible VCS. Repos are colocated (a normal .git next to .jj), so
# git, lazygit and Neovim's gitsigns keep working on the same repo.
# git -> jj translations: docs/jj-cheatsheet.md.
{ pkgs, ... }:

let
  identity = import ./identity.nix;
in
{
  programs.jujutsu = {
    enable = true; # the jj package also installs its zsh completion
    settings = {
      user = {
        inherit (identity) name email;
      };

      # Colocated is jj's default already; set explicitly because the git tools above rely on it.
      git.colocate = true;

      ui = {
        # delta (configured for git in home/git.nix) needs git-style diffs.
        pager = "delta";
        diff-formatter = ":git";
        default-command = "log";
      };
      # delta exits with 1 when there are differences; that is not an error.
      merge-tools.delta.diff-expected-exit-codes = [
        0
        1
      ];

      aliases = {
        # Move the nearest bookmark up to the last finished change, before `jj git push`.
        tug = [
          "bookmark"
          "move"
          "--from"
          "heads(::@- & bookmarks())"
          "--to"
          "@-"
        ];
        # Everything not yet on the remote main line, plus a little context.
        l = [
          "log"
          "-r"
          "(trunk()..@):: | (trunk()..@)-"
        ];
      };
    };
  };

  # One TUI: jjui. Of the two packaged ones (jjui, lazyjj) it covers more of jj (rebase,
  # squash, bookmarks, the operation log, revset input) and is more actively developed.
  home.packages = [ pkgs.jjui ];

  # SSH agent for git/jj over SSH. No keys are created here.
  services.ssh-agent.enable = true;

  # The first time a key is used in a session, ssh asks for its passphrase and hands the key to
  # the agent ("AddKeysToAgent"), so later pushes and fetches don't ask again. No `ssh-add` needed.
  # enableDefaultConfig = false: home-manager's old built-in defaults are being removed (it
  # warns about them) and they equal OpenSSH's own defaults anyway.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*".AddKeysToAgent = "yes";
  };
}
