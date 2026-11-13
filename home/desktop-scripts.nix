# Small desktop helpers bound to keys in home/hyprland.nix.
# writeShellApplication: strict bash, explicit dependencies, shellcheck at build time.
{ config, pkgs, ... }:

let
  screenshotsDir = config.xdg.userDirs.extraConfig.SCREENSHOTS;

  # SUPER+SHIFT+Escape. rofi with -no-custom: only a listed entry can be chosen, and Escape
  # cancels, so a stray key press can never power the laptop off.
  power-menu = pkgs.writeShellApplication {
    name = "power-menu";
    runtimeInputs = with pkgs; [
      rofi
      systemd
      uwsm
    ];
    text = ''
      choice=$(printf '%s\n' lock suspend reboot poweroff logout |
        rofi -dmenu -i -no-custom -p "Power") || exit 0
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
      rofi
      wl-clipboard
    ];
    text = ''
      entry=$(cliphist list | rofi -dmenu -i -no-custom -p "Clipboard") || exit 0
      printf '%s' "$entry" | cliphist decode | wl-copy
    '';
  };
in
{
  home.packages = [
    power-menu
    screenshot
    clipboard-pick
  ];

  # XDG user directories (Pictures, Downloads, ...), created on activation, plus a
  # Screenshots folder (XDG_SCREENSHOTS_DIR) for the screenshot script.
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    extraConfig.SCREENSHOTS = "${config.home.homeDirectory}/Pictures/Screenshots";
  };
}
