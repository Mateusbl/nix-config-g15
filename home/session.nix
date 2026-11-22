# Desktop session pieces: notifications, lock/idle, bar, launcher, terminal, browser.
{ lib, pkgs, ... }:

{
  # Session services (UWSM-compatible, Stylix themes them)
  services.mako.enable = true; # notifications
  services.hyprpolkitagent.enable = true; # privilege prompts for GUI apps
  services.hyprpaper.enable = true; # draws the Stylix wallpaper

  programs.hyprlock = {
    enable = true;
    settings.label = [
      # clock
      {
        text = "$TIME12";
        font_size = 90;
        font_family = "FiraCode Nerd Font Mono";
        color = "rgb(c9d8f7)";
        position = "0, 220";
        halign = "center";
        valign = "center";
      }
      #Date
      {
        text = ''cmd[update:6000] date +"%A, %d %B"'';
        font_size = 22;
        font_family = "DejaVu Sans";
        color = "rgb(7d93c6)";
        position = "0, 120";
        halign = "center";
        valign = "center";
      }
      #Greeting
      {
        text = "Hi, $USER";
        font_size = 18;
        font_family = "DejaVu Sans";
        color = "rgb(6f9cf5)";
        position = "0, -110";
        halign = "center";
        valign = "center";
      }
      #Battery
      {
        text = ''cmd[update:30000] echo "$(cat /sys/class/power_supply/BAT0/capacity)%"'';
        font_size = 14;
        font_family = "DejaVu Sans";
        color = "rgb(c9d8f7)";
        position = "-20, -20";
        halign = "right";
        valign = "Top";
      }
    ];
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "${pkgs.writeShellScript "hypr-lock" "${pkgs.procps}/bin/pgrep -x hyprlock || exec ${pkgs.hyprlock}/bin/hyprlock"}";
        before_sleep_cmd = "loginctl lock-session";
        # Was misspelled "aftet_sleep_cmd", so hypridle ignored it.
        after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\"})'";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "brightnessctl -s set 10%";
          on-resume = "brightnessctl -r";
        }
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 660;
          on-timeout = "hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'";
          on-resume = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'";
        }
        {
          timeout = 1800;
          on-timeout = "systemctl suspend-then-hibernate";
        }
      ];
    };
  };

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
  # Stylix themes rofi by default even though it is not installed, which only produces an
  # evaluation warning about a renamed rofi option.
  stylix.targets.rofi.enable = false;

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

  # Bar: ashell. One program made for Hyprland: workspaces, window title, clock, tray, and a
  # settings panel (click the icons on the right) for volume, Wi-Fi, Bluetooth, brightness,
  # power profile and power actions. Stylix sets its colours (stylix.targets.ashell).
  programs.ashell = {
    enable = true;
    systemd.enable = true; # a session service, like mako and hyprpaper
    settings = {
      position = "Top";
      modules = {
        left = [ "Workspaces" ];
        center = [ "WindowTitle" ];
        # Inner lists are drawn as one group.
        right = [
          "SystemInfo"
          "Tray" # icons of apps that keep running in the background
          [
            "Tempo"
            "Privacy" # shows when the microphone, camera or screen sharing is in use
            "Settings"
          ]
        ];
      };

      # Tempo is the clock; clicking it opens a calendar. No weather: that would ask a web
      # service for the location.
      tempo.clock_format = "%Y-%m-%d %H:%M";

      system_info.indicators = [
        "Cpu"
        "Memory"
        "Temperature"
      ];

      settings = {
        battery_format = "IconAndPercentage";
        # Same commands as power-menu, so both behave alike under UWSM.
        lock_cmd = "loginctl lock-session";
        suspend_cmd = "systemctl suspend";
        hibernate_cmd = "systemctl hibernate";
        reboot_cmd = "systemctl reboot";
        shutdown_cmd = "systemctl poweroff";
        logout_cmd = "uwsm stop";
        # Right-click the speaker / Bluetooth button for the full tools.
        audio_sinks_more_cmd = "pavucontrol -t 3";
        audio_sources_more_cmd = "pavucontrol -t 4";
        bluetooth_more_cmd = "blueman-manager";
      };
    };
  };

  # Clipboard history: a wl-paste watcher (systemd user service, started with the graphical
  # session like mako/hyprpaper/ashell). SUPER+SHIFT+V picks from it (clipboard-pick).
  services.cliphist.enable = true;

  # Media keys: playerctl talks to any MPRIS player (mpv, Firefox, Spotify, ...).
  # playerctld remembers the player you used last, so the keys go to that one.
  services.playerctld.enable = true;

  programs.firefox.enable = true;
  stylix.targets.firefox.profileNames = [ "default" ];
  stylix.targets.wayprompt.enable = false;
  home.packages = with pkgs; [
    mousepad
    brightnessctl
    playerctl
    # Volume mixer. pavucontrol rather than wiremix: it is mature, is opened by right-clicking the
    # speaker in the bar's settings panel, and is a GTK app that Stylix themes. wiremix (a TUI) works too,
    # but mixing per-app volumes is quicker with a mouse.
    pavucontrol
    wl-clipboard
    grim
    slurp
  ];
}
