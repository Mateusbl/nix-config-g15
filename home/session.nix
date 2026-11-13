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
          "battery"
        ];
        clock.format = "{:%Y-%m-%d %H:%M}";
        battery = {
          format = "BAT {capacity}%";
          format-charging = "CHG {capacity}%";
          format-full = "BAT {capacity}%";
        };
      };
    };
  };

  programs.firefox.enable = true;
  stylix.targets.firefox.profileNames = [ "default" ];

  home.packages = with pkgs; [
    mousepad
    brightnessctl
    wl-clipboard
    grim
    slurp
  ];
}
