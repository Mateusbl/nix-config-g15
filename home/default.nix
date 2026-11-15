# Home Manager entry point. username/homeDirectory come from the NixOS home-manager module.
{
  imports = [
    ./shell.nix
    ./git.nix
    ./cli.nix
    ./session.nix
    ./hyprland.nix
    ./vscode.nix
    ./editor/neovim # nixvim, split into one file per topic
    ./yazi.nix
    ./jujutsu.nix
    ./desktop-scripts.nix
    ./desktop-extras.nix
  ];

  home.stateVersion = "26.05";
}
