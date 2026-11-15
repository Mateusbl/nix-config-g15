# Nix daemon settings, flake registry pinning, garbage collection, nh.
{ inputs, username, ... }:

{
  nixpkgs.config.allowUnfree = true;

  nix = {
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Never silently accept `nixConfig` (extra substituters / keys) from a flake.
      # This is what keeps third-party binary caches such as a project's Cachix out.
      accept-flake-config = false;

      # To add a cache on purpose, use `extra-substituters` + `extra-trusted-public-keys`
      # here, never via a flake's own nixConfig.
    };
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };

    # Builds (bootvine is compiled here, and so is anything not on cache.nixos.org) only get CPU
    # and disk time nothing else wants, so the desktop stays responsive during `nh os switch`.
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
  };

  # nh (Nix Helper). Path is case-sensitive.
  programs.nh = {
    enable = true;
    flake = "/home/${username}/Code/nix-config";
    clean = {
      enable = true;
      extraArgs = "--keep-since 4d --keep 3";
    };
  };
}
