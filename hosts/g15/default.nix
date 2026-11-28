# Everything specific to this physical machine. Shared behaviour lives in modules/nixos.
# Disks are declared with disko (./disko.nix); there is no hardware-configuration.nix.
{
  hostname,
  inputs,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.disko.nixosModules.disko
    ./disko.nix
    ../../modules/nixos
  ];

  networking.hostName = hostname;
  my.ctosGreeter.machine = "Dell G15 5511"; # shown on the login and lock screen

  # Installed RAM in GiB; disko sizes the swap partition from it (RAM + 2 GiB, hosts/g15/disko.nix).
  # Only used when partitioning. The install guide (README, path B) sets it from the machine.
  my.disk.ramGiB = 16;

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
  # Intel microcode updates come from the TigerLake profile (flake.nix).

  # Never change this after the first install
  system.stateVersion = "26.05";
}
