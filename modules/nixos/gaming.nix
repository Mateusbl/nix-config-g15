{ config, pkgs, ... }:

let
  powerprofilesctl = "${config.services.power-profiles-daemon.package}/bin/powerprofilesctl";
in
{
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    protontricks.enable = true;
  };

  programs.gamemode = {
    enable = true;
    settings = {
      general.renice = 10;
      custom = {
        start = "${powerprofilesctl} set performance";
        end = "${powerprofilesctl} set balanced";
      };
    };
  };

  environment.sessionVariables.__GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
}
