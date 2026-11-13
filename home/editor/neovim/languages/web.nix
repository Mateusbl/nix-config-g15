# TypeScript/JavaScript, HTML, CSS, Tailwind. Servers come from the project's devenv.
{ config, lib, ... }:

let
  cfg = config.my.neovim;
  # conform: use the first formatter that is available instead of running both
  prettier = {
    __unkeyed-1 = "prettierd";
    __unkeyed-2 = "prettier";
    stop_after_first = true;
  };
in
{
  programs.nixvim = lib.mkIf cfg.languages.web.enable {
    plugins.lsp.servers = {
      vtsls = {
        enable = true;
        package = null;
        settings = {
          vtsls = {
            enableMoveToFileCodeAction = true;
            autoUseWorkspaceTsdk = true;
            experimental.completion.enableServerSideFuzzyMatch = true;
          };
          typescript = {
            updateImportsOnFileMove.enabled = "always";
            suggest.completeFunctionCalls = true;
            inlayHints = {
              enumMemberValues.enabled = true;
              functionLikeReturnTypes.enabled = true;
              parameterNames.enabled = "literals";
              parameterTypes.enabled = true;
              propertyDeclarationTypes.enabled = true;
              variableTypes.enabled = false;
            };
          };
        };
      };
      angularls = {
        enable = true;
        package = null;
      };
      eslint = {
        enable = true;
        package = null;
      };
      tailwindcss = {
        enable = true;
        package = null;
      };
      html = {
        enable = true;
        package = null;
      };
      cssls = {
        enable = true;
        package = null;
      };
    };

    plugins.conform-nvim.settings.formatters_by_ft = {
      javascript = prettier;
      typescript = prettier;
      javascriptreact = prettier;
      typescriptreact = prettier;
      html = prettier;
      htmlangular = prettier;
      css = prettier;
      scss = prettier;
    };

    plugins.neotest.adapters = lib.mkIf cfg.test.enable {
      jest.enable = true;
      vitest.enable = true;
    };

    # Start the servers/formatters from the project (node_modules, then devenv).
    extraConfigLuaPost = ''
      local devshell = require("devshell")
      for _, server in ipairs({ "vtsls", "eslint", "tailwindcss", "angularls" }) do
        devshell.wrap_lsp(server)
      end
      devshell.conform("prettierd", { node = true })
      devshell.conform("prettier", { node = true })
      devshell.register({ "javascript", "javascriptreact", "typescript", "typescriptreact" }, {
        { bin = "node", what = "runtime" },
        { bin = "vtsls", what = "TypeScript language server", version = false },
        { bin = "vscode-eslint-language-server", what = "ESLint language server", version = false },
        { bin = "tailwindcss-language-server", what = "Tailwind language server", version = false },
        { bin = "prettier", what = "formatter", node = true },
        { bin = "js-debug", what = "debug adapter", version = false },
      }, { "JS_DEBUG_PATH" })
    '';
  };
}
