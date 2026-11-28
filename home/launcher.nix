# Launcher and the look of the Hypr tools.
#
# hyprlauncher (SUPER+D): apps, plus emoji (type `.` first), maths (`=`) and fonts (`'`).
# It runs as a daemon, so it opens instantly, and it is also the menu behind the power menu,
# the clipboard picker and the window picker (desktop-scripts.nix): those send it a list and
# read back the choice, which only works while the daemon runs.
#
# hyprtoolkit is the toolkit of every Hypr app here: hyprlauncher, hyprpwcenter (mixer),
# hyprpolkitagent (password prompts), hyprshutdown, hyprsysteminfo and Hyprland's own portal
# and dialogs. Stylix has no target for it, so its colours and fonts are set from the palette.
{ config, ... }:

let
  c = config.lib.stylix.colors;
  argb = hex: "0xFF${hex}"; # hyprtoolkit takes colours as 0xAARRGGBB
in
{
  services.hyprlauncher = {
    enable = true; # a session service
    settings = {
      general.grab_focus = true;
      cache.enabled = true; # often launched apps first
      ui.window_size = "500 340";
      finders = {
        desktop_icons = true;
        desktop_terminal = "ghostty -e"; # for entries that need a terminal (btop, yazi, ...)
      };
    };
  };

  programs.hyprtoolkit = {
    enable = true;
    settings = {
      background = argb c.base00;
      base = argb c.base01;
      alternate_base = argb c.base02;
      text = argb c.base05;
      bright_text = argb c.base07;
      link_text = argb c.base0C;
      accent = argb c.base0D;
      accent_secondary = argb c.base0E;
      font_family = config.stylix.fonts.sansSerif.name;
      font_family_monospace = config.stylix.fonts.monospace.name;
      font_size = config.stylix.fonts.sizes.applications;
      icon_theme = config.stylix.icons.dark;
      # Square, like the rest of the desktop (modules/nixos/stylix.nix).
      rounding_large = 0;
      rounding_small = 0;
    };
  };
}
