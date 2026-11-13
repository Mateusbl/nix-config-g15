# Java: nvim-jdtls and the Java-only keymaps it adds on attach.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.neovim;
in
{
  programs.nixvim = lib.mkIf cfg.languages.java.enable {
    autoCmd = [
      {
        # Java: DAP hot-code-replace + refactor/test keymaps once jdtls attaches
        event = [ "LspAttach" ];
        desc = "jdtls DAP and Java keymaps";
        callback.__raw = ''
          function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if not client or client.name ~= "jdtls" then
              return
            end
            local ok, jdtls = pcall(require, "jdtls")
            if not ok then
              return
            end
            jdtls.setup_dap({ hotcodereplace = "auto" })
            pcall(function() require("jdtls.dap").setup_dap_main_class_configs() end)

            local map = function(mode, lhs, rhs, desc)
              vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = desc })
            end
            map("n", "<leader>co", jdtls.organize_imports, "Organize Imports")
            map("n", "<leader>crv", jdtls.extract_variable, "Extract Variable")
            map("v", "<leader>crv", function() jdtls.extract_variable(true) end, "Extract Variable")
            map("n", "<leader>crc", jdtls.extract_constant, "Extract Constant")
            map("v", "<leader>crc", function() jdtls.extract_constant(true) end, "Extract Constant")
            map("v", "<leader>crm", function() jdtls.extract_method(true) end, "Extract Method")
            map("n", "<leader>tc", jdtls.test_class, "Run Test Class (JDTLS)")
            map("n", "<leader>tm", jdtls.test_nearest_method, "Run Nearest Test (JDTLS)")
          end
        '';
      }
    ];
    plugins = {
      # --- Java: nvim-jdtls (server + Java tooling come from the project's devenv shell) ---
      jdtls = {
        enable = true;
        jdtLanguageServerPackage = null; # `package` would be the nvim-jdtls plugin itself, keep it
        settings = {
          cmd = [
            "jdtls"
            "--jvm-arg=-javaagent:${pkgs.lombok}/share/java/lombok.jar"
          ];

          root_dir.__raw = "vim.fs.root(0, { 'gradlew', 'mvnw', 'pom.xml', 'build.gradle', '.git' })";

          init_options.bundles.__raw = ''
            (function()
              local bundles = {}
              local function add_jars(pattern)
                for _, jar in ipairs(vim.split(vim.fn.glob(pattern, true), "\n")) do
                  if jar ~= ""
                    and not jar:match("runner%-jar%-with%-dependencies")
                    and not jar:match("jacocoagent") then
                    table.insert(bundles, jar)
                  end
                end
              end
              add_jars("${pkgs.vscode-extensions.vscjava.vscode-java-debug}/share/vscode/extensions/vscjava.vscode-java-debug/server/com.microsoft.java.debug.plugin-*.jar")
              add_jars("${pkgs.vscode-extensions.vscjava.vscode-java-test}/share/vscode/extensions/vscjava.vscode-java-test/server/*.jar")
              return bundles
            end)()
          '';

          settings.java = {
            inlayHints.parameterNames.enabled = "all";
            autobuild.enabled = true;
            signatureHelp.enabled = true;
            contentProvider.preferred = "fernflower";
            saveActions.organizeImports = true;
            completion.favoriteStaticMembers = [
              "org.hamcrest.MatcherAssert.assertThat"
              "org.hamcrest.Matchers.*"
              "org.junit.jupiter.api.Assertions.*"
              "org.assertj.core.api.Assertions.*"
              "org.mockito.Mockito.*"
              "org.mockito.ArgumentMatchers.*"
              "org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*"
              "org.springframework.test.web.servlet.result.MockMvcResultMatchers.*"
            ];
          };
        };
      };

      neotest.adapters.java.enable = cfg.test.enable;
      conform-nvim.settings.formatters_by_ft.java = [ "google-java-format" ];
    };
  };
}
