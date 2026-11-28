# The bar (Waybar) and notifications (mako).
#
# Waybar is GTK3, an allowed exception (CLAUDE.md): it is the owner's choice of bar. Everything
# it opens is a Hypr tool or a terminal program:
#   speaker      hyprpwcenter (PipeWire control center)  right-click: mute
#   Wi-Fi        nmtui in a floating Ghostty window
#   Bluetooth    bluetui in a floating Ghostty window
#   power        power-menu (desktop-scripts.nix)
#   bell         do not disturb on/off                    right-click: show the last notification again
# Labels are plain text (VOL, NET, ...): Waybar's font is the sans-serif one, which has no
# Nerd Font icons. Stylix sets the colours and fonts of both (stylix.targets.waybar / .mako).
{ lib, pkgs, ... }:

let
  # Opens a terminal program in a floating window (`tui.` windows float, home/hyprland.nix).
  tui = name: command: "ghostty --class=tui.${name} -e ${command}";

  # The bell: "DND" while do not disturb is on, empty otherwise. Waybar re-runs it when it
  # receives signal 8 (sent after every toggle), so it follows the state at once.
  dnd-status = pkgs.writeShellScript "dnd-status" ''
    if ${pkgs.mako}/bin/makoctl mode | ${pkgs.gnugrep}/bin/grep -q do-not-disturb; then
      echo "DND"
    else
      echo "BELL"
    fi
  '';
  dnd-toggle = pkgs.writeShellScript "dnd-toggle" ''
    ${pkgs.mako}/bin/makoctl mode -t do-not-disturb >/dev/null
    ${pkgs.procps}/bin/pkill -RTMIN+8 waybar
  '';
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true; # a session service, started and stopped with Hyprland
    # Extra colours for states, on top of Stylix's stylesheet. @base0X are the palette colours
    # Stylix defines for Waybar, so these follow the theme (mkAfter: must come after them).
    style = lib.mkAfter ''
      #battery.warning:not(.charging) { color: @base0A; }
      #battery.critical:not(.charging) { color: @base08; }
      #power-profiles-daemon.power-saver { color: @base0B; }
      #power-profiles-daemon.performance { color: @base09; }
      #pulseaudio.muted, #bluetooth.off, #network.disconnected { color: @base03; }
    '';
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 30;
      spacing = 12;
      modules-left = [
        "hyprland/workspaces"
        "hyprland/window"
      ];
      modules-center = [ "clock" ];
      modules-right = [
        "cpu"
        "memory"
        "temperature"
        "pulseaudio"
        "backlight"
        "network"
        "bluetooth"
        "power-profiles-daemon" # click to cycle power-saver / balanced / performance
        "battery"
        "tray" # icons of apps that keep running in the background
        "custom/dnd"
        "custom/power"
      ];

      "hyprland/window".max-length = 60;

      clock = {
        format = "{:%Y-%m-%d %H:%M}";
        tooltip-format = "<tt>{calendar}</tt>"; # hover for a calendar
      };

      cpu.format = "CPU {usage}%";
      memory.format = "MEM {percentage}%";
      temperature = {
        format = "TEMP {temperatureC}°C";
        critical-threshold = 90;
      };

      pulseaudio = {
        format = "VOL {volume}%";
        format-muted = "MUTED";
        max-volume = 150; # same limit as the volume keys (osd in desktop-scripts.nix)
        scroll-step = 5;
        on-click = "hyprpwcenter";
        on-click-right = "osd volume-mute";
      };

      backlight = {
        format = "BRI {percent}%";
        on-scroll-up = "osd brightness-up";
        on-scroll-down = "osd brightness-down";
      };

      network = {
        format-wifi = "NET {essid}";
        format-ethernet = "NET wired";
        format-disconnected = "NET off";
        tooltip-format-wifi = "{essid} ({signalStrength}%)\n{ipaddr}";
        on-click = tui "network" "nmtui";
      };

      bluetooth = {
        format = "BT";
        format-off = "BT off";
        format-connected = "BT {device_alias}";
        tooltip-format-connected = "{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}";
        on-click = tui "bluetooth" "bluetui";
      };

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
        format = "BAT {capacity}%";
        format-charging = "CHG {capacity}%";
        format-warning = "LOW {capacity}%";
        format-critical = "CRIT {capacity}%";
      };

      tray.spacing = 8;

      "custom/dnd" = {
        exec = "${dnd-status}";
        interval = "once";
        signal = 8;
        tooltip = false;
        on-click = "${dnd-toggle}";
        on-click-right = "makoctl restore";
      };

      "custom/power" = {
        format = "POWER";
        tooltip = false;
        on-click = "power-menu";
      };
    };
  };

  # Notifications: mako, popups in the top-right corner. `makoctl restore` (right-click the
  # bell) brings back the last one you dismissed. In do not disturb mode nothing is shown,
  # except critical ones (low battery).
  services.mako = {
    enable = true;
    settings = {
      anchor = "top-right";
      default-timeout = 5000; # milliseconds
      max-history = 20;
      border-radius = 8;
      "mode=do-not-disturb".invisible = 1;
      "mode=do-not-disturb urgency=critical".invisible = 0;
      # The volume/brightness overlay (osd, desktop-scripts.nix): short and centred at the bottom.
      "app-name=osd" = {
        anchor = "bottom-center";
        default-timeout = 1500;
      };
    };
  };
}
