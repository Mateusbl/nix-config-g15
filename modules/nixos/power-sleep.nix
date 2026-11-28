# Firmware, power profile, memory, suspend/hibernate behaviour.
# (The swap/resume device itself is declared in disko; the NVIDIA card sleeps via
# modules/nixos/nvidia.nix.)
{ config, ... }:

let
  # power-profiles-daemon's CLI; used by the boot service below.
  powerprofilesctl = "${config.services.power-profiles-daemon.package}/bin/powerprofilesctl";

  # A oneshot unit that switches the profile.
  setProfile = profile: {
    description = "Switch the power profile to ${profile}";
    after = [ "power-profiles-daemon.service" ];
    wants = [ "power-profiles-daemon.service" ];
    serviceConfig.Type = "oneshot";
    script = "${powerprofilesctl} set ${profile}";
  };
in
{
  services.fwupd.enable = true;
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;
  zramSwap.enable = true;

  # Wi-Fi power saving off. Leaving it unset is not the same: NetworkManager then keeps the
  # kernel's default, which has power saving on (slower first packets, laggy SSH and calls).
  networking.networkmanager.wifi.powersave = false;
  # The same for iwd, which NetworkManager uses as its Wi-Fi backend (base.nix). "*" = any driver.
  networking.wireless.iwd.settings.DriverQuirks.PowerSaveDisable = "*";

  # --- Power profile ---------------------------------------------------------------------
  # power-profiles-daemon (above) sets the CPU's energy/performance bias. Every boot starts in
  # "balanced", on the charger and on battery. Nothing is throttled to save power (no power-saver
  # profile, no Wi-Fi power saving, the panel stays at 120 Hz). Change it by hand with the power
  # profile button in the bar (PWR) (`performance` for games or builds); that lasts
  # until the next reboot.
  systemd.services.power-profile-default = setProfile "balanced" // {
    wantedBy = [ "multi-user.target" ];
  };

  # A safety net, not a power saver: UPower watches the battery and acts before it runs flat:
  # low at 20%, critical at 10%, and at 5% the laptop hibernates (the encrypted swap partition doubles as the hibernation target).
  services.upower = {
    enable = true;
    percentageLow = 20;
    percentageCritical = 10;
    percentageAction = 5;
    criticalPowerAction = "Hibernate";
  };

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
