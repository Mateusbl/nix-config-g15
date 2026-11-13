{ pkgs, self, ... }:

{
  # Record the git commit in system generations (falls back to dirtyRev, then null)
  system.configurationRevision = self.rev or self.dirtyRev or null;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;
}
