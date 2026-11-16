# Two commands to check the machine after a rebuild. They are defined in tests/ so that
# `nix flake check` can run the Neovim one too.
{ pkgs, ... }:

{
  home.packages = [
    (import ../tests/nvim-smoke-script.nix { inherit pkgs; }) # nvim-smoke
    (import ../tests/post-switch-check.nix { inherit pkgs; }) # post-switch-check
  ];
}
