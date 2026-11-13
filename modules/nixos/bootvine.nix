# bootvine: live tree of systemd jobs on the boot console (initrd, stage 2 and shutdown).
#
# The package comes from nixpkgs (cache.nixos.org); nothing is fetched from the author's own
# flake or cache. The services.bootvine *module* is not in nixos-unstable yet, so a copy is
# imported until it is (bootvine-module.nix). The check below turns the copy off by itself as
# soon as the locked nixpkgs has the module.
#
# It sits in the boot path and shows the LUKS passphrase prompt, so test with `nh os test`
# first (it does not change the boot menu) and keep the previous generation selectable.
{ lib, modulesPath, ... }:

{
  imports = lib.optional (
    !builtins.pathExists (modulesPath + "/services/system/bootvine.nix")
  ) ./bootvine-module.nix;

  # bootvine needs a systemd-based initrd. In this nixpkgs that is the only kind left (the scripted
  # initrd and the boot.initrd.systemd.enable option were removed), so nothing to set for it.

  services.bootvine.enable = true;

  # Optional tuning goes in services.bootvine.settings (TOML), for example:
  # services.bootvine.settings.timing.keep-final-frame-for = "500ms";
}
