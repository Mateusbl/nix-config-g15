# Config and docs files: Lua, JSON, YAML, TOML, Markdown, shell, Docker, HTML, CSS.
#
# Everything here is editor-owned: installed with Neovim and working inside or outside
# any devshell. The servers' default nixpkgs packages are used (no `package = null`).
{ pkgs, ... }:

let
  # Project formatter first (biome if the project has biome.json, else prettier from
  # node_modules/devshell); if neither exists conform falls back to the language server's
  # own formatting (format_on_save uses lsp_format = "fallback").
  projectFirst = {
    __unkeyed-1 = "biome";
    __unkeyed-2 = "prettier";
    stop_after_first = true;
  };
in
{
  programs.nixvim = {
    plugins.lsp.servers = {
      lua_ls.enable = true;
      jsonls.enable = true; # vscode-langservers-extracted
      yamlls = {
        enable = true; # yaml-language-server
        settings.format.enable = true; # so YAML formats without prettier too
      };
      taplo.enable = true; # TOML: lint + format
      bashls.enable = true; # uses shellcheck from extraPackages for diagnostics
      dockerls.enable = true; # Dockerfile
      docker_compose_language_service.enable = true; # compose.yaml / docker-compose.yml
      marksman.enable = true; # Markdown: links, headings, references
      # HTML/CSS servers ship in the same package as jsonls, so they are editor-owned too.
      html = {
        enable = true;
        filetypes = [
          "html"
          "htmldjango" # Django templates
        ];
      };
      cssls.enable = true;
    };

    # JSON and YAML schemas (package.json, tsconfig, GitHub Actions, compose, ...).
    plugins.schemastore = {
      enable = true;
      json.enable = true;
      yaml.enable = true;
    };

    # Rendered headings, tables, code blocks and checkboxes in Markdown buffers.
    plugins.render-markdown.enable = true;

    plugins.conform-nvim.settings.formatters_by_ft = {
      lua = [ "stylua" ];
      json = projectFirst;
      jsonc = projectFirst;
      yaml = [ "prettier" ];
      markdown = {
        __unkeyed-1 = "prettier";
        __unkeyed-2 = "mdformat"; # editor-owned fallback outside JS projects
        stop_after_first = true;
      };
      html = [ "prettier" ];
      css = projectFirst;
      scss = [ "prettier" ];
      sh = [ "shfmt" ];
      bash = [ "shfmt" ];
      toml = [ "taplo" ];
    };

    extraPackages = with pkgs; [
      stylua
      shellcheck
      shfmt
      mdformat
    ];

    # prettier/biome are project tools; only TypeScript/JavaScript/CSS buffers complain
    # when they are missing (JSON/YAML/Markdown quietly fall back, see above).
    extraConfigLuaPost = ''
      do
        local devshell = require("devshell")
        local web = { "javascript", "javascriptreact", "typescript", "typescriptreact", "css" }
        devshell.conform("prettier", { node = true, warn_ft = web })
        devshell.conform("biome", { node = true, needs_file = { "biome.json", "biome.jsonc" } })
      end
    '';

    keymaps = [
      {
        mode = "n";
        key = "<leader>um";
        action = "<cmd>RenderMarkdown toggle<cr>";
        options.desc = "Toggle Markdown Rendering";
      }
    ];
  };
}
