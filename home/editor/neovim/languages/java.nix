# Java: nvim-jdtls and the Java-only keymaps it adds on attach.
{
  config,
  lib,
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
            -- Debugger hooks; skipped quietly when nvim-dap is off (my.neovim.debug.enable = false).
            if pcall(require, "dap") then
              jdtls.setup_dap({ hotcodereplace = "auto" })
              pcall(function() require("jdtls.dap").setup_dap_main_class_configs() end)
            end

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
          # Only the binary name: lua/devshell.lua finds it in the project's devenv and
          # adds the Lombok agent and per-project arguments. Root detection comes from
          # nvim-lspconfig (pom.xml, build.gradle, mvnw, gradlew, .git, ...) per buffer.
          cmd = [ "jdtls" ];

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

    # jdtls is project-owned: nixvim would otherwise put jdt-language-server on
    # Neovim's PATH (lsp.servers.jdtls.package defaults to it).
    lsp.servers.jdtls.package = null;

    # Only when the task runner is installed (my.neovim.tasks.enable).
    keymaps = lib.mkIf cfg.tasks.enable [
      {
        mode = "n";
        key = "<leader>os";
        action.__raw = "function() require('overseer').run_task({ name = 'spring-boot: run' }) end";
        options.desc = "Spring Boot: Run";
      }
    ];

    extraFiles."lua/lang_java.lua".source = ../lua/lang_java.lua;

    extraConfigLuaPost = ''
      require("lang_java").setup()
      require("lang_java").setup_neotest()
      require("lang_java").setup_tasks()
      require("devshell").conform("google-java-format")
      require("devshell").register({ "java" }, {
        { bin = "java", what = "JDK", version = { "-version" } },
        { bin = "jdtls", what = "language server", version = false },
        { bin = "mvn", what = "Maven" },
        { bin = "gradle", what = "Gradle", version = false },
        { bin = "google-java-format", what = "formatter" },
      }, { "JAVA_HOME", "JDTLS_DEBUG_BUNDLE", "JDTLS_TEST_BUNDLES", "JDTLS_LOMBOK_JAR", "JUNIT_CONSOLE_JAR" })
    '';
  };
}
