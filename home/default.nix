# Home Manager entry point. username/homeDirectory come from the NixOS home-manager module.
{
  imports = [
    ./shell.nix
    ./git.nix
    ./cli.nix
    ./session.nix
    ./hyprland.nix
    ./vscode.nix
    ./neovim.nix # Phase 3 of the VS Code migration: remove this line (and the nixvim input)
  ];

  home.stateVersion = "26.05";
}
