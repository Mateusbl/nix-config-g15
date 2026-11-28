# Questions for the owner

Decisions the config cannot make on its own. Each one lists the default that is in place now.

## GTK/Qt: the two GTK programs that stay

Everything else GTK or Qt was replaced by terminal programs or removed. These two remain because
there is no toolkit-free equivalent of the same quality:

- **Terminal: Ghostty (GTK4).** Alternative: [foot](https://codeberg.org/dnkl/foot), Wayland-native
  with no toolkit (in nixpkgs, Stylix has a target for it). It supports Sixel images but not the
  kitty graphics protocol, so Yazi's image previews would be lower quality. Changing it means
  replacing `ghostty` in `home/session.nix`, `home/hyprland.nix`, `home/bar.nix`, and the
  `--class=tui.<name>` launches (`foot --app-id=tui.<name>`). *Default: keep Ghostty.*
- **Browser: LibreWolf (GTK3).** Every full browser on Linux is GTK (Firefox family, Chromium
  family) or Qt (qutebrowser, Falkon). *Default: keep LibreWolf.*

## Graphical password prompt (polkit agent)

hyprpolkitagent (Qt) was removed, and every alternative in nixpkgs is GTK or Qt
(polkit_gnome, soteria, cmd-polkit, lxqt-policykit). Without one, an app that needs an
administrator password and has no terminal fails with "not authorized" instead of asking. Nothing
in the current setup needs it (see README). *Default: no agent; if one is ever needed,
hyprpolkitagent is one line in `home/session.nix`.*

## Alt-tab

hyprshell (GTK4) was replaced by Hyprland's own `cycle_next`: it steps through the windows of the
current workspace in order, with no previews and no most-recently-used order. *Default: built-in
cycling.*

## Screenshot editor

satty (GTK4) was removed with its `SUPER+Print` key; the other screenshot keys are unchanged.
The toolkit-free editors in nixpkgs are not as good. *Default: no editor.*
