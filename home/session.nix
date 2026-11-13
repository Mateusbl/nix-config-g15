# Desktop session pieces: notifications, lock/idle, bar, launcher, terminal, browser.
{ pkgs, ... }:

{
  # Session services (UWSM-compatible, Stylix themes them)
  services.mako.enable = true; # notifications
  services.hyprpolkitagent.enable = true; # privilege prompts for GUI apps
  services.hyprpaper.enable = true; # draws the Stylix wallpaper

  programs.hyprlock.enable = true;

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

  # Default apps: Thunar for folders, Mousepad for plain text.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "thunar.desktop";
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

  # Rofi (Wayland support is in the main package now; Stylix themes it)
  programs.rofi.enable = true;

  # Waybar (text labels on purpose, no Nerd Font glyphs needed)
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "power-profiles-daemon" # click to cycle power-saver / balanced / performance
          "battery"
          "tray" # icons of apps that live in the background (nm-applet, blueman, ...)
        ];
        clock.format = "{:%Y-%m-%d %H:%M}";
        pulseaudio = {
          format = "VOL {volume}%";
          format-muted = "MUTED";
          on-click = "pavucontrol"; # mixer: per-app volume, outputs, inputs
        };
        tray.spacing = 8;
        power-profiles-daemon = {
          format = "PWR {profile}";
          tooltip-format = "Power profile: {profile}\nCPU driver: {cpu_driver}";
        };
        battery = {
          # The state names match UPower's thresholds (modules/nixos/power-sleep.nix).
          states = {
            warning = 20;
            critical = 10;
          };
          format-warning = "LOW {capacity}%";
          format-critical = "CRIT {capacity}%";
          format = "BAT {capacity}%";
          format-charging = "CHG {capacity}%";
          format-full = "BAT {capacity}%";
        };
      };
    };
  };

  # Clipboard history: a wl-paste watcher (systemd user service, started with the graphical
  # session like mako/hyprpaper/waybar). SUPER+SHIFT+V picks from it (clipboard-pick).
  services.cliphist.enable = true;

  # Media keys: playerctl talks to any MPRIS player (mpv, Firefox, Spotify, ...).
  # playerctld remembers the player you used last, so the keys go to that one.
  services.playerctld.enable = true;

  programs.firefox.enable = true;
  stylix.targets.firefox.profileNames = [ "default" ];

  home.packages = with pkgs; [
    mousepad
    brightnessctl
    playerctl
    # Volume mixer. pavucontrol rather than wiremix: it is mature, is opened by clicking the
    # Waybar volume module, and is a GTK app that Stylix themes. wiremix (a TUI) works too,
    # but mixing per-app volumes is quicker with a mouse.
    pavucontrol
    wl-clipboard
    grim
    slurp
  ];
}
