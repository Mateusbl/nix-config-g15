# Intel TigerLake-H + NVIDIA RTX 3050 Mobile (PRIME offload).
# Settings are explicit so they don't depend on nixos-hardware defaults.
{ pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
    ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true; # requires offload.enable
    # NVIDIA's open-source kernel modules (the driver itself stays NVIDIA's). NVIDIA recommends
    # them for Turing and newer; the RTX 3050 Mobile is Ampere. Fine-grained power management
    # (the card switching off when idle) works with them too.
    open = true;
    nvidiaSettings = true;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true; # provides the `nvidia-offload` wrapper
      # Verified with: lspci | grep -E "VGA|3D"
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
