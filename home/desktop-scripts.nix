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
    ];
    text = ''
      choice=$(printf '%s\n' lock suspend hibernate reboot poweroff logout |
        fuzzel --dmenu --only-match --prompt "Power  ") || exit 0
      case "$choice" in
        lock) loginctl lock-session ;;
        suspend) systemctl suspend ;;
        hibernate) systemctl hibernate ;;
        reboot) systemctl reboot ;;
        poweroff) systemctl poweroff ;;
        logout) hyprctl dispatch 'hl.dsp.exit()' ;; # hyprctl comes with Hyprland
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

  # ALT+Tab: pick a window with fuzzel. Windows are listed most recently used first, starting
  # with the one before the current window, so ALT+Tab then Enter jumps back to it. Type to
  # filter, Tab / arrows to move, Enter to switch, Escape to cancel. All workspaces are listed.
  window-pick = pkgs.writeShellApplication {
    name = "window-pick";
    runtimeInputs = with pkgs; [
      jq
      fuzzel
    ];
    # hyprctl comes with Hyprland (system profile), already on PATH in the session.
    text = ''
      windows=$(hyprctl clients -j | jq -r '
        map(select(.mapped)) | sort_by(.focusHistoryID) | (.[1:] + .[:1]) | .[]
        | "\(.address)\t\(.class)  \(.title)"')
      [ -n "$windows" ] || exit 0
      address=$(printf '%s\n' "$windows" |
        fuzzel --dmenu --only-match --with-nth=2 --match-nth=2 --accept-nth=1 \
          --width 70 --prompt "Window  ") || exit 0
      hyprctl dispatch "hl.dsp.focus({ window = \"address:$address\" })"
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

  # SUPER+period: pick an emoji with fuzzel; it is typed into the focused window and copied.
  # rofimoji ships its emoji list, so nothing is downloaded.
  emoji-pick = pkgs.writeShellApplication {
    name = "emoji-pick";
    runtimeInputs = with pkgs; [
      rofimoji
      fuzzel
      wl-clipboard
      wtype
    ];
    text = ''
      exec rofimoji --selector fuzzel --clipboarder wl-copy --typer wtype --action type copy
    '';
  };
in
{
  home.packages = [
    power-menu
    screenshot
    clipboard-pick
    emoji-pick
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
