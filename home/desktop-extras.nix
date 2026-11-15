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
in
{
  options.my.desktop = {
    nightLight.enable = lib.mkEnableOption "hyprsunset: warmer screen colours in the evening";
    colorPicker.enable = lib.mkEnableOption "hyprpicker on SUPER+SHIFT+C (copies the colour)";
    screenRecorder.enable = lib.mkEnableOption "wf-recorder on SUPER+SHIFT+R (region, start/stop)";
  };

  config = lib.mkMerge [
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
