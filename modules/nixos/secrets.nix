# Secret Service (org.freedesktop.secrets) provided by oo7, and nothing else.
# Background, verification and fallbacks: docs/oo7-notes.md.
{ config, lib, ... }:

{
  # nixpkgs' oo7 module installs oo7-cli, the oo7-daemon user service (started at login),
  # its D-Bus activation file, the Secret portal (oo7-portal), and pam_oo7 on the `login`
  # PAM service. The login screen's PAM service (greetd) includes `login` for auth and session,
  # so the keyring is unlocked with the login password.
  services.oo7.enable = true;

  # The D-Bus activation file asks systemd for "dbus-org.freedesktop.secrets.service", but
  # the oo7-daemon unit does not declare that alias. Without it, an app that asks for secrets
  # while the daemon is not running gets an activation error instead of starting it.
  systemd.user.services.oo7-daemon.aliases = [ "dbus-org.freedesktop.secrets.service" ];

  # Which portal implements each interface is chosen per desktop. Hyprland's own config only
  # lists "hyprland;gtk", and oo7-portal declares itself for GNOME only, so the Secret portal
  # (used by sandboxed apps) is assigned explicitly. This file replaces hyprland-portals.conf,
  # so its default line is repeated.
  xdg.portal.config.hyprland = {
    default = [
      "hyprland"
      "gtk"
    ];
    "org.freedesktop.impl.portal.Secret" = [ "oo7-portal" ];
  };

  # oo7 must be the only provider: two daemons fight over the same D-Bus name.
  # mkForce, so no other module (e.g. a desktop environment) can turn gnome-keyring on.
  services.gnome.gnome-keyring.enable = lib.mkForce false;
  assertions = [
    {
      assertion = !config.services.passSecretService.enable;
      message = "pass-secret-service would compete with oo7 for org.freedesktop.secrets.";
    }
    {
      assertion = !(config.security.pam.services.login.kwallet.enable or false);
      message = "KWallet would compete with oo7 as the Secret Service.";
    }
  ];
}
