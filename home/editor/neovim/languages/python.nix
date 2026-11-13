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

    # Start the servers/formatters from the project's devenv (lua/devshell.lua).
    extraConfigLuaPost = ''
      local devshell = require("devshell")
      devshell.wrap_lsp("pyright")
      devshell.wrap_lsp("ruff")
      devshell.conform("ruff_format")
      devshell.conform("ruff_organize_imports")
      devshell.register({ "python" }, {
        { bin = "python", what = "interpreter" },
        { bin = "pyright", what = "type checker / language server" },
        { bin = "ruff", what = "linter + formatter" },
        { bin = "python", what = "debugpy", version = { "-c", "import debugpy; print('debugpy', debugpy.__version__)" } },
        { bin = "python", what = "pytest", version = { "-m", "pytest", "--version" } },
      })
    '';
  };
}
