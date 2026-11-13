# Lua, JSON and YAML.
{ pkgs, ... }:

let
  # conform: use the first formatter that is available instead of running both
  prettier = {
    __unkeyed-1 = "prettierd";
    __unkeyed-2 = "prettier";
    stop_after_first = true;
  };
in
{
  programs.nixvim = {
    plugins.lsp.servers = {
      lua_ls.enable = true;
      jsonls = {
        enable = true;
        package = null;
      };
      yamlls = {
        enable = true;
        package = null;
      };
    };

    plugins.conform-nvim.settings.formatters_by_ft = {
      lua = [ "stylua" ];
      json = prettier;
      yaml = prettier;
    };

    extraPackages = [ pkgs.stylua ];
  };
}
