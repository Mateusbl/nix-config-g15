# Firmware, power profile, memory, suspend/hibernate behaviour.
# (The swap/resume device itself is declared in disko; the NVIDIA card sleeps via
# modules/nixos/nvidia.nix.)
{ config, ... }:

let
  # power-profiles-daemon's CLI; used by the charger rules below.
  powerprofilesctl = "${config.services.power-profiles-daemon.package}/bin/powerprofilesctl";

  # A oneshot unit that switches the profile; started by the udev rules below.
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
  # power-profiles-daemon (above) sets the CPU's energy/performance bias. The profile follows the
  # charger: "performance" when plugged in, "balanced" on battery. Nothing is throttled to save
  # power (no power-saver profile, no Wi-Fi power saving, the panel stays at 120 Hz). The udev
  # rules fire when the charger is (un)plugged and also once at boot. You can still change the
  # profile by hand (the bar's settings panel has a power profile button); it is reset at the next plug/unplug.
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", TAG+="systemd", ENV{SYSTEMD_WANTS}="power-profile-battery.service"
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", TAG+="systemd", ENV{SYSTEMD_WANTS}="power-profile-ac.service"
  '';
  systemd.services.power-profile-battery = setProfile "balanced";
  systemd.services.power-profile-ac = setProfile "performance";

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
