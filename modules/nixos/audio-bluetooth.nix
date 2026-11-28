{
  # Audio (PipeWire)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Bluetooth, on from boot. bluetui, a terminal app, turns it off and on and pairs new devices
  # (home/session.nix; click BT in the bar).
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
}
