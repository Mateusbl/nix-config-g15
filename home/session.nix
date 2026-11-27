# Desktop session pieces: polkit agent, wallpaper, default apps, terminal, launcher, clipboard,
# media keys, browser. The lock screen and idle behaviour are in lock-idle.nix, the bar in bar.nix.
{ pkgs, ... }:

{
  # Session services: systemd user services started with the graphical session
  # (hyprland-session.target, see home/hyprland.nix). Stylix themes them. Notifications and the
  # volume/brightness overlay are ashell's (bar.nix), so there is no separate notification daemon.
  services.hyprpolkitagent.enable = true; # privilege prompts for GUI apps
  services.hyprpaper.enable = true; # draws the Stylix wallpaper

  # Default apps: Yazi (in a Ghostty window) for folders, Mousepad for plain text.
  # Yazi is a terminal program, so "open folder" requests from other apps (a browser's
  # "show in folder") need a desktop entry that starts it inside a terminal.
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

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "yazi-ghostty.desktop";
      "text/plain" = "org.xfce.mousepad.desktop";
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
  programs.librewolf.enable = true;
  stylix.targets.librewolf.profileNames = [ "default" ];

  # Stylix themes every program it knows by default, including ones that are not installed. These
  # two only produce errors or warnings (rofi: a renamed option; wayprompt: removed from
  # home-manager), so their Stylix themes are off.
  stylix.targets.rofi.enable = false;

  home.packages = with pkgs; [
    mousepad
    brightnessctl
    playerctl
    # Volume mixer: pwvucontrol, made for PipeWire (GTK4). Opened by right-clicking the speaker in
    # the bar's settings panel.
    pwvucontrol
    # Bluetooth pairing and device settings (GTK4). Right-click the panel's Bluetooth button.
    overskride
    wl-clipboard
    grim
    slurp
  ];
}
