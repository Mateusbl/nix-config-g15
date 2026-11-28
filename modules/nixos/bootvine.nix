# bootvine: live tree of systemd jobs on the boot console (initrd, stage 2 and shutdown).
#
# Taken from bootvine's own flake (the `bootvine` input in flake.nix): its NixOS module and its
# package, which is compiled on this machine with the Rust toolchain the project pins. No binary
# cache is used for it.
#
# nixpkgs is about to ship a services.bootvine module of its own. When it does, declaring the same
# options twice is an error, so at that point delete the `bootvine` input and the import below and
# use nixpkgs' module and package.
#
# It sits in the boot path and shows the LUKS passphrase prompt, so test with `nh os test`
# first (it does not change the boot menu) and keep the previous generation selectable.
{ inputs, ... }:

{
  imports = [ inputs.bootvine.nixosModules.bootvine ];

  # The systemd-based initrd is the only kind this nixpkgs still has, so there is nothing to set
  # for it (the boot.initrd.systemd.enable option no longer exists).
  services.bootvine.enable = true;

  # Colours are names from the console's 16-colour palette, which Stylix sets from the system
  # palette (modules/nixos/stylix.nix), so "blue" is the desktop's accent. bootvine's own
  # highlights are yellow; these make "in progress" blue like everything else, while green
  # (finished) and red (failed) keep their meaning.
  services.bootvine.settings.colors = {
    tree.current-stage = "blue";
    tree.running-marker = "blue";
    timeline.running = "blue";
    footer.running = "blue";
    password.frame = "blue";
  };
}
