# TypeScript/JavaScript (React, Vite) and Tailwind. Servers come from the project's devenv.
# HTML/CSS servers are editor-owned and live in config-files.nix.
{ config, lib, ... }:

let
  cfg = config.my.neovim;
  # Project formatter: biome when the project has biome.json, otherwise prettier
  # (node_modules/.bin first, then the devshell). See config-files.nix for both.
  projectFirst = {
    __unkeyed-1 = "biome";
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
            # Use the project's node_modules/typescript, i.e. the same tsc version as CI.
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
      eslint = {
        enable = true;
        package = null;
      };
      # Class completion and hover. Colour swatches come from Neovim 0.12's built-in
      # LSP document colours (vim.lsp.document_color, on by default).
      tailwindcss = {
        enable = true;
        package = null;
      };
    };

    plugins.conform-nvim.settings.formatters_by_ft = {
      javascript = projectFirst;
      typescript = projectFirst;
      javascriptreact = projectFirst;
      typescriptreact = projectFirst;
    };

    plugins.neotest.adapters = lib.mkIf cfg.test.enable {
      jest.enable = true;
      vitest.enable = true;
    };

    extraFiles."lua/lang_web.lua".source = ../lua/lang_web.lua;

    # Start the servers/formatters from the project (node_modules, then devenv).
    extraConfigLuaPost = ''
      local devshell = require("devshell")
      for _, server in ipairs({ "vtsls", "eslint", "tailwindcss" }) do
        devshell.wrap_lsp(server)
      end
      require("lang_web").setup_dap() -- js-debug from the devshell
      devshell.register({ "javascript", "javascriptreact", "typescript", "typescriptreact" }, {
        { bin = "node", what = "runtime" },
        { bin = "vtsls", what = "TypeScript language server", version = false },
        { bin = "vscode-eslint-language-server", what = "ESLint language server", version = false },
        { bin = "tailwindcss-language-server", what = "Tailwind language server", version = false },
        { bin = "prettier", what = "formatter", node = true },
        { bin = "biome", what = "formatter (if biome.json)", node = true },
        { bin = "js-debug", what = "debug adapter", version = false },
      }, { "JS_DEBUG_PATH" })
    '';
  };
}
