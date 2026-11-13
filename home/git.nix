{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Mateus Barbosa Lopes";
        email = "mateusbarbosa999@gmail.com";
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
