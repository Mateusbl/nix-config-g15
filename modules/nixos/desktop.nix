# Login screen, Hyprland, portals.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Login screen: greetd, a small login daemon that runs the greeter as its own unprivileged user.
  # The greeter is ctOS (modules/nixos/ctos-greeter.nix); tuigreet below, a text login prompt on
  # the console, is the fallback used when `my.ctosGreeter.enable = false`. It lists the installed
  # sessions (Hyprland) and remembers the last user and session. Its colours are the console's
  # 16 colours, which Stylix already sets to the palette, so names like "blue" are base0D.
  services.greetd = {
    enable = true;
    # For the text greeter only: keeps boot messages from drawing over its prompt.
    useTextGreeter = !config.my.ctosGreeter.enable;
    settings.default_session.command = lib.mkDefault (
      lib.concatStringsSep " " [
        "${pkgs.tuigreet}/bin/tuigreet"
        "--time"
        "--remember"
        "--remember-session"
        "--asterisks"
        "--sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions"
        "--theme 'border=blue;text=white;prompt=cyan;time=blue;action=blue;button=cyan;container=black;input=white'"
      ]
    );
  };

  programs.hyprland = {
    enable = true;
    # No UWSM: home-manager starts and stops the session services itself (home/hyprland.nix).
    withUWSM = false;
    xwayland.enable = true;
  };
  security.pam.services.hyprlock = { };

  # Electron apps run natively on Wayland instead of XWayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Portals: how apps ask the desktop for a screenshot, a screen share, a secret or a file.
  # No GTK portal: open/save dialogs are Yazi in a terminal window instead (termfilechooser,
  # configured in home/session.nix). The Hyprland module always adds the GTK portal, so the list
  # is forced to exactly these three:
  #   hyprland          screenshots, screen sharing, global shortcuts
  #   oo7-portal        secrets for sandboxed apps (modules/nixos/secrets.nix)
  #   termfilechooser   open/save dialogs
  xdg.portal.extraPortals = lib.mkForce [
    config.programs.hyprland.portalPackage
    pkgs.oo7-portal
    pkgs.xdg-desktop-portal-termfilechooser
  ];
  # Every interface Hyprland's portal implements is assigned to it by name, so no other portal
  # can take one over. Its screen-share picker is drawn with hyprtoolkit (no GTK, no Qt).
  xdg.portal.config.hyprland = {
    "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
    "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
    "org.freedesktop.impl.portal.GlobalShortcuts" = [ "hyprland" ];
    "org.freedesktop.impl.portal.InputCapture" = [ "hyprland" ];
    "org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
  };

  # Removable drives: Yazi's mount plugin (`M`) mounts and ejects them through udisks.
  services.udisks2.enable = true;
  # dconf is a small settings store, not a GUI. home-manager writes the GTK theme settings there
  # for the two GTK programs that stay (Ghostty, LibreWolf).
  programs.dconf.enable = true;
}
