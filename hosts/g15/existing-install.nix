# Bridge for the machine as it is installed today (before it was ever formatted by disko).
#
# disko refers to partitions by GPT label (disk-main-ESP, disk-main-swap, disk-main-root)
# and names the LUKS mappings cryptroot / cryptswap. The current partitions were created
# by the NixOS installer and have neither those labels nor those names, so this file
# points the generated config back at the existing UUIDs. Without it, the current
# machine would not find its disks at boot.
#
# Remove this file (and its import in ./default.nix) once either:
#   - the machine has been reinstalled with disko, or
#   - the existing partitions were given disko's labels, e.g. (check numbers with lsblk):
#       sudo sgdisk -c 1:disk-main-ESP -c 2:disk-main-root -c 3:disk-main-swap /dev/nvme0n1
{ lib, ... }:

let
  rootUuid = "fcd97582-27f3-47fb-823a-f9a69bdc8f70";
  swapUuid = "65798653-0b13-4ff6-8b1f-fdcfd320bc5b";
in
{
  boot.initrd.luks.devices = {
    cryptroot.device = lib.mkForce "/dev/disk/by-uuid/${rootUuid}";
    cryptswap.device = lib.mkForce "/dev/disk/by-uuid/${swapUuid}";
  };

  fileSystems."/boot".device = lib.mkForce "/dev/disk/by-uuid/F0E7-A07C";
}
