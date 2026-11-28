# Monitors: hyprdynamicmonitors picks a monitor layout ("profile") from what is connected and
# whether the lid is open, and switches it when that changes (plugging in a screen, closing the
# lid). Profiles:
#   laptop         only the built-in panel: 1920x1080 at 120 Hz (also on battery)
#   docked         an external screen and the lid open: the external screen on the left at its
#                  highest refresh rate, the panel to its right
#   docked-closed  an external screen and the lid closed: only the external screen
# Screens not covered by a profile get their preferred mode (the catch-all rule in hyprland.nix).
#
# How it fits the Lua config: the daemon writes the chosen profile to ~/.config/hypr/monitors.lua,
# hyprland.lua loads that file (extraConfig below), and after every switch the daemon tells
# Hyprland to reload. hyprdynamicmonitors is from nixpkgs; its own flake (with a NixOS module)
# is not used, so the config file and the service are declared here.
#
# `hyprdynamicmonitors tui` shows the connected screens and which profile matches.
#
# Rescue: SUPER+SHIFT+M deletes the generated layout and reloads, so every screen comes back on
# with the catch-all rule (works even when the panel is dark: the keyboard still works). The next
# change (plugging, lid) makes the daemon pick a profile again.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  destination = "${config.xdg.configHome}/hypr/monitors.lua";

  # Profiles are Go templates (filled in with the connected screens' names) that produce Lua.
  laptop = ''
    {{- $laptop := index .MonitorsByTag "laptop" -}}
    hl.monitor({ output = "{{ $laptop.Name }}", mode = "1920x1080@120", position = "0x0", scale = 1 })
  '';

  docked = ''
    {{- $laptop := index .MonitorsByTag "laptop" -}}
    {{- $external := index .MonitorsByTag "external" -}}
    hl.monitor({ output = "{{ $external.Name }}", mode = "highrr", position = "0x0", scale = 1 })
    hl.monitor({ output = "{{ $laptop.Name }}", mode = "1920x1080@120", position = "auto-right", scale = 1 })
  '';

  # The panel is switched off only if another screen is really connected right now. This file
  # stays in place after logout, and Hyprland cannot start with every screen off: if the laptop
  # boots without the external screen, the panel stays on until the daemon picks "laptop".
  # (hyprdynamicmonitors' own `prepare` command does this for the classic config format only.)
  dockedClosed = ''
    {{- $laptop := index .MonitorsByTag "laptop" -}}
    {{- $external := index .MonitorsByTag "external" -}}
    hl.monitor({ output = "{{ $external.Name }}", mode = "highrr", position = "0x0", scale = 1 })
    local other_screens = 0
    for _, monitor in ipairs(hl.get_monitors({ all = true })) do
      if monitor.name ~= "{{ $laptop.Name }}" then
        other_screens = other_screens + 1
      end
    end
    if other_screens > 0 then
      hl.monitor({ output = "{{ $laptop.Name }}", disabled = true })
    end
  '';

  panel = {
    name = "eDP-1";
    monitor_tag = "laptop";
  };
  # Any external connector (HDMI or DisplayPort/USB-C).
  external = {
    name = "^(HDMI|DP)-.*";
    match_name_using_regex = true;
    monitor_tag = "external";
  };

  monitors-reset = pkgs.writeShellApplication {
    name = "monitors-reset";
    runtimeInputs = with pkgs; [
      coreutils
      libnotify
    ];
    # hyprctl comes with Hyprland (system profile), already on PATH in the session.
    text = ''
      rm -f "${destination}"
      hyprctl reload
      notify-send "Monitors reset" "All screens on with their preferred mode"
    '';
  };

  settings = {
    general = {
      inherit destination;
      debounce_time_ms = 1500;
      # Make Hyprland re-read hyprland.lua (and with it the new monitors.lua) and re-apply the
      # monitor rules.
      post_apply_exec = "hyprctl reload";
    };
    profiles = {
      laptop = {
        config_file = "${pkgs.writeText "laptop.lua.tmpl" laptop}";
        config_file_type = "template";
        conditions.required_monitors = [ panel ];
      };
      docked = {
        config_file = "${pkgs.writeText "docked.lua.tmpl" docked}";
        config_file_type = "template";
        conditions = {
          lid_state = "Opened";
          required_monitors = [
            panel
            external
          ];
        };
      };
      docked-closed = {
        config_file = "${pkgs.writeText "docked-closed.lua.tmpl" dockedClosed}";
        config_file_type = "template";
        conditions = {
          lid_state = "Closed";
          required_monitors = [
            panel
            external
          ];
        };
      };
    };
  };
in
{
  home.packages = [
    pkgs.hyprdynamicmonitors # for `hyprdynamicmonitors tui`
    monitors-reset
  ];

  wayland.windowManager.hyprland.settings.bind = [
    ((import ./lib/hyprland-bind.nix { inherit lib; }).bindCall "SUPER + SHIFT + M"
      ''hl.dsp.exec_cmd("monitors-reset")''
    )
  ];

  xdg.configFile."hyprdynamicmonitors/config.toml".source =
    (pkgs.formats.toml { }).generate "hyprdynamicmonitors.toml"
      settings;

  # Started with the graphical session, like the bar. Lid events come from UPower. Power events
  # (AC / battery) are off: no profile depends on them, the panel stays at 120 Hz either way.
  systemd.user.services.hyprdynamicmonitors = {
    Unit = {
      Description = "Switch the monitor layout when screens or the lid change";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.hyprdynamicmonitors}/bin/hyprdynamicmonitors run --enable-lid-events --disable-power-events";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # hyprland.lua loads the layout the daemon chose, if there is one yet (the first login has
  # none until the daemon starts; the catch-all rule in hyprland.nix covers that moment).
  wayland.windowManager.hyprland.extraConfig = ''
    -- Monitor layout chosen by hyprdynamicmonitors (home/monitors.nix)
    local monitors_file = "${destination}"
    local handle = io.open(monitors_file, "r")
    if handle then
      handle:close()
      dofile(monitors_file)
    end
  '';
}
