{
  # Audio (PipeWire)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Bluetooth, on from boot; the bar's settings panel turns it off and on. New devices are paired
  # with overskride (home/session.nix; launcher, or right-click the panel's Bluetooth button).
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
}
