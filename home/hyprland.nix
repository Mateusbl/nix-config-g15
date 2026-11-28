{
  lib,
  ...
}:

{
  # Hyprland (Lua config; the binary comes from the system module, modules/nixos/desktop.nix)
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    package = null;
    portalPackage = null;
    # Session services without UWSM: when Hyprland starts, home-manager imports the environment
    # into systemd and starts hyprland-session.target, which pulls in graphical-session.target and
    # with it ashell, hypridle, hyprpaper, cliphist, ...; when Hyprland exits, it stops them again.
    # "--all" imports the whole environment (PATH included), as UWSM did, so commands the
    # services run (brightnessctl, hyprctl, ...) are found.
    systemd = {
      enable = true;
      variables = [ "--all" ];
    };

    settings = {
      # hl.env("LIBVA_DRIVER_NAME", "iHD")
      env = [
        {
          _args = [
            "LIBVA_DRIVER_NAME"
            "iHD"
          ];
        }
      ];

      # hl.monitor({ ... }): only the catch-all for screens without a rule. The real layouts
      # (laptop, docked, lid closed) come from hyprdynamicmonitors (home/monitors.nix).
      monitor = [
        {
          output = "";
          mode = "preferred";
          position = "auto";
          scale = 1;
        }
      ];

      # hl.config({ ... })
      config = {
        input = {
          kb_layout = "us";
          # US keys with accents on AltGr (right Alt): AltGr+, = ç, AltGr+' then a = á,
          # AltGr+~ then a = ã. Plain ' and " still type at once, which matters for code.
          kb_variant = "altgr-intl";
          follow_mouse = 1;
          touchpad.natural_scroll = true;
        };

        general = {
          gaps_in = 4;
          gaps_out = 8;
          border_size = 2;
          layout = "dwindle";
        };

        decoration = {
          rounding = 6;
        };
      };

      # hl.gesture({ fingers, direction, action }): swipe three fingers left/right on the
      # touchpad to change workspace.
      gesture = [
        {
          fingers = 3;
          direction = "horizontal";
          action = "workspace";
        }
      ];

      # hl.window_rule({ name, match, <effects> })
      # Small utility windows float in the middle of the screen instead of being tiled like an
      # editor or a browser. `class` is a regular expression on the window's app id (the name in
      # the app's .desktop file; `hyprctl clients` shows it for open windows).
      window_rule = [
        {
          # Mixer, Bluetooth and file dialogs: terminal apps started with
          # `ghostty --class=tui.<name>` (home/session.nix, home/bar.nix).
          name = "float-terminal-tools";
          match.class = "^tui\\..*$";
          float = true;
          center = true;
          size = "1000 650";
        }
      ];

      # hl.bind(key, dispatcher, opts)
      bind =
        let
          # Shared helpers, also used by desktop-extras.nix (home/lib/hyprland-bind.nix)
          inherit (import ./lib/hyprland-bind.nix { inherit lib; }) bindCall bindOpts;
        in
        [
          # Launchers & session
          (bindCall "SUPER + Return" ''hl.dsp.exec_cmd("ghostty")'')
          (bindCall "SUPER + Q" "hl.dsp.window.close()")
          (bindCall "SUPER + M" "hl.dsp.exit()") # log out
          (bindCall "SUPER + E" ''hl.dsp.exec_cmd("ghostty -e yazi")'') # file manager
          (bindCall "SUPER + D" ''hl.dsp.exec_cmd("fuzzel")'')
          (bindCall "SUPER + V" ''hl.dsp.window.float({ action = "toggle" })'')
          (bindCall "SUPER + F" "hl.dsp.window.fullscreen()")

          # Alt-tab: a fuzzel list of the windows, most recently used first (desktop-scripts.nix)
          (bindCall "ALT + Tab" ''hl.dsp.exec_cmd("window-pick")'')

          # Screenshots: region to clipboard; Shift = region to file; Ctrl = full screen to file
          (bindCall "Print" ''hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy")'')
          (bindCall "SHIFT + Print" ''hl.dsp.exec_cmd("screenshot region")'')
          (bindCall "CTRL + Print" ''hl.dsp.exec_cmd("screenshot full")'')

          # Clipboard history
          (bindCall "SUPER + SHIFT + V" ''hl.dsp.exec_cmd("clipboard-pick")'')

          # Emoji picker: types the chosen emoji and also copies it
          (bindCall "SUPER + period" ''hl.dsp.exec_cmd("emoji-pick")'')

          # Focus
          (bindCall "SUPER + H" ''hl.dsp.focus({ direction = "left" })'')
          (bindCall "SUPER + L" ''hl.dsp.focus({ direction = "right" })'')
          (bindCall "SUPER + K" ''hl.dsp.focus({ direction = "up" })'')
          (bindCall "SUPER + J" ''hl.dsp.focus({ direction = "down" })'')

          # Move windows
          (bindCall "SUPER + SHIFT + H" ''hl.dsp.window.move({ direction = "left" })'')
          (bindCall "SUPER + SHIFT + L" ''hl.dsp.window.move({ direction = "right" })'')
          (bindCall "SUPER + SHIFT + K" ''hl.dsp.window.move({ direction = "up" })'')
          (bindCall "SUPER + SHIFT + J" ''hl.dsp.window.move({ direction = "down" })'')
          # Lock and power
          (bindCall "SUPER + Escape" ''hl.dsp.exec_cmd("loginctl lock-session")'')
          # Power menu (lock/suspend/reboot/poweroff/logout); needs an explicit choice.
          (bindCall "SUPER + SHIFT + Escape" ''hl.dsp.exec_cmd("power-menu")'')

          # Resize (repeating)
          (bindOpts "SUPER + CTRL + H" "hl.dsp.window.resize({ x = -40, y = 0, relative = true })" {
            repeating = true;
          })
          (bindOpts "SUPER + CTRL + L" "hl.dsp.window.resize({ x = 40, y = 0, relative = true })" {
            repeating = true;
          })
          (bindOpts "SUPER + CTRL + K" "hl.dsp.window.resize({ x = 0, y = -40, relative = true })" {
            repeating = true;
          })
          (bindOpts "SUPER + CTRL + J" "hl.dsp.window.resize({ x = 0, y = 40, relative = true })" {
            repeating = true;
          })

          # Workspaces 1-10 (key 0 is workspace 10): SUPER+n goes there, SUPER+SHIFT+n moves the window.
        ]
        ++ lib.concatMap (
          n:
          let
            key = toString (lib.mod n 10);
            ws = toString n;
          in
          [
            (bindCall "SUPER + ${key}" "hl.dsp.focus({ workspace = ${ws} })")
            (bindCall "SUPER + SHIFT + ${key}" "hl.dsp.window.move({ workspace = ${ws} })")
          ]
        ) (lib.range 1 10)
        ++ [
          # Volume & brightness keys (work when locked, repeat when held). ashell changes the value
          # and shows it in its on-screen display (osd settings in home/session.nix).
          (bindOpts "XF86AudioRaiseVolume" ''hl.dsp.exec_cmd("ashell msg volume-up")'' {
            locked = true;
            repeating = true;
          })
          (bindOpts "XF86AudioLowerVolume" ''hl.dsp.exec_cmd("ashell msg volume-down")'' {
            locked = true;
            repeating = true;
          })
          (bindOpts "XF86MonBrightnessUp" ''hl.dsp.exec_cmd("ashell msg brightness-up")'' {
            locked = true;
            repeating = true;
          })
          (bindOpts "XF86MonBrightnessDown" ''hl.dsp.exec_cmd("ashell msg brightness-down")'' {
            locked = true;
            repeating = true;
          })

          # Media keys (go to the last used player, see playerctld in session.nix)
          (bindOpts "XF86AudioPlay" ''hl.dsp.exec_cmd("playerctl play-pause")'' { locked = true; })
          (bindOpts "XF86AudioPause" ''hl.dsp.exec_cmd("playerctl play-pause")'' { locked = true; })
          (bindOpts "XF86AudioNext" ''hl.dsp.exec_cmd("playerctl next")'' { locked = true; })
          (bindOpts "XF86AudioPrev" ''hl.dsp.exec_cmd("playerctl previous")'' { locked = true; })

          # Mute keys
          (bindOpts "XF86AudioMute" ''hl.dsp.exec_cmd("ashell msg volume-toggle-mute")'' {
            locked = true;
          })
          (bindOpts "XF86AudioMicMute" ''hl.dsp.exec_cmd("ashell msg microphone-toggle-mute")'' {
            locked = true;
          })

          # Mouse: drag and resize windows
          (bindOpts "SUPER + mouse:272" "hl.dsp.window.drag()" { mouse = true; })
          (bindOpts "SUPER + mouse:273" "hl.dsp.window.resize()" { mouse = true; })
        ];
    };
  };
}
