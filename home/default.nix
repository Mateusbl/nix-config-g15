# Home Manager entry point. username/homeDirectory come from the NixOS home-manager module.
{
  imports = [
    ./shell.nix
    ./git.nix
    ./cli.nix
    ./session.nix
    ./hyprland.nix
    ./editor/neovim # nixvim, split into one file per topic
    ./yazi.nix
    ./jujutsu.nix
    ./desktop-scripts.nix
    ./desktop-extras.nix
    ./battery-warning.nix
    ./window-switcher.nix
    ./ghostty-cursor.nix
  ];

  home.stateVersion = "26.05";
}
