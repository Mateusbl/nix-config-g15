# Lua module `lang_java`, installed as lua/lang_java.lua next to init.lua (extraFiles), so
# `require("lang_java")` finds it. It is kept as one Nix string so the config is Nix only.
''
  -- lang_java.lua: Java pieces that need the project's environment.
  --
  -- The jars jdtls loads as plugins (debugger, test runner, Lombok) come from the
  -- project's devenv through environment variables. Nix store paths are never written
  -- into the editor config, so each project decides its own versions.
  --   JDTLS_DEBUG_BUNDLE  com.microsoft.java.debug.plugin-*.jar (file, directory or glob)
  --   JDTLS_TEST_BUNDLES  vscode-java-test server jars, ':'-separated (files, directories or globs)
  --   JDTLS_LOMBOK_JAR    lombok.jar, used as a -javaagent
  --   JUNIT_CONSOLE_JAR   junit-platform-console-standalone.jar, used by neotest-java

  local devshell = require("devshell")
  local M = {}

  -- Expand one entry: a directory gives its *.jar files, anything else is globbed.
  local function jars(entry)
    if entry == nil or entry == "" then
      return {}
    end
    local pattern = vim.fn.isdirectory(entry) == 1 and (entry .. "/*.jar") or entry
    return vim.fn.glob(pattern, true, true)
  end

  -- Bundles for jdtls' initializationOptions, from the project at `root`.
  function M.bundles(root)
    local list = {}
    local function add(entry)
      for _, jar in ipairs(jars(entry)) do
        -- Same filter the VS Code Java test extension uses: these jars are not plugins.
        if not jar:match("runner%-jar%-with%-dependencies") and not jar:match("jacocoagent") then
          table.insert(list, jar)
        end
      end
    end
    add(devshell.getenv(root, "JDTLS_DEBUG_BUNDLE"))
    for _, entry in ipairs(vim.split(devshell.getenv(root, "JDTLS_TEST_BUNDLES") or "", ":", { trimempty = true })) do
      add(entry)
    end
    return list
  end

  -- jdtls keeps an index per project ("workspace"). One directory per project root,
  -- named after the folder plus a short hash of the full path, so two projects with the
  -- same folder name do not share (and corrupt) an index.
  function M.workspace_dir(root)
    local name = vim.fs.basename(root) .. "-" .. vim.fn.sha256(root):sub(1, 8)
    return vim.fn.stdpath("cache") .. "/jdtls/workspace/" .. name
  end

  -- Extra jdtls command-line arguments for `root`: workspace, and Lombok if provided.
  function M.extra_args(root)
    local args = { "-data", M.workspace_dir(root) }
    local lombok = devshell.getenv(root, "JDTLS_LOMBOK_JAR")
    if lombok and lombok ~= "" then
      table.insert(args, "--jvm-arg=-javaagent:" .. lombok)
    end
    return args
  end

  function M.setup()
    devshell.wrap_lsp("jdtls", { extra_args = M.extra_args })
    vim.lsp.config("jdtls", {
      -- Runs just before the server is initialised, once per project root.
      before_init = function(params, config)
        params.initializationOptions = params.initializationOptions or {}
        params.initializationOptions.bundles = M.bundles(config.root_dir)
      end,
    })
  end

  -- neotest-java runs tests with junit-platform-console-standalone.jar. Its own
  -- `:NeotestJava setup` downloads that jar at runtime, which this config avoids; the
  -- project provides it in JUNIT_CONSOLE_JAR instead. neotest-java takes the jar path
  -- when the adapter is created, so a fresh adapter with the project's jar is created
  -- for each run (cheap: it is only a table of functions).
  function M.setup_neotest()
    local ok, config = pcall(require, "neotest.config")
    if not ok then
      return
    end
    for _, adapter in ipairs(config.adapters or {}) do
      if adapter.name == "neotest-java" then
        adapter.build_spec = function(args)
          local where = args.tree:data().path
          local jar = devshell.getenv(where, "JUNIT_CONSOLE_JAR")
          if not jar or vim.fn.filereadable(jar) ~= 1 then
            devshell.warn_missing(where, "JUNIT_CONSOLE_JAR (junit-platform-console-standalone.jar)", devshell.get(where))
            return nil
          end
          local fresh = require("neotest-java")({ junit_jar = jar })
          return devshell.neotest(fresh).build_spec(args)
        end
      end
    end
  end

  -- Spring Boot: an overseer task "spring-boot: run" in projects that use Spring Boot.
  -- Uses the project's wrapper (./mvnw, ./gradlew) when present, otherwise mvn/gradle
  -- from the devshell. The task runs inside the devshell (see tasks.nix).
  function M.setup_tasks()
    local ok, overseer = pcall(require, "overseer")
    if not ok then
      return
    end
    overseer.register_template({
      name = "spring-boot",
      generator = function(opts)
        local root = vim.fs.root(opts.dir, { "mvnw", "pom.xml", "gradlew", "build.gradle", "build.gradle.kts" })
        if not root then
          return "Not a Maven/Gradle project"
        end
        local function has(file)
          return vim.uv.fs_stat(root .. "/" .. file) ~= nil
        end
        local function mentions_spring(file)
          return has(file) and table.concat(vim.fn.readfile(root .. "/" .. file), "\n"):find("spring%-boot") ~= nil
        end
        local cmd
        if mentions_spring("pom.xml") then
          cmd = has("mvnw") and { "./mvnw", "spring-boot:run" } or { "mvn", "spring-boot:run" }
        elseif mentions_spring("build.gradle") or mentions_spring("build.gradle.kts") then
          cmd = has("gradlew") and { "./gradlew", "bootRun" } or { "gradle", "bootRun" }
        else
          return "No Spring Boot plugin in the build file"
        end
        return {
          {
            name = "spring-boot: run",
            builder = function()
              return { cmd = cmd, cwd = root }
            end,
          },
        }
      end,
    })
  end

  return M
''
