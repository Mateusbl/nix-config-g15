# Devshell contract

Neovim provides the editor and a few language-agnostic tools. Everything that depends on a
project's versions (JDK, Python, Node, language servers, formatters, debuggers and test
runners) comes from that project's **direnv** environment, usually a devenv.

This page lists what each kind of project must provide so that Neovim can use it.

## How Neovim finds the tools

`home/editor/neovim/lua/devshell.lua` does this for every project tool:

1. Find the nearest `.envrc` above the file.
2. If it is allowed, load its environment once (`direnv export json`) and cache it per
   directory. Two projects in one Neovim session therefore each get their own environment.
3. Look the tool up on that environment's `PATH` (JavaScript tools look in
   `node_modules/.bin` first), and start it with that environment.
4. If there is no `.envrc`, or it is not allowed, Neovim's own `PATH` is used. A blocked
   `.envrc` is reported once with a "run `direnv allow`" hint. Neovim never allows an
   `.envrc` by itself.

When a tool is missing you get one message, e.g. `jdtls not found in this project's devenv`.
`:DevshellStatus` (or `<leader>cD`) shows the `.envrc` state and, for the current filetype,
every expected tool with its path and version. After changing `devenv.nix`, run `:DevshellReload`
(saving `.envrc` / `devenv.nix` from Neovim does it for you), then `:lsp restart`.

### `.envrc` for devenv

```bash
#!/usr/bin/env bash
eval "$(devenv direnvrc)"
use devenv
```

Then run `direnv allow` once in the project directory.

## Environment variables

Some tools are jars or scripts, not programs on `PATH`. nixpkgs ships them, and the project
points at them with these variables:

| Variable             | Used for                         | Value                                                                                                      |
| -------------------- | -------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `JDTLS_DEBUG_BUNDLE` | Java debugging (jdtls plugin)    | `com.microsoft.java.debug.plugin-*.jar`: a file, a directory of jars, or a glob                            |
| `JDTLS_TEST_BUNDLES` | Java test running/debugging      | vscode-java-test server jars, `:`-separated; each a file, directory or glob                                |
| `JDTLS_LOMBOK_JAR`   | Lombok support in jdtls          | path to `lombok.jar` (passed as `-javaagent`)                                                              |
| `JUNIT_CONSOLE_JAR`  | Java tests through neotest       | path to `junit-platform-console-standalone-*.jar` (neotest-java would otherwise download it at runtime)    |
| `JS_DEBUG_PATH`      | JavaScript/TypeScript debugging  | the `js-debug` program, its directory, or `dapDebugServer.js`. Without it, `js-debug` on `PATH` is used    |

## Editor-owned tools (nothing to provide)

These come with Neovim and work everywhere, inside or outside a devshell:
nil, nixfmt, lua-language-server, stylua.

## Stacks

### java-spring (Maven or Gradle)

| Needed                    | Binary / variable                                   | nixpkgs package                                 |
| ------------------------- | --------------------------------------------------- | ----------------------------------------------- |
| JDK                       | `java`, `JAVA_HOME`                                 | `jdk21` (or the version you build with)         |
| Build tool                | `mvn` / `gradle` (or the project's `./mvnw`, `./gradlew`) | `maven`, `gradle`                         |
| Language server           | `jdtls`                                             | `jdt-language-server`                           |
| Formatter (optional)      | `google-java-format`                                | `google-java-format`                            |
| Debugging                 | `JDTLS_DEBUG_BUNDLE`                                | `vscode-extensions.vscjava.vscode-java-debug`   |
| Test running              | `JDTLS_TEST_BUNDLES`                                | `vscode-extensions.vscjava.vscode-java-test`    |
| Lombok (if the code uses it) | `JDTLS_LOMBOK_JAR`                               | `lombok`                                        |
| neotest runner            | `JUNIT_CONSOLE_JAR`                                 | `fetchurl` from Maven Central (not in nixpkgs)  |

```nix
# devenv.nix
{ pkgs, ... }:

let
  ext = pkgs.vscode-extensions.vscjava;
in
{
  languages.java = {
    enable = true;
    jdk.package = pkgs.jdk21;
    maven.enable = true; # or: gradle.enable = true;
    # lsp.enable defaults to true and adds jdt-language-server (`jdtls`).
  };

  packages = [ pkgs.google-java-format ];

  env = {
    JDTLS_DEBUG_BUNDLE = "${ext.vscode-java-debug}/share/vscode/extensions/vscjava.vscode-java-debug/server";
    JDTLS_TEST_BUNDLES = "${ext.vscode-java-test}/share/vscode/extensions/vscjava.vscode-java-test/server";
    JDTLS_LOMBOK_JAR = "${pkgs.lombok}/share/java/lombok.jar";
    # For neotest (<leader>tt, <leader>tr). Same version/hash neotest-java pins.
    JUNIT_CONSOLE_JAR = "${pkgs.fetchurl {
      url = "https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/1.10.1/junit-platform-console-standalone-1.10.1.jar";
      sha256 = "b42eaa53d13576d17db5fb8b280722a6ae9e36daf95f4262bc6e96d4cb20725f";
    }}";
  };
}
```

### django (Django / DRF)

| Needed               | Binary                                   | nixpkgs package / source                       |
| -------------------- | ---------------------------------------- | ---------------------------------------------- |
| Python               | `python`                                 | `python312` (+ the project's venv)             |
| Language server      | `pyright` (`pyright-langserver`)         | `pyright`                                      |
| Lint + format        | `ruff`                                   | `ruff`                                         |
| Debugging            | `python -m debugpy`                      | `debugpy` in the project's Python              |
| Tests                | `python -m pytest`                       | `pytest` (+ `pytest-django`) in the project's Python |
| Template formatting (optional) | `djlint`                       | `djlint`                                       |

Tests run with pytest by default. For Django's own runner (`manage.py test`), set
`my.neovim.languages.python.testRunner = "django";` in `home/default.nix`.

`debugpy` and `pytest` must be importable by the project's `python`. They are not separate
programs. Either add them to the venv (`uv add --dev debugpy pytest pytest-django`) or
build the interpreter with them:

```nix
# devenv.nix
{ pkgs, ... }:

{
  languages.python = {
    enable = true;
    package = pkgs.python312.withPackages (ps: [
      ps.django
      ps.djangorestframework
      ps.debugpy
      ps.pytest
      ps.pytest-django
    ]);
    # lsp.enable defaults to true and adds pyright.
  };

  packages = [ pkgs.ruff ];

  # Anything the app reads at runtime is visible to tests and the debugger too:
  env.DJANGO_SETTINGS_MODULE = "config.settings";
}
```

With uv instead: `languages.python = { enable = true; uv.enable = true; uv.sync.enable = true; venv.enable = true; };`
and keep Django, debugpy and pytest in `pyproject.toml`.

### fastapi

Same as Django, without the template tooling:

```nix
# devenv.nix
{ pkgs, ... }:

{
  languages.python = {
    enable = true;
    package = pkgs.python312.withPackages (ps: [
      ps.fastapi
      ps.uvicorn
      ps.debugpy
      ps.pytest
      ps.httpx
    ]);
  };

  packages = [ pkgs.ruff ];
}
```

### react-vite (TypeScript, Tailwind)

| Needed               | Binary                                       | Source                                                     |
| -------------------- | -------------------------------------------- | ---------------------------------------------------------- |
| Node + package manager | `node`, `npm`/`pnpm`                       | `nodejs_22`, devenv `languages.javascript`                 |
| TypeScript server    | `vtsls`                                      | `vtsls`; it uses the project's `node_modules/typescript`   |
| ESLint server        | `vscode-eslint-language-server`              | `vscode-langservers-extracted`; eslint itself from `node_modules` |
| Formatter            | `prettier` (or `biome`)                      | the project's `node_modules/.bin` first, then `prettier`/`biome` from devenv |
| Tailwind server      | `tailwindcss-language-server`                | `tailwindcss-language-server`                              |
| Debugging            | `js-debug` / `JS_DEBUG_PATH`                 | `vscode-js-debug`                                          |
| Tests                | `vitest` / `jest`                            | the project's `node_modules`                               |

```nix
# devenv.nix
{ pkgs, ... }:

{
  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_22;
    npm.enable = true;
    npm.install.enable = true; # runs `npm install` when the shell starts
    lsp.enable = false; # Neovim uses vtsls (below), not typescript-language-server
  };

  packages = [
    pkgs.vtsls
    pkgs.vscode-langservers-extracted # vscode-eslint-language-server
    pkgs.tailwindcss-language-server
    pkgs.vscode-js-debug # js-debug
  ];
}
```

`prettier`, `eslint`, `typescript` and `vitest` should be `devDependencies` of the project, so
the versions match CI.
