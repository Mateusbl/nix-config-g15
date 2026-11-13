# Everything specific to this physical machine. Shared behaviour lives in modules/nixos.
# Disks are declared with disko (./disko.nix); there is no hardware-configuration.nix.
{
  hostname,
  inputs,
  lib,
  config,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./existing-install.nix # remove after a disko reinstall, see the file
    ../../modules/nixos
  ];

  networking.hostName = hostname;

  # What nixos-generate-config detected for this machine (Intel TigerLake-H, NVMe).
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Never change this after the first install
  system.stateVersion = "26.05";
}
