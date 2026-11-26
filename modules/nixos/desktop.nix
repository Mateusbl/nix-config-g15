# Login screen, Hyprland, portals.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Login screen: greetd, a small login daemon that runs the greeter as its own unprivileged user,
  # with tuigreet as the greeter (a text login prompt on the console). It lists the installed
  # sessions (Hyprland) and remembers the last user and session. Its colours are the console's
  # 16 colours, which Stylix already sets to the palette, so names like "blue" are base0D.
  services.greetd = {
    enable = true;
    useTextGreeter = true; # keeps boot messages from drawing over the prompt
    settings.default_session.command = lib.concatStringsSep " " [
      "${pkgs.tuigreet}/bin/tuigreet"
      "--time"
      "--remember"
      "--remember-session"
      "--asterisks"
      "--sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions"
      "--theme 'border=blue;text=white;prompt=cyan;time=blue;action=blue;button=cyan;container=black;input=white'"
    ];
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

  # GTK portal so file-open/save dialogs work in apps under Hyprland
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # Removable drives: Yazi's mount plugin (`M`) mounts and ejects them through udisks.
  services.udisks2.enable = true;
  programs.dconf.enable = true; # needed for Stylix/home-manager GTK settings
}
