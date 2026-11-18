{ pkgs, username, ... }:

{
  # sudo-rs: a memory-safe rewrite of sudo with the same command and config format. Only
  # members of "wheel" may even run the binary.
  security.sudo-rs = {
    enable = true;
    execWheelOnly = true;
  };

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
