# LSP engine: shared keymaps and inlay hints. Servers are enabled in languages/*.nix.
{
  programs.nixvim.plugins.lsp = {
    enable = true;
    inlayHints = true;
    keymaps = {
      diagnostic = {
        "]d" = "goto_next";
        "[d" = "goto_prev";
        "<leader>cd" = "open_float";
      };
      lspBuf = {
        "gd" = "definition";
        "gD" = "declaration";
        "gr" = "references";
        "gI" = "implementation";
        "gy" = "type_definition";
        "K" = "hover";
        "gK" = "signature_help";
        "<leader>ca" = "code_action";
        "<leader>cR" = "rename"; # <leader>cr is the Java refactor group
      };
    };
  };
}
