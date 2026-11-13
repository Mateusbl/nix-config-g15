# Python: pyright + ruff (from the project's devenv), debugpy via dap-python, pytest via neotest.
{ config, lib, ... }:

let
  cfg = config.my.neovim;
in
{
  programs.nixvim = lib.mkIf cfg.languages.python.enable {
    plugins.lsp.servers = {
      pyright = {
        enable = true;
        package = null;
      };
      ruff = {
        enable = true;
        package = null;
      };
    };

    plugins.conform-nvim.settings.formatters_by_ft.python = [
      "ruff_organize_imports"
      "ruff_format"
    ];

    plugins.dap-python.enable = cfg.debug.enable;
    plugins.neotest.adapters.python.enable = cfg.test.enable;
  };
}
