# Btrfs maintenance. Mount options (compress=zstd, noatime) are set per mountpoint
# in hosts/<host>/disko.nix.
{
  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/" ];
  };
}
