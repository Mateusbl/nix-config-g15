# Firmware, power, memory, suspend/hibernate behaviour, and battery tuning.
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

  # --- Battery -------------------------------------------------------------------------
  # power-profiles-daemon (above) sets the CPU's energy/performance bias. By default it stays on
  # "balanced" even when unplugged, so the profile follows the charger instead: power-saver on
  # battery, balanced on AC. The udev rules fire when the charger is (un)plugged and also once
  # at boot, so the profile always matches the current state. You can still change it by hand
  # (Waybar's PWR label cycles it on click); it is reset at the next plug/unplug.
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", TAG+="systemd", ENV{SYSTEMD_WANTS}="power-profile-battery.service"
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", TAG+="systemd", ENV{SYSTEMD_WANTS}="power-profile-ac.service"
  '';
  systemd.services.power-profile-battery = setProfile "power-saver";
  systemd.services.power-profile-ac = setProfile "balanced";

  # The Wi-Fi radio sleeps between packets. Costs a few ms of latency, saves a fraction of a watt.
  networking.networkmanager.wifi.powersave = true;

  # UPower watches the battery and acts before it runs flat: low at 20%, critical at 10%, and at
  # 5% the laptop hibernates (the encrypted swap partition doubles as the hibernation target).
  # Waybar's battery label changes at the same thresholds.
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
