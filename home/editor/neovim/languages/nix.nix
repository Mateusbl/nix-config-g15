# Nix: nil language server and nixfmt. Both are editor-owned (installed with Neovim).
{ pkgs, ... }:

{
  programs.nixvim = {
    plugins.lsp.servers.nil_ls.enable = true;
    plugins.conform-nvim.settings.formatters_by_ft.nix = [ "nixfmt" ];
    extraPackages = [ pkgs.nixfmt ];
  };
}
