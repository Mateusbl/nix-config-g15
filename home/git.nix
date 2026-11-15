# Git (over SSH; no gh). Identity comes from ./identity.nix, shared with Jujutsu.
let
  identity = import ./identity.nix;
in
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        inherit (identity) name email;
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
    };
  };

  programs.lazygit.enable = true;
}
