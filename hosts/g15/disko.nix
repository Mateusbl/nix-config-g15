# Declarative disk layout (disko). It matches the layout the old
# hardware-configuration.nix described:
#
#   GPT
#   ├─ ESP    vfat  -> /boot          (fmask/dmask 0077)
#   ├─ swap   LUKS  -> encrypted swap, also the hibernation (resume) device
#   └─ root   LUKS  -> btrfs
#                      ├─ top level  -> /
#                      ├─ @home      -> /home   (subvolume "home")
#                      └─ @nix       -> /nix    (subvolume "nix")
#
# On a fresh install:
#   sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko/latest -- \
#     --mode destroy,format,mount --flake .#g15
#   sudo nixos-install --flake .#g15
#
# `device` and the partition sizes are only read by the disko CLI when partitioning. The NixOS
# config refers to partitions by GPT label (/dev/disk/by-partlabel/disk-main-*), so the system
# boots no matter what the kernel names the disk, and changing a size later changes nothing on an
# installed machine.
#
# Swap size follows the RAM: my.disk.ramGiB (set per host, see hosts/g15/default.nix) plus
# my.disk.swapOffsetGiB. Nix cannot read the RAM itself (builds give the same result on every
# machine), so the install guide (README, path B) writes the real value into the host file just
# before disko runs.
{ config, lib, ... }:

let
  cfg = config.my.disk;
in
{
  options.my.disk = {
    ramGiB = lib.mkOption {
      type = lib.types.ints.positive;
      description = "Installed RAM in GiB, rounded up. Sizes the swap partition.";
    };
    swapOffsetGiB = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 2;
      description = ''
        Swap beyond the RAM size. Hibernation writes RAM into swap (compressed, usually well
        under the RAM size); the extra room covers a large image while some swap is already in
        use, without reserving much more disk than needed.
      '';
    };
  };

  config.disko.devices.disk.main = {
    type = "disk";
    # Check with `lsblk` before running disko: everything on this disk is erased.
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "fmask=0077"
              "dmask=0077"
            ];
          };
        };

        # RAM + offset, so hibernation always fits (see my.disk above).
        swap = {
          priority = 2;
          size = "${toString (cfg.ramGiB + cfg.swapOffsetGiB)}G";
          content = {
            type = "luks";
            name = "cryptswap";
            settings.allowDiscards = true;
            content = {
              type = "swap";
              resumeDevice = true; # sets boot.resumeDevice
            };
          };
        };

        root = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              # Top-level volume is mounted as /, like before (no subvol= option).
              mountpoint = "/";
              mountOptions = [
                "compress=zstd"
                "noatime"
              ];
              subvolumes = {
                "home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };
}
