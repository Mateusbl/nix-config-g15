{
  imports = [
    ./base.nix
    ./boot.nix
    # ./bootvine.nix # enable once nixos-unstable has services.bootvine, see the file
    ./storage.nix
    ./nix.nix
    ./nvidia.nix
    ./power-sleep.nix
    ./audio-bluetooth.nix
    ./desktop.nix
    ./podman.nix
    ./stylix.nix
    ./users.nix
  ];
}
