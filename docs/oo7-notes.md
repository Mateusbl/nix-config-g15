# oo7 notes

[oo7](https://github.com/linux-credentials/oo7) is the only Secret Service
(`org.freedesktop.secrets`) on this machine. Apps that store passwords through libsecret
(browsers, NetworkManager applets, git credential helpers that use libsecret, …) talk to it.

## What is set up (`modules/nixos/secrets.nix`)

| Piece | Where it comes from |
| --- | --- |
| `oo7-daemon` (the Secret Service) | nixpkgs `oo7-server`, started as a systemd **user** service at login (`services.oo7.enable`) |
| D-Bus activation of `org.freedesktop.secrets` | `oo7-server`'s D-Bus file, plus a unit alias `dbus-org.freedesktop.secrets.service` added in this repo (the upstream unit lacks it, so activation would fail if the daemon is not already running) |
| Unlock at login | `pam_oo7` on the `login` PAM service (nixpkgs module). greetd's PAM service includes `login` with `substack`/`include`, so the keyring is unlocked with your login password |
| Secret portal for sandboxed apps | `oo7-portal`, chosen explicitly in `/etc/xdg/xdg-desktop-portal/hyprland-portals.conf` (`org.freedesktop.impl.portal.Secret=oo7-portal`). Without that line it would never be used: Hyprland's own portals file lists only `hyprland;gtk` (here replaced by `hyprland`, there is no GTK portal), and oo7-portal declares itself for GNOME |
| CLI (secret-tool replacement) | `oo7-cli` |
| Only provider | `services.gnome.gnome-keyring.enable = mkForce false`, plus assertions against pass-secret-service and KWallet. KeePassXC's Secret Service integration is off (KeePassXC is not installed) |

oo7's README says gnome-keyring-daemon must be stopped first. Nothing here starts it.

## How the portal is chosen

xdg-desktop-portal reads `<desktop>-portals.conf` for `XDG_CURRENT_DESKTOP=Hyprland`, i.e.
`hyprland-portals.conf`, and picks an implementation per interface. The NixOS file in
`/etc/xdg` takes precedence over the one shipped in the Hyprland package. That is why the
default line is repeated there, as `default=hyprland` (there is no GTK portal; open/save dialogs
are assigned to termfilechooser in `modules/nixos/desktop.nix`).

## Verify (after `nh os switch` and a fresh login)

1. Daemon running and owning the name:

   ```bash
   systemctl --user status oo7-daemon
   ```

   ```bash
   busctl --user introspect org.freedesktop.secrets /org/freedesktop/secrets
   ```

   The second shows the `org.freedesktop.Secret.Service` interface.

2. Store and read back a secret. `store` asks for the secret:

   ```bash
   oo7-cli store "oo7 test" app=oo7-test
   ```

   ```bash
   oo7-cli lookup app=oo7-test
   ```

   ```bash
   oo7-cli delete app=oo7-test
   ```

3. Unlock at login: log out, log in again at the login screen (greetd), then run `oo7-cli lookup app=…` again. It should
   answer without asking for a password. If it asks, the keyring password and the login
   password differ (see below).

4. Portal choice:

   ```bash
   cat /etc/xdg/xdg-desktop-portal/hyprland-portals.conf
   ```

   ```bash
   systemctl --user status xdg-desktop-portal
   ```

## Gaps and things to know (oo7 0.6 is young)

- **No git credential helper.** The nixpkgs package does not build oo7's
  `cargo-credential`/git helper. Git and jj use SSH (`services.ssh-agent`), so nothing needs it
  today.
- **Login password ≠ keyring password.** If you change your user password, the keyring keeps the
  old one. pam_oo7 then cannot unlock it at login, and oo7 prompts separately. Change both
  together.
- **Memory locking.** The nixpkgs module installs `oo7-daemon` behind a wrapper with
  `cap_ipc_lock`. But the upstream unit sets `NoNewPrivileges=true`, which stops file
  capabilities from applying. So secrets in the daemon's memory may be swapped out. Swap is
  LUKS-encrypted here, which limits the risk.
- **Apps that insist on gnome-keyring.** Apps that call gnome-keyring APIs directly, instead of the
  Secret Service, will not find a keyring. Report them; there is nothing to configure.
- **Screen lock.** hyprlock does not lock or unlock the keyring. It stays unlocked for the session.

## Fallbacks

If oo7 misbehaves, switching to gnome-keyring is two lines in `modules/nixos/secrets.nix`:
`services.oo7.enable = false;` and `services.gnome.gnome-keyring.enable = true;` (drop the
`mkForce`). Also add `security.pam.services.login.enableGnomeKeyring = true;`. Secrets stored in
oo7 do not migrate automatically, so note down anything important first.
