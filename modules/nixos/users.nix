{ pkgs, username, ... }:

{
  security.sudo.execWheelOnly = true;

  programs.zsh = {
    enable = true;
    enableCompletion = false; # handled by Home Manager
  };

  users.users.${username} = {
    isNormalUser = true;
    description = "Mateus Barbosa Lopes";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "dialout"
    ];
    shell = pkgs.zsh;
  };
}
