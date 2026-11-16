# Local btrfs snapshots of /home with btrbk.
#
# NixOS generations roll back the system, but nothing protects files in /home. A snapshot is
# a read-only, instant, copy-on-write view of the subvolume: cheap, and good against
# "I deleted/overwrote that file yesterday". It is NOT a backup: snapshots live on the same
# disk. The owner keeps off-disk backups separately, outside this config.
#
# btrbk rather than snapper: one declarative config, no per-subvolume state to create first,
# and the same tool can send these snapshots to an external drive (send/receive) if that is
# ever wanted.
{
  services.btrbk.instances.home = {
    # Once a day. The timer is persistent: if the laptop was off at midnight, the snapshot is
    # taken shortly after the next boot.
    onCalendar = "daily";
    snapshotOnly = true; # local snapshots only, no send/receive target
    settings = {
      # Date and time in the name, so an extra manual run on the same day cannot collide.
      timestamp_format = "long";
      snapshot_preserve_min = "2d"; # never delete anything younger than 2 days
      snapshot_preserve = "14d"; # then keep one snapshot per day for 14 days
      # Renders as:  volume /  ->  snapshot_dir .snapshots  ->  subvolume home
      # /home is the "home" subvolume (hosts/g15/disko.nix); snapshots go to /.snapshots,
      # which is on the same btrfs filesystem but outside /home itself.
      volume."/" = {
        snapshot_dir = ".snapshots";
        subvolume.home = { };
      };
    };
  };

  # Create /.snapshots as a btrfs subvolume ("v"), so snapshots are not part of the root
  # filesystem's own snapshots should you ever take some. Only root can read it.
  systemd.tmpfiles.rules = [ "v /.snapshots 0700 root root -" ];
}
