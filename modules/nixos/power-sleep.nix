# Firmware, power, memory, suspend/hibernate behaviour.
# (The swap/resume device itself is declared in hosts/g15/default.nix.)
{
  services.fwupd.enable = true;
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;
  zramSwap.enable = true;

  # Lid switch and power button
  services.logind.settings = {
    Login = {
      HandleLidSwitch = "suspend-then-hibernate";
      HandleLidSwitchExternalPower = "suspend";
      HandlePowerKey = "suspend";
      HandlePowerKeyLongPress = "poweroff";
    };
  };

  # Wait 2 hours in RAM-sleep before writing to disk
  systemd.sleep.settings = {
    Sleep = {
      HibernateDelaySec = "2h";
    };
  };

  systemd.services.disable-instant-wake = {
    description = "Disable devices that cause instant wake from suspend";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      for dev in XHCI TXHC PEG0 PEG1 RP14; do
        if grep -q "$dev.*\*enabled" /proc/acpi/wakeup; then
          echo $dev > /proc/acpi/wakeup
        fi
      done
    '';
  };
}
