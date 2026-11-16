# Small desktop helpers bound to keys in home/hyprland.nix.
# writeShellApplication: strict bash, explicit dependencies, shellcheck at build time.
{ config, pkgs, ... }:

let
  screenshotsDir = config.xdg.userDirs.extraConfig.SCREENSHOTS;

  # SUPER+SHIFT+Escape. fuzzel with --only-match: only a listed entry can be chosen, and Escape
  # cancels, so a stray key press can never power the laptop off.
  power-menu = pkgs.writeShellApplication {
    name = "power-menu";
    runtimeInputs = with pkgs; [
      fuzzel
      systemd
      uwsm
    ];
    text = ''
      choice=$(printf '%s\n' lock suspend reboot poweroff logout |
        fuzzel --dmenu --only-match --prompt "Power  ") || exit 0
      case "$choice" in
        lock) loginctl lock-session ;;
        suspend) systemctl suspend ;;
        reboot) systemctl reboot ;;
        poweroff) systemctl poweroff ;;
        logout) uwsm stop ;;
      esac
    '';
  };

  # Shift+Print: region to a file; Ctrl+Print: whole screen to a file. Both notify.
  # (Plain Print, region to clipboard, stays a one-liner in hyprland.nix.)
  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = with pkgs; [
      grim
      slurp
      libnotify
      coreutils
    ];
    text = ''
      dir=${screenshotsDir}
      mkdir -p "$dir"
      file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
      case "''${1:-}" in
        region)
          area=$(slurp) || exit 0 # Escape while selecting cancels
          grim -g "$area" "$file"
          ;;
        full) grim "$file" ;;
        *)
          echo "usage: screenshot region|full" >&2
          exit 1
          ;;
      esac
      notify-send -i "$file" "Screenshot saved" "$file"
    '';
  };

  # SUPER+SHIFT+V: pick an entry from the clipboard history and copy it again.
  clipboard-pick = pkgs.writeShellApplication {
    name = "clipboard-pick";
    runtimeInputs = with pkgs; [
      cliphist
      fuzzel
      wl-clipboard
    ];
    text = ''
      entry=$(cliphist list | fuzzel --dmenu --only-match --width 80 --prompt "Clipboard  ") || exit 0
      printf '%s' "$entry" | cliphist decode | wl-copy
    '';
  };

  # Volume / brightness keys: change the value, then show it. The notification replaces itself
  # (the "synchronous" hint) and carries the value, which mako draws as a progress bar in the
  # Stylix colours. No extra OSD daemon needed.
  osd = pkgs.writeShellApplication {
    name = "osd";
    runtimeInputs = with pkgs; [
      wireplumber # wpctl
      brightnessctl
      libnotify
      gawk
      coreutils
    ];
    text = ''
      show() { # show <title> <percent>
        local bar=$2
        if [ "$bar" -gt 100 ]; then bar=100; fi
        notify-send -a osd -t 1200 \
          -h string:x-canonical-private-synchronous:osd -h "int:value:$bar" "$1" "$2%"
      }

      # "Volume: 0.45" or "Volume: 0.45 [MUTED]" -> title + percent
      show_audio() { # show_audio <wpctl target> <label>
        local state percent
        state=$(wpctl get-volume "$1")
        percent=$(awk '{ printf "%d", $2 * 100 + 0.5 }' <<<"$state")
        case "$state" in
          *MUTED*) show "$2 muted" 0 ;;
          *) show "$2" "$percent" ;;
        esac
      }

      case "''${1:-}" in
        volume-up) wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+ ;;
        volume-down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
        volume-mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
        mic-mute) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
        brightness-up) brightnessctl --quiet set 5%+ ;;
        brightness-down) brightnessctl --quiet set 5%- ;;
        *)
          echo "usage: osd volume-up|volume-down|volume-mute|mic-mute|brightness-up|brightness-down" >&2
          exit 1
          ;;
      esac

      case "$1" in
        volume-*) show_audio @DEFAULT_AUDIO_SINK@ "Volume" ;;
        mic-mute) show_audio @DEFAULT_AUDIO_SOURCE@ "Microphone" ;;
        brightness-*) show "Brightness" "$(brightnessctl --machine-readable | cut -d, -f4 | tr -d '%')" ;;
      esac
    '';
  };
in
{
  home.packages = [
    power-menu
    screenshot
    clipboard-pick
    osd
  ];

  # XDG user directories (Pictures, Downloads, ...), created on activation, plus a
  # Screenshots folder (XDG_SCREENSHOTS_DIR) for the screenshot script.
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    extraConfig.SCREENSHOTS = "${config.home.homeDirectory}/Pictures/Screenshots";
  };
}
