# Helpers for Hyprland key bindings in the Lua config format (home/hyprland.nix and
# home/desktop-extras.nix both use them). This is a plain function file, not a module:
#   inherit (import ./lib/hyprland-bind.nix { inherit lib; }) bindCall bindOpts;
#   (bindCall "SUPER + Q" "hl.dsp.window.close()")
#   (bindOpts "XF86AudioMute" ''hl.dsp.exec_cmd("...")'' { locked = true; })
# Each one becomes hl.bind(key, dispatcher[, opts]) in hyprland.lua.
{ lib }:

{
  bindCall = key: dispatcher: {
    _args = [
      key
      (lib.generators.mkLuaInline dispatcher)
    ];
  };

  bindOpts = key: dispatcher: opts: {
    _args = [
      key
      (lib.generators.mkLuaInline dispatcher)
      opts
    ];
  };
}
