{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Hyprland (Lua config; binaries come from the system module via UWSM)
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    package = null;
    portalPackage = null;
    systemd.enable = false; # conflicts with UWSM

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

      # hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
      monitor = [
        {
          output = "HDMI-A-1";
          mode = "1920x1080@60";
          position = "0x0";
          scale = 1;
        }
        {
          output = "eDP-1";
          mode = "1920x1080@120";
          position = "1920x0";
          scale = 1;
        }
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

      # hl.bind(key, dispatcher, opts)
      # hl.bind(key, dispatcher, opts)
      bind =
        let
          bindCall = key: dsp: {
            _args = [
              key
              (lib.generators.mkLuaInline dsp)
            ];
          };
          bindOpts = key: dsp: opts: {
            _args = [
              key
              (lib.generators.mkLuaInline dsp)
              opts
            ];
          };
        in
        [
          # Launchers & session
          (bindCall "SUPER + Return" ''hl.dsp.exec_cmd("ghostty")'')
          (bindCall "SUPER + Q" "hl.dsp.window.close()")
          (bindCall "SUPER + M" ''hl.dsp.exec_cmd("uwsm stop")'')
          (bindCall "SUPER + E" ''hl.dsp.exec_cmd("thunar")'')
          (bindCall "SUPER + SHIFT + E" ''hl.dsp.exec_cmd("ghostty -e yazi")'') # terminal file manager
          (bindCall "SUPER + D" ''hl.dsp.exec_cmd("rofi -show drun")'')
          (bindCall "SUPER + V" ''hl.dsp.window.float({ action = "toggle" })'')
          (bindCall "SUPER + F" "hl.dsp.window.fullscreen()")

          # Region screenshot to clipboard
          (bindCall "Print" ''hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy")'')

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
          (bindCall "SUPER + SHIFT + Escape" ''hl.dsp.exec_cmd("systemctl poweroff")'')

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

          # Workspaces 1-5
          (bindCall "SUPER + 1" "hl.dsp.focus({ workspace = 1 })")
          (bindCall "SUPER + 2" "hl.dsp.focus({ workspace = 2 })")
          (bindCall "SUPER + 3" "hl.dsp.focus({ workspace = 3 })")
          (bindCall "SUPER + 4" "hl.dsp.focus({ workspace = 4 })")
          (bindCall "SUPER + 5" "hl.dsp.focus({ workspace = 5 })")
          (bindCall "SUPER + SHIFT + 1" "hl.dsp.window.move({ workspace = 1 })")
          (bindCall "SUPER + SHIFT + 2" "hl.dsp.window.move({ workspace = 2 })")
          (bindCall "SUPER + SHIFT + 3" "hl.dsp.window.move({ workspace = 3 })")
          (bindCall "SUPER + SHIFT + 4" "hl.dsp.window.move({ workspace = 4 })")
          (bindCall "SUPER + SHIFT + 5" "hl.dsp.window.move({ workspace = 5 })")

          # Volume & brightness keys (work when locked, repeat when held)
          (bindOpts "XF86AudioRaiseVolume"
            ''hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+")''
            {
              locked = true;
              repeating = true;
            }
          )
          (bindOpts "XF86AudioLowerVolume" ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")'' {
            locked = true;
            repeating = true;
          })
          (bindOpts "XF86MonBrightnessUp" ''hl.dsp.exec_cmd("brightnessctl set 5%+")'' {
            locked = true;
            repeating = true;
          })
          (bindOpts "XF86MonBrightnessDown" ''hl.dsp.exec_cmd("brightnessctl set 5%-")'' {
            locked = true;
            repeating = true;
          })

          # Mute keys
          (bindOpts "XF86AudioMute" ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")'' {
            locked = true;
          })
          (bindOpts "XF86AudioMicMute" ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")'' {
            locked = true;
          })

          # Mouse: drag and resize windows
          (bindOpts "SUPER + mouse:272" "hl.dsp.window.drag()" { mouse = true; })
          (bindOpts "SUPER + mouse:273" "hl.dsp.window.resize()" { mouse = true; })
        ];
    };
  };
}
