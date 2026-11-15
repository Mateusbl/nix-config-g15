# Zsh, prompt and the small tools that integrate with the shell.
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      # No grep/find aliases on purpose: rg and fd have different flags.
      cat = "bat";
      catp = "bat -p";
      top = "btop";
      lg = "lazygit";
      nrs = "nh os switch";
      nrt = "nh os test";
      clean = "nh clean all --keep-since 4d --keep 3";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ];
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # Direnv + nix-direnv (devenv / flake dev shells)
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
