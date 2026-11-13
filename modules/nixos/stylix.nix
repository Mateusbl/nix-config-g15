{ pkgs, ... }:

{
  # Stylix system-wide theme
  stylix = {
    enable = true;
    polarity = "dark";
    image = ../../assets/nix-bg.png;

    # Custom NixOS-logo color palette
    base16Scheme = {
      base00 = "0f141e"; # Deep background
      base01 = "182030"; # Lighter background (Statusbars)
      base02 = "28344a"; # Selection background
      base03 = "3b4252"; # Comments / Invisibles
      base04 = "4c566a"; # Dark Foreground
      base05 = "d8dee9"; # Default Foreground
      base06 = "e5e9f0"; # Light Foreground
      base07 = "eceff4"; # Light Background
      base08 = "bf616a"; # Red (Errors)
      base09 = "d08770"; # Orange
      base0A = "ebcb8b"; # Yellow (Warnings)
      base0B = "a3be8c"; # Green (Strings)
      base0C = "7EBAE4"; # Cyan -> Nix Light Blue
      base0D = "5277C3"; # Blue -> Nix Dark Blue (Primary Accent)
      base0E = "b48ead"; # Purple (Keywords)
      base0F = "8fbcbb"; # Brown/Teal
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
