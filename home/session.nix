# Desktop session pieces: wallpaper, default apps, terminal, launcher, clipboard, media keys,
# browser, file dialogs. The lock screen and idle behaviour are in lock-idle.nix, the bar in
# bar.nix.
#
# No GTK or Qt apps beyond the terminal and the browser: small tools (mixer, Bluetooth, file
# dialogs, text editor, PDF viewer) are terminal programs opened in a Ghostty window. The mixer, Bluetooth
# and file-dialog windows get an app id starting with `tui.` (`ghostty --class=tui.<name>`), so
# one rule in hyprland.nix floats them all.
{ config, pkgs, ... }:

{
  # Session services: systemd user services started with the graphical session
  # (hyprland-session.target, see home/hyprland.nix). Stylix themes them. Notifications and the
  # volume/brightness overlay are ashell's (bar.nix), so there is no separate notification daemon.
  # Password prompts for apps that need administrator rights. hyprpolkitagent is drawn with
  # hyprtoolkit, Hyprland's own small toolkit (no GTK, no Qt), like Hyprland's portal.
  services.hyprpolkitagent.enable = true;
  services.hyprpaper.enable = true; # draws the Stylix wallpaper

  # Default apps: Yazi for folders, Neovim for plain text, tdf for PDFs, each in a Ghostty window.
  # They are terminal programs, so "open folder" / "open file" requests from other apps (a
  # browser's "show in folder") need a desktop entry that starts them inside a terminal.
  xdg.desktopEntries.yazi-ghostty = {
    name = "Yazi";
    genericName = "File Manager";
    icon = "system-file-manager";
    exec = "ghostty -e yazi %f";
    mimeType = [ "inode/directory" ];
    categories = [
      "System"
      "FileManager"
    ];
  };
  xdg.desktopEntries.tdf-ghostty = {
    name = "tdf";
    genericName = "PDF Viewer";
    icon = "application-pdf";
    exec = "ghostty -e tdf %f";
    mimeType = [ "application/pdf" ];
    categories = [
      "Office"
      "Viewer"
    ];
  };
  xdg.desktopEntries.nvim-ghostty = {
    name = "Neovim";
    genericName = "Text Editor";
    icon = "nvim";
    exec = "ghostty -e nvim %F";
    mimeType = [ "text/plain" ];
    categories = [
      "Utility"
      "TextEditor"
    ];
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "yazi-ghostty.desktop";
      "text/plain" = "nvim-ghostty.desktop";
    };
  };

  # Ghostty (font size comes from stylix.fonts.sizes.terminal)
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      window-padding-x = 8;
      window-padding-y = 8;
      confirm-close-surface = false;
      cursor-style = "block";
      cursor-style-blink = false;
      mouse-hide-while-typing = true;
    };
  };

  # Launcher: fuzzel. Wayland-native, starts instantly, and remembers what you launch most.
  # Stylix sets its colours and font; icons come from the icon theme in modules/nixos/stylix.nix.
  # It is also the menu behind power-menu and clipboard-pick (home/desktop-scripts.nix).
  programs.fuzzel = {
    enable = true;
    settings.main = {
      terminal = "ghostty -e"; # for entries that need a terminal (btop, yazi, ...)
      layer = "overlay"; # also shown above fullscreen windows
      lines = 12;
      width = 40;
    };
    settings.border.radius = 8;
  };

  # Clipboard history: a wl-paste watcher (systemd user service, started with the graphical
  # session like hyprpaper/ashell). SUPER+SHIFT+V picks from it (clipboard-pick).
  services.cliphist.enable = true;

  # Media keys: playerctl talks to any MPRIS player (mpv, LibreWolf, Spotify, ...).
  # playerctld remembers the player you used last, so the keys go to that one.
  services.playerctld.enable = true;

  # Browser: LibreWolf, Firefox with privacy and security settings on by default (tracking
  # protection, no telemetry, uBlock Origin included). By default it deletes cookies and history
  # when it closes, so you are logged out of sites after a restart; change that in its Settings →
  # Privacy & Security if you prefer. Stylix themes it like it did Firefox.
  programs.librewolf = {
    enable = true;
    # Open/save dialogs through the portal (Yazi, see below) instead of GTK's own dialog.
    settings."widget.use-xdg-desktop-portal.file-picker" = 1;
  };
  stylix.targets.librewolf.profileNames = [ "default" ];

  # Open/save dialogs: xdg-desktop-portal-termfilechooser (modules/nixos/desktop.nix) opens Yazi
  # in a floating Ghostty window. Pick a file with Enter (several: select with Space first), or
  # for "save", move to the folder and edit the suggested name in the file it shows, then quit.
  # `q` without choosing cancels.
  xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
    [filechooser]
    cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
    default_dir=${config.home.homeDirectory}
    env=TERMCMD=ghostty --class=tui.filechooser -e
  '';

  # Stylix's Qt theme is off: no Qt programs are installed (same switch in modules/nixos/stylix.nix).
  stylix.targets.qt.enable = false;

  # Stylix themes every program it knows by default, including ones that are not installed. Its
  # rofi theme sets an option home-manager has renamed, which only produces a warning, so it is
  # off (rofi is not used; fuzzel is the launcher).
  stylix.targets.rofi.enable = false;

  home.packages = with pkgs; [
    brightnessctl
    playerctl
    # Volume mixer made for PipeWire: outputs, inputs and per-app volume. Right-click the speaker
    # in the bar's settings panel.
    wiremix
    # Bluetooth: scan, pair, connect, trust. Right-click the panel's Bluetooth button.
    bluetui
    wl-clipboard
    grim
    slurp
  ];
}
