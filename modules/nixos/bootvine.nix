# bootvine: live tree of systemd jobs on the boot console (initrd, stage 2 and shutdown).
#
# Uses the module that ships in nixpkgs (services.bootvine), NOT the author's flake, so
# nothing is fetched from the author's Codeberg flake or his Cachix cache. The package is
# built by nixpkgs and comes from cache.nixos.org once Hydra has built it.
#
# The module was merged into nixpkgs master on 2026-11-12. Until your nixpkgs input
# contains it, evaluation fails with "option `services.bootvine' does not exist":
#   nix flake update nixpkgs
# If it still fails, the nixos-unstable channel has not caught up yet. Comment out the
# `./bootvine.nix` line in modules/nixos/default.nix and retry in a few days.
#
# It sits in the boot path and answers the LUKS passphrase prompt, so test with
# `nh os test` first and keep the previous generation in the boot menu.
{
  # bootvine needs a systemd-based initrd (default in recent NixOS, explicit on purpose).
  boot.initrd.systemd.enable = true;

  services.bootvine.enable = true;

  # Optional tuning goes in services.bootvine.settings (TOML), for example:
  # services.bootvine.settings.timing.keep-final-frame-for = "500ms";
}
