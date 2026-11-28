# System-wide theme (Stylix). Neovim, Ghostty, ashell, fuzzel, GTK, Hyprland borders, ... all take
# their colours from the palette below, so changing it here re-themes everything.
{ pkgs, ... }:

let
  # A blue-leaning base16 palette on a deep navy background. Text and accent colours
  # (base04 to base0F) reach at least 5:1 contrast on base00, so they stay readable on the
  # 0.85-opaque terminal; comments (base03) are deliberately dimmer, at 3:1. The accents keep
  # their usual roles (red errors, yellow warnings, green strings) but are softened and pulled
  # toward blue so nothing clashes.
  palette = {
    base00 = "0a1224"; # Deep navy background
    base01 = "111d38"; # Lighter background (status bars, popups)
    base02 = "1c2c52"; # Selection background
    base03 = "4a5f94"; # Comments / invisibles
    base04 = "7d93c6"; # Dark foreground
    base05 = "c9d8f7"; # Default foreground
    base06 = "dce7fc"; # Light foreground
    base07 = "eff4ff"; # Light background
    base08 = "f2788f"; # Red (errors), rose
    base09 = "eba377"; # Orange, peach
    base0A = "e8cf8b"; # Yellow (warnings)
    base0B = "7fd6b4"; # Green (strings), sea green
    base0C = "7ec8f0"; # Cyan -> Nix light blue
    base0D = "6f9cf5"; # Blue (primary accent)
    base0E = "a496f5"; # Purple (keywords), blue-violet
    base0F = "5fcbd8"; # Teal
  };

  # The original wallpaper is neutral grey on black (with an alpha channel, dropped first). Its greys
  # are stretched to the full range, dimmed (the 150% level keeps the logo subtle behind the
  # translucent terminal) and remapped from navy (base00) up to base03, so it follows the palette.
  # Built once at build time; no extra binary in git.
  wallpaper = pkgs.runCommand "nix-bg-blue.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    magick ${../../assets/nix-bg.png} -alpha off -colorspace Gray -auto-level -level 0%,150% \
      +level-colors "#${palette.base00},#${palette.base03}" $out
  '';
in
{
  stylix = {
    enable = true;
    polarity = "dark";
    image = wallpaper;
    base16Scheme = palette;

    # No Qt programs are installed, so no Qt theme (it would pull in qt5ct, qt6ct and Kvantum).
    # The same switch for home-manager is in home/session.nix.
    targets.qt.enable = false;

    # Icons for fuzzel, the tray and the bar. Without an icon theme they fall back to
    # whatever generic icons happen to be installed. Papirus' folders are blue, which suits the
    # palette.
    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus-Light";
    };

    # One mouse cursor everywhere (Hyprland, Ghostty, LibreWolf, XWayland apps): light, so it stays visible on
    # the navy background.
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };

    # Make the terminal slightly transparent to see the wallpaper
    opacity = {
      terminal = 0.85;
      popups = 0.95;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.fira-code;
        name = "FiraCode Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      sizes = {
        applications = 11;
        terminal = 12;
      };
    };
  };
}
