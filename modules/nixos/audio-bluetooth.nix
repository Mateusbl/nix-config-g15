{
  # Audio (PipeWire)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Bluetooth. The radio stays off after boot; turn it on from the bar's settings panel.
  # blueman-manager (launcher, or right-click the panel's Bluetooth button) pairs new devices.
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };
  services.blueman.enable = true;
}
