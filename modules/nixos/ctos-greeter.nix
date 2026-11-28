# Login screen: the ctOS greeter (https://github.com/TSM-061/ctOS, GPL-3.0), an animated
# "terminal" login inspired by Watch Dogs' ctOS, written in QML for Quickshell.
#
# Packaged the Nix way instead of its install script:
#   - the source is pinned to one commit and hash (fetchFromGitHub: no flake input, nothing is
#     downloaded at runtime); to update, change `rev` and `hash` below
#   - it runs from the Nix store with nixpkgs' Quickshell, inside cage (a tiny kiosk compositor)
#   - its config (/etc/ctos) is generated here, its state dir (/var/lib/ctos) by systemd-tmpfiles
#   - its colours come from the Stylix palette (modules/nixos/stylix.nix) instead of its own greys,
#     so it follows the system theme
#
# Using it: the screen types out a short boot sequence, then asks for the password of the first
# normal user (mateus) and starts the first session (Hyprland). Typing commands instead of a
# password: `help`, `users`, `desktops`, `chusr <name>`, `chdesk <name>`.
#
# If it ever fails to start: Ctrl+Alt+F2 gives a text login. Setting
# `my.ctosGreeter.enable = false;` brings back tuigreet (modules/nixos/desktop.nix), and the
# previous generation in the boot menu always has the old login screen.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.ctosGreeter;
  c = config.lib.stylix.colors; # hex without '#'
  hex = name: "#${c.${name}}";

  # Where NixOS puts the session entries (Hyprland). ctOS looks in /usr/share, which NixOS has not.
  sessions = "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";

  ctos = pkgs.stdenvNoCC.mkDerivation {
    pname = "ctos-greeter";
    version = "0-unstable-2026-11-01";

    src = pkgs.fetchFromGitHub {
      owner = "TSM-061";
      repo = "ctOS";
      rev = "06e67f79417e3a425dae3dbb747aa7f1e8c8343c";
      hash = "sha256-MpCZQNZbqW68OLoGli+6auv/cCkTMlFH8Tu5166OMNQ=";
    };

    # --replace-fail: if a new upstream version changes one of these lines, the build stops
    # instead of silently keeping the old value.
    postPatch = ''
      substituteInPlace greeter/services/SessionManager.qml \
        --replace-fail /usr/share/wayland-sessions ${sessions}

      # Kiosk mode (the one used inside cage) has no settings block upstream, so its animation
      # setting could not be read; give it one like the other modes.
      substituteInPlace greeter/config/GeneralDto.qml \
        --replace-fail 'property ModeSettings test: ModeSettings {}' \
          'property ModeSettings test: ModeSettings {}
              property ModeSettings kiosk: ModeSettings {}'

      # Colours: ctOS' neutral greys become the palette's blue-tinted ones, its light-grey
      # blocks the blue accent, and its green "success" the accent as well.
      substituteInPlace common/Theme.qml \
        --replace-fail '"#ffffff"' '"${hex "base07"}"' \
        --replace-fail '"#CACACA"' '"${hex "base06"}"' \
        --replace-fail '"#D9D9D9"' '"${hex "base0D"}"' \
        --replace-fail '"#c3c3c3"' '"${hex "base05"}"' \
        --replace-fail '"#7a7a7a"' '"${hex "base04"}"' \
        --replace-fail '"#202020"' '"${hex "base01"}"' \
        --replace-fail '"#0E0E0E"' '"${hex "base00"}"' \
        --replace-fail '"#1bfd9c"' '"${hex "base0D"}"' \
        --replace-fail '"#fc3e38"' '"${hex "base08"}"'
      substituteInPlace greeter/components/Time.qml \
        --replace-fail '"#414141"' '"${hex "base03"}"' \
        --replace-fail '"#B1B1B1"' '"${hex "base05"}"'
      substituteInPlace greeter/views/Locker.qml \
        --replace-fail '"#ff0e0e0e"' '"#ff${c.base00}"'
      # The same colours inside the pictures (logo, barcodes, ID card).
      for f in greeter/resources/*.svg; do
        sed -i -e 's/#0[eE]0[eE]0[eE]/${hex "base00"}/g' \
               -e 's/#505050/${hex "base03"}/g' \
               -e 's/#[eE][eE][eE][eE][eE][eE]\|#[eE]6[eE]6[eE]6/${hex "base06"}/g' \
               -e 's/#[bB]6[bB]6[bB]6\|#CACACA\|#cdcdcd/${hex "base05"}/g' \
               -e 's/#D9D9D9/${hex "base0D"}/g' "$f"
      done
    '';

    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/ctos
      cp -r common greeter greeter.qml $out/share/ctos/
    '';

    # A font setup with only the greeter's font, for CI's headless test.
    passthru.fontsConf = pkgs.makeFontsConf { fontDirectories = [ pkgs.nerd-fonts.jetbrains-mono ]; };

    meta.license = lib.licenses.gpl3Only;
  };

  # What greetd runs: cage shows one full-screen window, ctOS in kiosk mode. The greeter user
  # has no home, so Quickshell keeps its cache in ctOS' state dir.
  greeter = pkgs.writeShellScript "ctos-greeter" ''
    export CTOS_MODE=kiosk
    export HOME=/var/lib/ctos
    export XDG_CACHE_HOME=/var/lib/ctos/cache
    exec ${lib.getExe pkgs.cage} -d -s -m last -- \
      ${lib.getExe pkgs.quickshell} --path ${ctos}/share/ctos/greeter.qml
  '';
in
{
  options.my.ctosGreeter.enable = lib.mkEnableOption "the ctOS login screen (tuigreet when off)" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    services.greetd.settings.default_session.command = "${greeter}";

    # For CI's greeter test (.github/workflows/ci.yml), which starts it headless.
    system.build.ctosGreeter = ctos;

    # Read from /etc/ctos/greeter.config.json (the path is fixed upstream). Animations are on in
    # every mode; "reduced" or "none" tone them down.
    environment.etc."ctos/greeter.config.json".text = builtins.toJSON {
      general = {
        fontFamily = "JetBrainsMono Nerd Font";
        animations = "all";
        monitor = ""; # empty: the screen cage shows
        exitOverride = [ ];
        launchOverride = [ ];
        modes = lib.genAttrs [ "greetd" "lockd" "test" "kiosk" ] (_: {
          animations = "all";
          monitor = "";
        });
      };
    };

    # The font ctOS is designed around, installed system-wide so the greeter user has it too.
    fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

    # The state file must exist: ctOS quits (one second after start) when a config file it reads
    # is missing. `f` creates it once with an empty JSON object and never overwrites it.
    systemd.tmpfiles.rules = [
      "d /var/lib/ctos 0750 greeter greeter - -"
      "d /var/lib/ctos/cache 0750 greeter greeter - -"
      "f /var/lib/ctos/greeter.state.json 0640 greeter greeter - {}"
    ];
  };
}
