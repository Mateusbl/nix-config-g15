# Completion menu (blink.cmp) and snippets.
{ ... }:

{
  programs.nixvim = {
    plugins = {
      # --- Completion ---
      friendly-snippets.enable = true;
      blink-cmp = {
        enable = true;
        settings = {
          keymap.preset = "enter";
          appearance = {
            use_nvim_cmp_as_default = false;
            nerd_font_variant = "mono";
          };
          completion = {
            accept.auto_brackets.enabled = true;
            menu.draw.treesitter = [ "lsp" ];
            documentation = {
              auto_show = true;
              auto_show_delay_ms = 200;
            };
          };
          sources.default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
          ];
        };
      };
    };
  };
}
