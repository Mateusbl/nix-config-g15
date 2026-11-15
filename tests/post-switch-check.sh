#!/usr/bin/env bash
# Post-switch check: is everything this config sets up actually running on this machine?
#
# Run it inside the Hyprland session after `nh os test` or `nh os switch`:
#   tests/post-switch-check.sh
# It only reads state (no sudo, nothing is changed). Each line is OK, FAIL (with a hint) or
# INFO. The exit code is the number of failed checks.
set -uo pipefail

failed=0

ok() { printf '  OK    %s\n' "$1"; }
info() { printf '  INFO  %s\n' "$1"; }
fail() {
  printf '  FAIL  %s\n' "$1"
  [ -n "${2:-}" ] && printf '        -> %s\n' "$2"
  failed=$((failed + 1))
}

# check <description> <hint> <command...>: OK when the command succeeds.
check() {
  local what=$1 hint=$2
  shift 2
  if "$@" >/dev/null 2>&1; then ok "$what"; else fail "$what" "$hint"; fi
}

section() { printf '\n%s\n' "$1"; }

# ----------------------------------------------------------------------------------------
section "System services"
check "earlyoom is running" "systemctl status earlyoom" systemctl is-active --quiet earlyoom
check "power-profiles-daemon is running" "systemctl status power-profiles-daemon" \
  systemctl is-active --quiet power-profiles-daemon
check "UPower is running (low-battery actions)" "systemctl status upower" systemctl is-active --quiet upower
check "btrbk snapshot timer is scheduled" "systemctl status btrbk-home.timer" \
  systemctl is-active --quiet btrbk-home.timer
check "/.snapshots exists" "created at boot by systemd-tmpfiles; reboot, then: ls -d /.snapshots" test -d /.snapshots
check "weekly TRIM timer is scheduled" "systemctl status fstrim.timer" systemctl is-active --quiet fstrim.timer
check "NetworkManager is running" "systemctl status NetworkManager" systemctl is-active --quiet NetworkManager
check "Bluetooth service is running" "systemctl status bluetooth" systemctl is-active --quiet bluetooth

section "Boot screen and hibernation"
if [ "$(systemctl show -p Result --value bootvine.service 2>/dev/null)" = "success" ]; then
  ok "bootvine ran without error this boot"
else
  fail "bootvine did not finish cleanly" "journalctl -b -u bootvine"
fi
if [ -r /sys/power/resume ] && [ "$(cat /sys/power/resume)" != "0:0" ]; then
  ok "a hibernation (resume) device is set"
else
  fail "no hibernation device is set" "check boot.resumeDevice / the swap partition in hosts/g15"
fi
check "swap is active" "swapon --show" test -n "$(swapon --show --noheadings 2>/dev/null)"

section "Battery"
on_ac=no
for supply in /sys/class/power_supply/*; do
  if [ "$(cat "$supply/type" 2>/dev/null)" = "Mains" ] && [ "$(cat "$supply/online" 2>/dev/null)" = "1" ]; then
    on_ac=yes
  fi
done
profile=$(powerprofilesctl get 2>/dev/null || echo unknown)
expected=$([ "$on_ac" = yes ] && echo balanced || echo power-saver)
if [ "$profile" = "$expected" ]; then
  ok "power profile is '$profile' (charger connected: $on_ac)"
else
  # Not necessarily wrong: the profile can be changed by hand until the next plug/unplug.
  info "power profile is '$profile', the automatic one would be '$expected' (charger connected: $on_ac)"
fi
gpu=/sys/bus/pci/devices/0000:01:00.0/power/runtime_status
if [ -r "$gpu" ]; then
  info "NVIDIA card power state: $(cat "$gpu") ('suspended' is what saves battery when nothing uses it)"
fi

# ----------------------------------------------------------------------------------------
section "Session services (systemd --user)"
for unit in oo7-daemon waybar mako hypridle hyprpaper cliphist network-manager-applet \
  blueman-applet playerctld ssh-agent hyprpolkitagent; do
  check "$unit is running" "systemctl --user status $unit" systemctl --user is-active --quiet "$unit"
done

section "Secrets (oo7)"
check "org.freedesktop.secrets is owned on the session bus" "see docs/oo7-notes.md" \
  busctl --user status org.freedesktop.secrets
check "the Secret portal is assigned to oo7" "cat /etc/xdg/xdg-desktop-portal/hyprland-portals.conf" \
  grep -q "portal.Secret=oo7-portal" /etc/xdg/xdg-desktop-portal/hyprland-portals.conf
if pgrep -x gnome-keyring-d >/dev/null 2>&1; then
  fail "gnome-keyring-daemon is running too" "oo7 must be the only Secret Service; find what starts it"
else
  ok "no gnome-keyring-daemon"
fi

section "Hyprland"
check "Hyprland answers hyprctl" "run this inside the Hyprland session" hyprctl monitors
if errors=$(hyprctl configerrors 2>/dev/null) && [ -n "$errors" ]; then
  fail "Hyprland reports config errors" "$errors"
else
  ok "Hyprland reports no config errors"
fi

section "Commands on PATH"
for cmd in nvim yazi jj jjui oo7-cli power-menu screenshot clipboard-pick osd rofi \
  playerctl pavucontrol imv mpv zathura direnv; do
  check "$cmd" "not installed? check home/*.nix" command -v "$cmd"
done

section "Folders and themes"
check "screenshots folder exists" "created on activation (xdg.userDirs)" test -d "$HOME/Pictures/Screenshots"
check "icon theme Papirus-Dark is installed" "stylix.icons in modules/nixos/stylix.nix" \
  test -d "$HOME/.nix-profile/share/icons/Papirus-Dark" -o -d "/etc/profiles/per-user/$(id -un)/share/icons/Papirus-Dark" \
  -o -d /run/current-system/sw/share/icons/Papirus-Dark
info "cursor theme: ${XCURSOR_THEME:-not set} (expected Bibata-Modern-Ice)"

# ----------------------------------------------------------------------------------------
printf '\n'
if [ "$failed" -eq 0 ]; then
  echo "All checks passed. Neovim has its own test: tests/nvim-smoke.sh"
else
  echo "$failed check(s) failed. Neovim has its own test: tests/nvim-smoke.sh"
fi
exit "$failed"
