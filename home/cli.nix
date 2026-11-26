# Command-line tools (no GUI, no shell integration beyond what shell.nix sets up).
{ pkgs, ... }:

{
  programs.bat.enable = true;

  programs.btop = {
    enable = true;
    settings.vim_keys = true;
  };

  programs.ripgrep = {
    enable = true;
    arguments = [
      "--smart-case"
      "--hidden"
      "--glob=!.git/*"
    ];
  };

  programs.fd = {
    enable = true;
    hidden = true;
    ignores = [ ".git/" ];
  };

  home.packages = with pkgs; [
    jaq # jq-compatible JSON tool, faster and written in Rust (`jaq` instead of `jq`)
    dust
    duf
    sd
    tlrc
    xh
    tokei
    fastfetch
    devenv
  ];
}
