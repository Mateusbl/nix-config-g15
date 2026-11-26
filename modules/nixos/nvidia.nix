# Intel TigerLake-H + NVIDIA RTX 3050 Mobile (PRIME offload).
#
# The nixos-hardware profiles imported in flake.nix already cover the basics:
#   - Intel TigerLake profile: the Intel video drivers (intel-media-driver, vpl-gpu-rt),
#     microcode updates and GuC/HuC firmware for the iGPU (i915.enable_guc=3).
#   - common-gpu-nvidia: the NVIDIA driver, PRIME offload with the `nvidia-offload` command,
#     nouveau blacklisted, and udev rules that let the card's extra PCI functions sleep.
# This file adds what is specific to this laptop: 32-bit graphics, the bus IDs, power management
# and the open kernel modules.
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam / Proton and other 32-bit programs
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true; # the card powers off when idle (needs PRIME offload)
    # NVIDIA's open-source kernel modules (the driver itself stays NVIDIA's). NVIDIA recommends
    # them for Turing and newer; the RTX 3050 Mobile is Ampere. Fine-grained power management
    # (the card switching off when idle) works with them too.
    open = true;
    nvidiaSettings = true;
    prime = {
      # Verified with: lspci | grep -E "VGA|3D"
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
