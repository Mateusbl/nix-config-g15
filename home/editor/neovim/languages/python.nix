# Python: pyright + ruff (from the project's devenv), debugpy via dap-python, pytest via neotest.
{ config, lib, ... }:

let
  cfg = config.my.neovim;
in
{
  options.my.neovim.languages.python.testRunner = lib.mkOption {
    type = lib.types.enum [
      "pytest"
      "django"
    ];
    default = "pytest";
    description = ''
      How Python tests are run (neotest and dap-python's test_method/test_class).
      "django" uses Django's own runner (manage.py test) instead of pytest.
    '';
  };

  config.programs.nixvim = lib.mkIf cfg.languages.python.enable {
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

    plugins.dap-python = {
      enable = cfg.debug.enable;
      # nixvim's default is a Nix-built python3 + debugpy, i.e. a project toolchain in
      # the editor. lang_python.lua replaces the adapter command with the project's
      # python anyway, so only a plain name is given here (nothing gets installed).
      adapterPythonPath = "python3";
      # A Lua expression (this option takes Lua code), hence the inner quotes.
      testRunner = ''"${cfg.languages.python.testRunner}"'';
    };
    plugins.neotest.adapters.python = {
      enable = cfg.test.enable;
      settings = {
        runner = cfg.languages.python.testRunner;
        # The project's interpreter (devshell), not the one Neovim was started with.
        python.__raw = ''
          function() return require("lang_python").python(0) or "python3" end
        '';
        dap.justMyCode = false;
      };
    };

    extraFiles."lua/lang_python.lua".source = ../lua/lang_python.lua;

    # Start the servers/formatters from the project's devenv (lua/devshell.lua).
    extraConfigLuaPost = ''
      local devshell = require("devshell")
      devshell.wrap_lsp("pyright")
      devshell.wrap_lsp("ruff")
      devshell.conform("ruff_format")
      devshell.conform("ruff_organize_imports")
      require("lang_python").setup_dap()
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
