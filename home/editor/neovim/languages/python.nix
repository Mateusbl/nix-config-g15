# Python: pyright + ruff (from the project's devenv), debugpy via dap-python, pytest via neotest.
# pyright, not basedpyright: it is what devenv's languages.python.lsp installs by default
# and what VS Code's Pylance is built on (see docs/neovim-decisions.md).
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

    plugins.conform-nvim.settings.formatters_by_ft = {
      # ruff does both: sort imports, then format (it is also the linter, via its LSP).
      python = [
        "ruff_organize_imports"
        "ruff_format"
      ];
      # Django templates. Neovim detects them as `htmldjango`; the html server (config-files.nix)
      # also attaches. djlint is optional and comes from the project.
      htmldjango = [ "djlint" ];
    };

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

    extraFiles."lua/lang_python.lua".text = import ../lua/lang_python.nix;

    # Start the servers/formatters from the project's devenv (lua/devshell.nix).
    extraConfigLuaPost = ''
      local devshell = require("devshell")
      devshell.wrap_lsp("pyright")
      devshell.wrap_lsp("ruff")
      devshell.conform("ruff_format")
      devshell.conform("ruff_organize_imports")
      devshell.conform("djlint", { warn_ft = {} }) -- optional: never warn
      require("lang_python").setup_dap()
      devshell.register({ "python" }, {
        { bin = "python", what = "interpreter" },
        { bin = "pyright", what = "type checker / language server" },
        { bin = "ruff", what = "linter + formatter" },
        { bin = "python", what = "debugpy", version = { "-c", "import debugpy; print('debugpy', debugpy.__version__)" } },
        { bin = "python", what = "pytest", version = { "-m", "pytest", "--version" } },
      })
      devshell.register({ "htmldjango" }, {
        { bin = "djlint", what = "template formatter (optional)" },
      })
    '';
  };
}
