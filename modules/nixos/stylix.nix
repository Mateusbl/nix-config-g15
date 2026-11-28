# System-wide theme (Stylix). Neovim, Ghostty, Waybar, mako, GTK, Hyprland borders, the ctOS
# login/lock screen, ... all take their colours and fonts from here, so changing it here
# re-themes everything. The shapes follow the ctOS login screen too: square corners everywhere
# (Hyprland, mako, the Hypr tools, GTK in home/session.nix).
{ pkgs, ... }:

let
  # ctOS / Watch Dogs: pure black, neutral greys and white for text, and Watch Dogs' electric
  # cyan-blue as the highlight colour (base0D, the accent everything uses: active window border,
  # selected items, the login screen's blocks). Red and green are ctOS' own (errors, success /
  # strings). Text and accent colours (base04 to base0F) reach at least 5.9:1 contrast on black,
  # so they stay readable on the 0.85-opaque terminal; comments (base03) are deliberately dimmer,
  # at 3.3:1. Selections (base02) are a dark blue-grey, with text on them at 10.7:1.
  palette = {
    base00 = "000000"; # Background: pure black
    base01 = "0d0d0d"; # Lighter background (status bars, popups)
    base02 = "1a2a33"; # Selection background, a dark blue-grey
    base03 = "5a6066"; # Comments / invisibles
    base04 = "8a9095"; # Dark foreground
    base05 = "d9dcde"; # Default foreground (ctOS' light grey)
    base06 = "eceeef"; # Light foreground
    base07 = "ffffff"; # Light background, white
    base08 = "fc3e38"; # Red (errors), ctOS red
    base09 = "ff9d4a"; # Orange
    base0A = "ffd84a"; # Yellow (warnings)
    base0B = "1bfd9c"; # Green (strings, success), ctOS green
    base0C = "00e5ff"; # Cyan, Watch Dogs cyan
    base0D = "00b4ff"; # Blue (primary accent / highlights), Watch Dogs blue
    base0E = "8f8aff"; # Purple (keywords)
    base0F = "2fd6c6"; # Teal
  };

  # The original wallpaper is neutral grey on black (with an alpha channel, dropped first). Its greys
  # are stretched to the full range, dimmed (the 150% level keeps the logo subtle behind the
  # translucent terminal) and remapped from black (base00) up to base03, so it follows the palette.
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

    # Icons for the launcher, the tray and notifications. Without an icon theme they fall back to
    # whatever generic icons happen to be installed. Papirus' folders are blue, which suits the
    # palette.
    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus-Light";
    };

    # One mouse cursor everywhere (Hyprland, Ghostty, LibreWolf, XWayland apps): light, so it stays visible on
    # the black background.
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

    # One typeface everywhere: JetBrains Mono, the font the ctOS login screen is designed around.
    # The terminal and editor use its fixed-width "Mono" cut, everything else (bar, notifications,
    # launcher, GTK) the regular cut, so the whole desktop reads like the login screen. Both are
    # Nerd Fonts, so icons work everywhere.
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sizes = {
        applications = 11;
        terminal = 12;
      };
    };
  };
}
