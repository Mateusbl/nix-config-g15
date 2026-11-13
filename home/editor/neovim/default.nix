# Neovim (nixvim) entry point.
#
# Each file below owns one topic. Language files add their servers, formatters, test
# adapters and debug adapters to the shared engines (lsp.nix, format.nix, test.nix,
# debug.nix), so a language can be switched off in one place.
{ lib, pkgs, ... }:

{
  # Switches for the parts you may want to turn off. They default to on because they
  # were all on before the split; flip one to `false` in home/default.nix if needed.
  options.my.neovim = {
    debug.enable = lib.mkEnableOption "debugging with nvim-dap" // {
      default = true;
    };
    test.enable = lib.mkEnableOption "running tests with neotest" // {
      default = true;
    };
    languages = {
      java.enable = lib.mkEnableOption "Java support (jdtls)" // {
        default = true;
      };
      python.enable = lib.mkEnableOption "Python support (pyright, ruff)" // {
        default = true;
      };
      web.enable = lib.mkEnableOption "TypeScript/JavaScript/HTML/CSS support" // {
        default = true;
      };
    };
  };

  imports = [
    ./options.nix
    ./ui.nix
    ./navigation.nix
    ./keymaps.nix
    ./completion.nix
    ./treesitter.nix
    ./git.nix
    ./lsp.nix
    ./format.nix
    ./debug.nix
    ./test.nix
    ./tasks.nix
    ./devshell.nix
    ./optional.nix
    ./performance.nix
    ./languages/nix.nix
    ./languages/config-files.nix
    ./languages/java.nix
    ./languages/python.nix
    ./languages/web.nix
  ];

  config.programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Editor-level tools stay global; project toolchains live in devenv
    extraPackages = with pkgs; [
      ripgrep
      fd
      fzf
      lazygit
      tree-sitter
    ];
  };
}
