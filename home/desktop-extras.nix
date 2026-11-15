# Optional desktop extras, all off by default. Turn one on in home/default.nix, e.g.
#   my.desktop.nightLight.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.desktop;

  # Hyprland key binding in the Lua config format used by home/hyprland.nix.
  bind = key: lua: {
    _args = [
      key
      (lib.generators.mkLuaInline lua)
    ];
  };

  # Start/stop screen recording of a region. wf-recorder captures through the compositor
  # (Hyprland renders on the Intel iGPU, which drives the panel), and encodes with the CPU
  # (libx264) by default: that works regardless of the NVIDIA PRIME offload setup, which
  # GPU encoders (gpu-screen-recorder with NVENC) would have to be configured for.
  screen-record = pkgs.writeShellApplication {
    name = "screen-record";
    runtimeInputs = with pkgs; [
      wf-recorder
      slurp
      libnotify
      procps
      coreutils
    ];
    text = ''
      if pgrep -x wf-recorder >/dev/null; then
        pkill -INT -x wf-recorder # INT lets it finish the file properly
        notify-send "Recording stopped"
        exit 0
      fi
      dir=${config.xdg.userDirs.videos}/Recordings
      mkdir -p "$dir"
      area=$(slurp) || exit 0
      file="$dir/$(date +%Y-%m-%d_%H-%M-%S).mp4"
      notify-send "Recording" "SUPER+SHIFT+R again to stop"
      wf-recorder -g "$area" -f "$file"
      notify-send "Recording saved" "$file"
    '';
  };

  # The laptop panel as configured in home/hyprland.nix (output, position, scale, normal mode).
  panel = lib.findFirst (
    m: m.output == "eDP-1"
  ) null config.wayland.windowManager.hyprland.settings.monitor;

  # Lua snippet that sets the panel to a given mode; sent to the running Hyprland with
  # `hyprctl eval`. Everything except the mode is taken from the normal monitor entry.
  setPanel =
    mode:
    ''hl.monitor({ output = "${panel.output}", mode = "${mode}", position = "${panel.position}", scale = ${toString panel.scale} })'';

  # Follows the charger: the normal mode on AC, cfg.batteryRefreshRate.mode on battery.
  # udevadm prints one line per power-supply event; several arrive per plug/unplug, so the mode is
  # only changed when the state really changed.
  battery-refresh-rate = pkgs.writeShellApplication {
    name = "battery-refresh-rate";
    runtimeInputs = with pkgs; [
      systemd # udevadm
      coreutils
      hyprland # hyprctl (same build as the system's programs.hyprland)
    ];
    text = ''
      on_ac() {
        local supply
        for supply in /sys/class/power_supply/*; do
          if [ "$(cat "$supply/type" 2>/dev/null)" = "Mains" ] && [ "$(cat "$supply/online" 2>/dev/null)" = "1" ]; then
            return 0
          fi
        done
        return 1
      }

      last=""
      apply() {
        local state
        if on_ac; then state=ac; else state=battery; fi
        if [ "$state" = "$last" ]; then return; fi
        last=$state
        if [ "$state" = ac ]; then
          hyprctl eval '${setPanel panel.mode}'
        else
          hyprctl eval '${setPanel cfg.batteryRefreshRate.mode}'
        fi
      }

      apply
      udevadm monitor --udev --subsystem-match=power_supply | while read -r _; do
        apply
      done
    '';
  };
in
{
  options.my.desktop = {
    batteryRefreshRate = {
      enable = lib.mkEnableOption "a lower refresh rate for the laptop panel while on battery";
      mode = lib.mkOption {
        type = lib.types.str;
        default = "1920x1080@60";
        description = "Hyprland mode for the laptop panel (eDP-1) on battery; on AC the mode from home/hyprland.nix is used.";
      };
    };
    nightLight.enable = lib.mkEnableOption "hyprsunset: warmer screen colours in the evening";
    colorPicker.enable = lib.mkEnableOption "hyprpicker on SUPER+SHIFT+C (copies the colour)";
    screenRecorder.enable = lib.mkEnableOption "wf-recorder on SUPER+SHIFT+R (region, start/stop)";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.batteryRefreshRate.enable {
      assertions = [
        {
          assertion = panel != null;
          message = "my.desktop.batteryRefreshRate needs an eDP-1 entry in wayland.windowManager.hyprland.settings.monitor.";
        }
      ];
      # A session service like the others (started and stopped with the graphical session).
      systemd.user.services.battery-refresh-rate = {
        Unit = {
          Description = "Lower the laptop panel's refresh rate on battery";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = lib.getExe battery-refresh-rate;
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    })

    (lib.mkIf cfg.nightLight.enable {
      services.hyprsunset = {
        enable = true;
        settings.profile = [
          {
            time = "7:00";
            identity = true; # daytime: no change
          }
          {
            time = "20:00";
            temperature = 4500;
          }
        ];
      };
    })

    (lib.mkIf cfg.colorPicker.enable {
      home.packages = [ pkgs.hyprpicker ];
      wayland.windowManager.hyprland.settings.bind = [
        (bind "SUPER + SHIFT + C" ''hl.dsp.exec_cmd("hyprpicker --autocopy")'')
      ];
    })

    (lib.mkIf cfg.screenRecorder.enable {
      home.packages = [ screen-record ];
      wayland.windowManager.hyprland.settings.bind = [
        (bind "SUPER + SHIFT + R" ''hl.dsp.exec_cmd("screen-record")'')
      ];
    })
  ];
}
