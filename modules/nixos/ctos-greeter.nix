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
# The texts it shows are real: upstream's are made up (a fictional company, an Australian region,
# random IDs), here they say who you are and which machine, NixOS and kernel this is. They come
# from this config at build time. Upstream's logos are kept.
#
# Using it: the screen types out a short boot sequence, then asks for the password of the first
# normal user (mateus) and starts the first session (Hyprland). Typing commands instead of a
# password: `help`, `users`, `desktops`, `chusr <name>`, `chdesk <name>`.
#
# It is also the lock screen (SUPER+L, SUPER+Escape, idle and suspend): `ctos-lock`, run by
# hypridle (home/lock-idle.nix).
#
# If the login screen ever fails to start: Ctrl+Alt+F2 gives a text login. Setting
# `my.ctosGreeter.enable = false;` brings back tuigreet and hyprlock, and the previous generation
# in the boot menu always has the old login screen. If the lock screen ever froze: Ctrl+Alt+F2,
# log in, run `hyprctl --instance 0 dispatch 'hl.dsp.exec_cmd("ctos-lock")'` to start a new one
# (Hyprland allows a crashed lock screen to be replaced, home/hyprland.nix), then Ctrl+Alt+F1.
{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  cfg = config.my.ctosGreeter;
  c = config.lib.stylix.colors; # hex without '#'
  hex = name: "#${c.${name}}";

  # Where NixOS puts the session entries (Hyprland). ctOS looks in /usr/share, which NixOS has not.
  sessions = "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";

  # The real information shown instead of upstream's made-up texts.
  upper = lib.toUpper;
  font = config.stylix.fonts.sansSerif.name; # the system font, which ctOS is designed around
  fullName = config.users.users.${username}.description;
  host = config.networking.hostName;
  release = config.system.nixos.release;
  kernel = config.boot.kernelPackages.kernel.version;
  region = upper (builtins.replaceStrings [ "/" ] [ "-" ] config.time.timeZone);
  machine = upper cfg.machine;

  # The vertical text on the right edge was drawn into a picture; this one says what this
  # machine is. Qt draws the SVG text with the greeter's font, rotated to run downwards.
  deviceLabel = "${machine} // NIXOS-${release} // LINUX-${kernel}";
  deviceText = pkgs.writeText "device-text.svg" ''
    <svg width="14" height="${
      toString (builtins.stringLength deviceLabel * 8 + 4)
    }" xmlns="http://www.w3.org/2000/svg">
      <text transform="translate(3,0) rotate(90)" font-family="${font}" font-size="11" letter-spacing="1" fill="${hex "base05"}">${deviceLabel}</text>
    </svg>
  '';

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

      # Real information instead of upstream's made-up company, region and random IDs.
      substituteInPlace greeter/components/Disclaimer.qml \
        --replace-fail 'Property of Blume Corp. All usage is' 'Property of ${fullName}. All usage is' \
        --replace-fail 'subject to Sentinel Active Monitoring.' 'logged by systemd-journald.'
      substituteInPlace greeter/components/Terminal.qml \
        --replace-fail 'blume-krn-1.0.8 <> ctOS-1.0.0-a' 'linux-${kernel} <> nixos-${release}'
      substituteInPlace greeter/services/TerminalManager.qml \
        --replace-fail '"[BLUME_IDP]"' '"[PAM]"' \
        --replace-fail '"[SENTINEL]"' '"[PAM]"' \
        --replace-fail 'AU-SOUTH-EAST-2' '${region}' \
        --replace-fail '1B7C5296-469D-4595-AD5D-4E31349CF13F' 'systemd-journald@${host}' \
        --replace-fail ' <-> ADDR_PTR: 0x''${Faker.randomHexString()}' "" \
        --replace-fail 'SID:''${Faker.randomHexString(24)}' 'USER:''${AuthManager.user}' \
        --replace-fail 'Authentication Failed (TraceId: ''${Faker.randomHexString(16)})' 'Authentication failed'
      # The user being authenticated: upstream's lock mode asks for AuthManager.user, which does
      # not exist. In lock mode it is whoever is logged in, at login the user chosen there.
      substituteInPlace greeter/services/AuthManager.qml \
        --replace-fail 'property string _username: SessionManager.activeUser?.username || ""' \
          'property string _username: SessionManager.activeUser?.username || ""
          readonly property string user: Settings.isLockd ? (Quickshell.env("USER") || "") : _username'
      # The ID card shown after login, and the status panel (upstream reads settings that no
      # longer exist, so these were empty).
      substituteInPlace greeter/components/IdentityCard.qml \
        --replace-fail '"EMPID ##"' '"USER"' \
        --replace-fail 'Settings.fakeIdentity.id' '"${upper username}"' \
        --replace-fail 'Settings.fakeIdentity.class' '"WHEEL"' \
        --replace-fail 'Settings.fakeIdentity.fullName' '"${fullName}"'
      substituteInPlace greeter/components/Status.qml \
        --replace-fail 'Settings.fakeStatus.env' '"DESKTOP"' \
        --replace-fail 'Settings.fakeStatus.node' '"${upper host}"'
      # The device text from above (upstream's logos stay as they are).
      cp ${deviceText} greeter/resources/device-text.svg

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
  # has no home, so Quickshell keeps its cache in ctOS' state dir. Without DISPLAY, Quickshell
  # does not look for an X server, so cage never starts Xwayland: a faster start and one less
  # program running on the login screen.
  greeter = pkgs.writeShellScript "ctos-greeter" ''
    export CTOS_MODE=kiosk
    export HOME=/var/lib/ctos
    export XDG_CACHE_HOME=/var/lib/ctos/cache
    exec ${lib.getExe pkgs.cage} -d -s -m last -- \
      env -u DISPLAY QT_QPA_PLATFORM=wayland \
      ${lib.getExe pkgs.quickshell} --path ${ctos}/share/ctos/greeter.qml
  '';

  # The lock screen: the same program in lock mode, in the running session. flock: a second
  # lock request while already locked does nothing instead of starting a second locker.
  ctos-lock = pkgs.writeShellScriptBin "ctos-lock" ''
    exec ${pkgs.util-linux}/bin/flock -n "''${XDG_RUNTIME_DIR:-/tmp}/ctos-lock.lock" \
      env CTOS_MODE=lockd ${lib.getExe pkgs.quickshell} --path ${ctos}/share/ctos/greeter.qml
  '';
in
{
  options.my.ctosGreeter = {
    enable = lib.mkEnableOption "the ctOS login and lock screen (tuigreet and hyprlock when off)" // {
      default = true;
    };
    machine = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "Machine name shown on the login and lock screen.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.greetd.settings.default_session.command = "${greeter}";

    environment.systemPackages = [ ctos-lock ];

    # For CI's greeter test (.github/workflows/ci.yml), which starts it headless.
    system.build.ctosGreeter = ctos;

    # Read from /etc/ctos/greeter.config.json (the path is fixed upstream). Animation settings
    # are upstream's: all of them at login, a shorter set when locking ("all", "reduced" or "none").
    environment.etc."ctos/greeter.config.json".text = builtins.toJSON {
      general = {
        fontFamily = font;
        animations = "all";
        monitor = ""; # empty: the screen cage shows
        exitOverride = [ ];
        launchOverride = [ ];
        modes =
          lib.genAttrs [ "greetd" "test" "kiosk" ] (_: {
            animations = "all";
            monitor = "";
          })
          // {
            lockd = {
              animations = "reduced";
              monitor = "";
            };
          };
      };
    };

    # The state file must exist: ctOS quits (one second after start) when a config file it reads
    # is missing. `f` creates it once with an empty JSON object and never overwrites it. Readable
    # by everyone, because the lock screen runs as you, not as the greeter user.
    systemd.tmpfiles.rules = [
      "d /var/lib/ctos 0755 greeter greeter - -"
      "d /var/lib/ctos/cache 0750 greeter greeter - -"
      "f /var/lib/ctos/greeter.state.json 0644 greeter greeter - {}"
    ];
  };
}
