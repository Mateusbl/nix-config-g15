# Alt-tab: hyprshell's window switcher. Hold ALT and press TAB to step through the windows,
# most recently used first, with a live preview of each; let go of ALT to switch. SHIFT+TAB goes
# back, and `q` closes the selected window. Only the switcher is turned on: fuzzel stays the
# launcher (SUPER+D).
#
# hyprshell registers its own keys with Hyprland, so ALT+TAB is not listed in hyprland.nix.
{ config, ... }:

let
  c = config.lib.stylix.colors; # the Stylix palette, so the switcher matches the desktop
in
{
  services.hyprshell = {
    enable = true; # a systemd user service, started with the graphical session
    settings = {
      version = 4; # config format version of hyprshell 4.x
      windows.switch = {
        modifier = "alt";
        key = "Tab";
        filter_by = [ ]; # all windows, on every monitor and workspace
      };
    };
    style = ''
      :root {
        --bg-color: #${c.base00}eb;
        --bg-color-hover: #${c.base02};
        --bg-window-color: #${c.base01}d9;
        --border-color: #${c.base03};
        --border-color-active: #${c.base0D};
        --text-color: #${c.base05};
        --border-radius: 8px;
        --border-size: 2px;
      }
    '';
  };
}
