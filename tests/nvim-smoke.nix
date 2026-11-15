# Runs tests/nvim-smoke.sh as a flake check (`nix flake check`), against exactly the Neovim
# package and the ~/.config/nvim files this flake builds for the user. A Lua error in the editor
# config then fails the check instead of showing up after a switch.
{
  pkgs,
  lib,
  hm, # the user's evaluated home-manager configuration
}:

let
  # What home-manager would install under ~/.config/nvim (init.lua, lua/*.lua, queries).
  nvimFiles = lib.filterAttrs (
    name: file: file.enable && lib.hasPrefix "nvim/" name
  ) hm.xdg.configFile;
  configHome = pkgs.linkFarm "nvim-config-home" (
    lib.mapAttrsToList (name: file: {
      inherit name;
      path = file.source;
    }) nvimFiles
  );
in
pkgs.runCommand "nvim-smoke"
  {
    nativeBuildInputs = [
      hm.programs.nixvim.build.package
      pkgs.gawk
      pkgs.gnugrep
      pkgs.gnused
    ];
  }
  ''
    # A throwaway home: Neovim reads its config from the store and writes state here.
    export HOME=$TMPDIR/home
    export XDG_CONFIG_HOME=${configHome}
    export XDG_DATA_HOME=$HOME/.local/share XDG_STATE_HOME=$HOME/.local/state XDG_CACHE_HOME=$HOME/.cache
    mkdir -p "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

    # pipefail: without it the pipe to `tee` would hide a failing test.
    set -o pipefail
    bash ${./nvim-smoke.sh} | tee $out
  ''
