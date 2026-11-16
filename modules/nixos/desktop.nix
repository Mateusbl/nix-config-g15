# Display manager, Hyprland (UWSM), portals.
{ config, pkgs, ... }:

let
  # ly takes 24-bit colours as 0xSSRRGGBB (SS = style bits: 01 bold). The values come from the
  # Stylix palette, so the login screen matches the desktop (and its "matrix" rain is blue, not
  # the default green).
  palette = config.lib.stylix.colors;
  plain = color: "0x00${color}";
  bold = color: "0x01${color}";
in

{
  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "matrix";
      clock = "%c";
      bigclock = "en"; # none | en | fa (it is a language, not on/off)

      bg = plain palette.base00;
      fg = plain palette.base05;
      border_fg = plain palette.base0D;
      error_fg = bold palette.base08;
      cmatrix_fg = plain palette.base0D;
      cmatrix_head_col = bold palette.base0C;
    };
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
  security.pam.services.hyprlock = { };

  # Electron apps run natively on Wayland instead of XWayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # GTK portal so file-open/save dialogs work in apps under Hyprland
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # Removable drives: Yazi's mount plugin (`M`) mounts and ejects them through udisks.
  services.udisks2.enable = true;
  programs.dconf.enable = true; # needed for Stylix/home-manager GTK settings
}
