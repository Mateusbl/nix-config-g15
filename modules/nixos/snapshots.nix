# Local btrfs snapshots of /home with btrbk.
#
# NixOS generations roll back the system, but nothing protects files in /home. A snapshot is
# a read-only, instant, copy-on-write view of the subvolume: cheap, and good against
# "I deleted/overwrote that file an hour ago". It is NOT a backup: snapshots live on the same
# disk (see docs/questions.md for the off-disk target).
#
# btrbk rather than snapper: one declarative config, no per-subvolume state to create first,
# and the same tool can later send these snapshots to an external drive (send/receive) once
# a target is chosen.
{
  services.btrbk.instances.home = {
    onCalendar = "hourly";
    snapshotOnly = true; # only snapshots for now, no send/receive target
    settings = {
      # Hourly snapshots need a time in the name ("short" is date only and would collide).
      timestamp_format = "long";
      snapshot_preserve_min = "2h"; # never delete anything younger than 2 hours
      snapshot_preserve = "24h 7d"; # then keep 24 hourly and 7 daily snapshots
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
