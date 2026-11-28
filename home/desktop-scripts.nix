# Small desktop helpers bound to keys in home/hyprland.nix.
# writeShellApplication: strict bash, explicit dependencies, shellcheck at build time.
{ config, pkgs, ... }:

let
  screenshotsDir = config.xdg.userDirs.extraConfig.SCREENSHOTS;

  # The menu behind the pickers below: hyprlauncher in dmenu mode (home/launcher.nix). It reads
  # the entries from stdin and prints the chosen one; only listed entries can be chosen. Escape
  # makes hyprlauncher print "Exited without selection", which counts as a cancel (exit 1), so a
  # stray key press never runs anything.
  menu = pkgs.writeShellApplication {
    name = "menu";
    runtimeInputs = [ pkgs.hyprlauncher ];
    text = ''
      choice=$(hyprlauncher --quiet --dmenu)
      if [ -z "$choice" ] || [ "$choice" = "Exited without selection" ]; then
        exit 1
      fi
      printf '%s\n' "$choice"
    '';
  };

  # SUPER+SHIFT+Escape, or POWER in the bar. Reboot, power off and log out go through
  # hyprshutdown: it asks every app to close (so they can save) before Hyprland exits.
  power-menu = pkgs.writeShellApplication {
    name = "power-menu";
    runtimeInputs = [
      menu
      pkgs.hyprshutdown
      pkgs.systemd
    ];
    text = ''
      choice=$(printf '%s\n' lock suspend hibernate reboot poweroff logout | menu) || exit 0
      case "$choice" in
        lock) loginctl lock-session ;;
        suspend) systemctl suspend ;;
        hibernate) systemctl hibernate ;;
        reboot) hyprshutdown -t "Restarting..." -p "systemctl reboot" ;;
        poweroff) hyprshutdown -t "Shutting down..." -p "systemctl poweroff" ;;
        logout) hyprshutdown -t "Logging out..." ;;
      esac
    '';
  };

  # Volume, microphone and brightness keys (home/hyprland.nix) and the bar: change the value,
  # then show it as a notification with a bar (mako, "osd" settings in bar.nix). The tag makes
  # each new one replace the last instead of stacking up.
  osd = pkgs.writeShellApplication {
    name = "osd";
    runtimeInputs = with pkgs; [
      wireplumber # wpctl
      brightnessctl
      libnotify
      gawk
      gnugrep
    ];
    text = ''
      show() { # show <icon> <text> <percent>
        notify-send -a osd -i "$1" -h string:x-canonical-private-synchronous:osd \
          -h "int:value:$3" "$2"
      }
      volume() { # volume <device> <name>
        state=$(wpctl get-volume "$1") # "Volume: 0.45" or "Volume: 0.45 [MUTED]"
        percent=$(echo "$state" | awk '{ printf "%d", $2 * 100 + 0.5 }')
        if echo "$state" | grep -q MUTED; then
          show audio-volume-muted "$2 muted" 0
        else
          show audio-volume-high "$2 $percent%" "$percent"
        fi
      }
      brightness() {
        percent=$(( $(brightnessctl get) * 100 / $(brightnessctl max) ))
        show display-brightness "Brightness $percent%" "$percent"
      }
      case "''${1:-}" in
        volume-up) wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+ && volume @DEFAULT_AUDIO_SINK@ Volume ;;
        volume-down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && volume @DEFAULT_AUDIO_SINK@ Volume ;;
        volume-mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && volume @DEFAULT_AUDIO_SINK@ Volume ;;
        mic-mute) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && volume @DEFAULT_AUDIO_SOURCE@ Microphone ;;
        # -n 1%: never all the way to 0, so the panel cannot go fully dark
        brightness-up) brightnessctl -q set 5%+ && brightness ;;
        brightness-down) brightnessctl -q -n 1% set 5%- && brightness ;;
        *)
          echo "usage: osd volume-up|volume-down|volume-mute|mic-mute|brightness-up|brightness-down" >&2
          exit 1
          ;;
      esac
    '';
  };

  # Shift+Print: region to a file; Ctrl+Print: whole screen to a file. Both notify.
  # SUPER+Print (edit): region opened in satty to draw arrows, text or blur; Ctrl+S there saves
  # to the Screenshots folder, Ctrl+C copies, and satty closes after either. satty is GTK4, an
  # allowed exception (CLAUDE.md): drawing needs a window, and GTK4 is already there for Ghostty.
  # (Plain Print, region to clipboard, stays a one-liner in hyprland.nix.)
  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = with pkgs; [
      grim
      slurp
      libnotify
      coreutils
      satty
      wl-clipboard
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
        edit)
          area=$(slurp) || exit 0
          grim -g "$area" - | satty --filename - --output-filename "$file" \
            --copy-command wl-copy --early-exit
          exit 0 # satty shows its own result; no notification here
          ;;
        *)
          echo "usage: screenshot region|full|edit" >&2
          exit 1
          ;;
      esac
      notify-send -i "$file" "Screenshot saved" "$file"
    '';
  };

  # ALT+Tab: pick a window. Windows are listed most recently used first, starting with the one
  # before the current window, so ALT+Tab then Enter jumps back to it. Type to filter, arrows to
  # move, Enter to switch, Escape to cancel. All workspaces are listed.
  window-pick = pkgs.writeShellApplication {
    name = "window-pick";
    runtimeInputs = [
      menu
      pkgs.jq
    ];
    # hyprctl comes with Hyprland (system profile), already on PATH in the session.
    text = ''
      # The menu shows "class: title"; each line is mapped back to the window's address.
      declare -A address
      labels=()
      while IFS=$'\t' read -r addr label; do
        key=$label n=2
        while [ -n "''${address[$key]+set}" ]; do # two windows with the same title
          key="$label ($n)" n=$((n + 1))
        done
        address[$key]=$addr
        labels+=("$key")
      done < <(hyprctl clients -j | jq -r '
        map(select(.mapped)) | sort_by(.focusHistoryID) | (.[1:] + .[:1]) | .[]
        | "\(.address)\t\(.class): \(.title)"')
      [ "''${#labels[@]}" -gt 0 ] || exit 0
      choice=$(printf '%s\n' "''${labels[@]}" | menu) || exit 0
      hyprctl dispatch "hl.dsp.focus({ window = \"address:''${address[$choice]}\" })"
    '';
  };

  # SUPER+SHIFT+V: pick an entry from the clipboard history and copy it again.
  clipboard-pick = pkgs.writeShellApplication {
    name = "clipboard-pick";
    runtimeInputs = with pkgs; [
      menu
      cliphist
      wl-clipboard
    ];
    text = ''
      entry=$(cliphist list | menu) || exit 0
      printf '%s' "$entry" | cliphist decode | wl-copy
    '';
  };
in
{
  # Emoji (SUPER+period) need no script: hyprlauncher's own emoji search (home/hyprland.nix).
  home.packages = [
    menu
    power-menu
    osd
    screenshot
    clipboard-pick
    window-pick
  ];

  # XDG user directories (Pictures, Downloads, ...), created on activation, plus a
  # Screenshots folder (XDG_SCREENSHOTS_DIR) for the screenshot script.
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    extraConfig.SCREENSHOTS = "${config.home.homeDirectory}/Pictures/Screenshots";
  };
}
