# Lock screen and idle behaviour (hypridle). SUPER+L or SUPER+Escape locks; hypridle dims the
# screen after 5 minutes, locks after 10, turns the screen off after 11 and suspends after 30.
#
# The lock screen is ctOS (`ctos-lock`, modules/nixos/ctos-greeter.nix), the same program as the
# login screen. hyprlock below is the fallback, used only when `my.ctosGreeter.enable = false`;
# Stylix sets its background and colours, the labels add the time, date, a greeting and battery.
{ osConfig, pkgs, ... }:

let
  ctos = osConfig.my.ctosGreeter.enable;
  hyprlock = pkgs.writeShellScript "hypr-lock" "${pkgs.procps}/bin/pgrep -x hyprlock || exec ${pkgs.hyprlock}/bin/hyprlock";
in
{
  programs.hyprlock = {
    enable = !ctos;
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
        # ctos-lock comes from the system profile; it never starts a second locker.
        lock_cmd = if ctos then "ctos-lock" else "${hyprlock}";
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
}
