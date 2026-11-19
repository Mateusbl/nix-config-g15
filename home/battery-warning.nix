# Low-battery warning. UPower (modules/nixos/power-sleep.nix) hibernates the laptop at 5%, but it
# shows nothing before that: the bar's battery icon is easy to miss. This checks the battery once a
# minute and sends one notification when it drops to 20% and another (critical) at 10%, the same
# thresholds UPower uses. Plugging in the charger resets it.
{ pkgs, ... }:

let
  battery-warning = pkgs.writeShellApplication {
    name = "battery-warning";
    runtimeInputs = with pkgs; [
      libnotify
      coreutils
    ];
    text = ''
      shopt -s nullglob
      for bat in /sys/class/power_supply/BAT*; do
        capacity=$(cat "$bat/capacity")
        status=$(cat "$bat/status")
        # The last threshold already warned about, so each warning is sent only once.
        state="''${XDG_RUNTIME_DIR:-/tmp}/battery-warning-$(basename "$bat")"
        last=$(cat "$state" 2>/dev/null || echo 100)

        if [ "$status" != "Discharging" ]; then
          echo 100 >"$state"
          continue
        fi

        if [ "$capacity" -le 10 ] && [ "$last" -gt 10 ]; then
          notify-send -u critical -i battery-caution "Battery at ''${capacity}%" \
            "Plug in the charger now. The laptop hibernates at 5%."
          echo 10 >"$state"
        elif [ "$capacity" -le 20 ] && [ "$last" -gt 20 ]; then
          notify-send -i battery-low "Battery at ''${capacity}%" "Plug in the charger soon."
          echo 20 >"$state"
        fi
      done
    '';
  };
in
{
  systemd.user.services.battery-warning = {
    Unit.Description = "Warn when the battery is low";
    Service = {
      Type = "oneshot";
      ExecStart = "${battery-warning}/bin/battery-warning";
    };
  };

  systemd.user.timers.battery-warning = {
    Unit.Description = "Check the battery every minute";
    Timer = {
      OnStartupSec = "1min";
      OnUnitActiveSec = "1min";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
