# The bar: ashell. Also the notification daemon (popups and a bell with the history) and the
# on-screen display for the volume and brightness keys.
{
  # Bar: ashell. One program made for Hyprland: workspaces, window title, clock, tray, and a
  # settings panel (click the icons on the right) for volume, Wi-Fi, Bluetooth, brightness,
  # power profile and power actions. Stylix sets its colours (stylix.targets.ashell).
  programs.ashell = {
    enable = true;
    systemd.enable = true; # a session service, like mako and hyprpaper
    settings = {
      position = "Top";
      modules = {
        left = [ "Workspaces" ];
        center = [ "WindowTitle" ];
        # Inner lists are drawn as one group.
        right = [
          "SystemInfo"
          "Tray" # icons of apps that keep running in the background
          [
            "Tempo"
            "Privacy" # shows when the microphone, camera or screen sharing is in use
            "Notifications" # bell: click for the list of notifications, right-click for do not disturb
            "Settings"
          ]
        ];
      };

      # ashell is also the notification daemon: popups in the top-right corner, and the bell in
      # the bar keeps the history (in memory, until logout).
      notifications = {
        toast_position = "TopRight";
        history_limit = 100;
      };

      # On-screen display for the volume, microphone and brightness keys (home/hyprland.nix sends
      # `ashell msg volume-up` and friends): a small bar at the bottom centre.
      osd = {
        enabled = true;
        timeout = 1500;
        show_volume_percentage = true;
        show_brightness_percentage = true;
      };

      # Tempo is the clock; clicking it opens a calendar. No weather: that would ask a web
      # service for the location.
      tempo.clock_format = "%Y-%m-%d %H:%M";

      system_info.indicators = [
        "Cpu"
        "Memory"
        "Temperature"
      ];

      settings = {
        battery_format = "IconAndPercentage";
        volume_step = 5; # per press of a volume key
        max_volume = 150; # allow up to 150%, as before
        # Same commands as power-menu, so both behave alike.
        lock_cmd = "loginctl lock-session";
        suspend_cmd = "systemctl suspend";
        hibernate_cmd = "systemctl hibernate";
        reboot_cmd = "systemctl reboot";
        shutdown_cmd = "systemctl poweroff";
        logout_cmd = "hyprctl dispatch 'hl.dsp.exit()'";
        # Right-click the speaker / Bluetooth button for the full tools.
        audio_sinks_more_cmd = "pwvucontrol";
        audio_sources_more_cmd = "pwvucontrol";
        bluetooth_more_cmd = "overskride";
      };
    };
  };
}
