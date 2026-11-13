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
  };
}
