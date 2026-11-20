# Games. Steam is the one FHS-style exception CLAUDE.md allows (programs.steam): it brings its
# own runtime with the 32-bit libraries games expect. 32-bit graphics are on in nvidia.nix.
#
# Games run on the Intel GPU unless told otherwise. For the RTX 3050, set each game's launch
# options (right-click → Properties → Launch Options) to:  nvidia-offload %command%
{ pkgs, ... }:

{
  programs.steam = {
    enable = true;

    # Proton-GE: a community build of Proton (Valve's Windows compatibility layer) with extra
    # fixes and codecs, so some games run or play videos where Valve's Proton does not. It shows
    # up in Steam as one more choice under Properties → Compatibility; Valve's Proton stays the
    # default.
    extraCompatPackages = [ pkgs.proton-ge-bin ];

    # protontricks: installs Windows components (fonts, Visual C++ runtimes, ...) into one game's
    # Proton prefix, which a few games need. Run `protontricks --gui` and pick the game.
    protontricks.enable = true;
  };
}
