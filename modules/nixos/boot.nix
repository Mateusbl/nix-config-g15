# Boot loader: systemd-boot, installed and signed by lanzaboote for Secure Boot.
#
# Plain systemd-boot copies the kernel and initrd to the ESP unsigned, so with Secure Boot on the
# firmware would refuse them. lanzaboote bundles kernel + initrd + command line into one signed
# file per generation (a UKI) and installs a signed systemd-boot. The boot menu, the
# 10-generation limit and rollbacks work as before.
#
# The keys live in /var/lib/sbctl. Turning Secure Boot on in the firmware is a one-time manual
# step: README, "Secure Boot".
{
  inputs,
  lib,
  pkgs,
  self,
  ...
}:

{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  # Record the git commit in system generations (falls back to dirtyRev, then null)
  system.configurationRevision = self.rev or self.dirtyRev or null;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot = {
    # lanzaboote installs systemd-boot itself (signed); NixOS' own installer must stay off.
    enable = lib.mkForce false;
    # Read by lanzaboote too:
    configurationLimit = 10;
    editor = false; # no editing the kernel command line from the boot menu
  };
  boot.loader.efi.canTouchEfiVariables = true;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    # Create the keys at the first boot if they do not exist yet. Until then lanzaboote installs
    # unsigned files, which boot fine while Secure Boot is still off in the firmware.
    autoGenerateKeys.enable = true;
  };

  # sbctl: create, inspect and enroll the keys (`sudo sbctl status`, `sudo sbctl verify`).
  environment.systemPackages = [ pkgs.sbctl ];
}
