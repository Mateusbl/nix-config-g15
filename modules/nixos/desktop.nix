# Display manager, Hyprland (UWSM), portals and the Thunar file-manager stack.
{ pkgs, ... }:

{
  services.displayManager.ly = {
    enable = true;
    settings = {
      animate = true;
      animation = "matrix";
      clock = "%c";
      bigclock = true;
    };
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
  security.pam.services.hyprlock = { };

  # Electron apps (VS Code, etc.) run natively on Wayland instead of XWayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # GTK portal so file-open/save dialogs work in apps under Hyprland
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # Thunar & companions
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };
  programs.xfconf.enable = true; # Thunar preferences persist outside XFCE
  services.gvfs.enable = true; # trash, mounts, network shares
  services.udisks2.enable = true; # removable drives show up in Thunar
  services.tumbler.enable = true; # thumbnails
  programs.dconf.enable = true; # needed for Stylix/home-manager GTK settings
}
