# Neovim decisions

Non-obvious choices in `home/editor/neovim`, the options that were rejected, and the
questions that only you can answer.

## Devshell layer

**Cached `direnv export json` instead of running `direnv exec` per command.** The brief asked
for every project tool to be launched through `direnv exec <root> <cmd>`. `lua/devshell.lua`
computes the same environment (`direnv export json` in that directory). It does this once per
`.envrc` and reuses it, then starts the tool with it. `direnv exec` pays the direnv startup
cost on every call. With format-on-save (500 ms timeout) that cost would be paid on every
save, and devenv's first evaluation can take seconds. The environment is identical, and
Neovim's own environment is never changed. The cache is dropped by `:DevshellReload`, or
when you save `.envrc`, `devenv.nix`, `devenv.yaml`, `devenv.lock`, `flake.nix`,
`flake.lock` or `shell.nix` from Neovim.

**The launcher replaces direnv.vim.** direnv.vim loads an environment into Neovim itself on
`:cd`. That can only hold one project at a time, and it would load environments a second
time on top of the launcher. Only the launcher is used.

**Environment handling per API.**
- Language servers, formatters and neotest *add* the project's variables to Neovim's
  environment (that is what `vim.lsp.rpc.start`, conform and neotest support).
- nvim-dap replaces the environment entirely, so debug adapters get the complete merged
  environment, including variables that direnv unsets.
- Edge case: if Neovim itself was started inside project A's shell, a variable that only A
  sets stays visible to project B's language servers. `PATH` is always replaced, so the
  right binaries are used either way.

**Language servers keep nvim-lspconfig's root detection.** `wrap_lsp` wraps the server's
existing `root_dir` / `root_markers`. The server only starts (`on_dir`) once its binary is
found in that root's environment. Otherwise you get one message, e.g. `jdtls not found in
this project's devenv`. If an `.envrc` exists but is still loading, the server starts as soon
as it is loaded.

**A blocked `.envrc` is reported, never allowed.** The editor runs `direnv status --json` to
see whether an `.envrc` is allowed. If it is not, it falls back to Neovim's PATH and tells you
to run `direnv allow`.

**`:DevshellStatus` does not run language servers.** Servers such as jdtls or vtsls start
and wait for input when given `--version`, so the status shows their path only. CLIs (java,
python, ruff, prettier, mvn) also show a version.

**Formatter warnings.**
- prettier is only *expected* for JS/TS/CSS. For JSON/YAML/Markdown it is optional, and they
  quietly fall back to the language server or mdformat.
- djlint is entirely optional and never warns.
- On the first save after opening a project, the environment may still be loading. That one
  save uses the language server's formatting.

## Java

- **jdtls `root_dir` bug fixed.** The old config computed `vim.fs.root(0, …)` once at
  startup, so every Java buffer shared the root of the directory Neovim was started in.
  Root detection now comes from nvim-lspconfig, per buffer.
- **Workspace per project.** `-data ~/.cache/nvim/jdtls/workspace/<folder>-<sha256 prefix>`.
  Two projects with the same folder name get different indexes.
- **No Nix store paths in the editor.** The jdtls package (nixvim's default for
  `lsp.servers.jdtls.package`) and the lombok / vscode-java-debug / vscode-java-test jars were
  removed from home-manager. The project provides them (`JDTLS_*` variables, see
  `docs/devshell-contract.md`).
- **neotest-java's JUnit jar comes from `JUNIT_CONSOLE_JAR`.** Its `:NeotestJava setup`
  downloads the jar at runtime, which the rules forbid, and nixpkgs has no package for it.
  The contract shows a `fetchurl` with the hash neotest-java itself pins. neotest-java only
  takes the jar path when an adapter is created, so a fresh adapter (a table of functions) is
  created per run with the project's jar.
- **spring-boot.nvim: not added.** The plugin is in nixpkgs, but it is only a client for the
  Spring Boot language server (STS4, shipped in the `vmware.vscode-spring-boot` VS Code
  extension). That server is not in nixpkgs. The plugin otherwise looks for it in Mason or in
  `~/.vscode/extensions`, which means a runtime download, so it could not be packaged
  cleanly. What exists instead: `spring-boot: run` (overseer, `<leader>os`), jdtls with Spring
  static imports in completion, and jdtls' main-class debug configurations (`<F5>`).

## Python

- **pyright, not basedpyright.** devenv's `languages.python.lsp` installs pyright by default,
  so a plain devenv works without extra lines. VS Code's Pylance is pyright-based, so the
  diagnostics match what you are used to. basedpyright mainly adds stricter defaults. To
  switch, replace `pyright` with `basedpyright` in `languages/python.nix` and in the project's
  devenv.
- **ruff for both lint and format.** The ruff language server gives diagnostics and code
  actions, and conform runs `ruff_organize_imports` + `ruff_format` on save.
- **dap-python's adapter Python is a plain `"python3"`.** nixvim's default is a Nix-built
  `python3.withPackages [debugpy]`. That would be a project toolchain inside the editor
  closure. `lua/lang_python.lua` replaces the adapter command with the project's python
  anyway.
- **Test runner:** pytest by default. `my.neovim.languages.python.testRunner = "django"`
  switches neotest and dap-python to Django's runner (`manage.py test`).

## TypeScript / React

- **angularls removed.** None of your stacks is Angular (see `docs/neovim-audit.md`). The
  `htmlangular` formatter entry went with it.
- **prettierd dropped.** It is a global daemon that caches prettier versions, and it is not in
  any devshell contract. The formatter is now biome when the project has `biome.json` /
  `biome.jsonc`, otherwise prettier from `node_modules/.bin`, then from the devshell.
- **Tailwind colour preview** uses Neovim 0.12's built-in LSP document colours
  (`vim.lsp.document_color`, on by default) instead of an extra plugin.
- **html/cssls are editor-owned.** They come in the same nixpkgs package as jsonls
  (vscode-langservers-extracted), which the editor needs anyway for JSON outside devshells.

## Config files

- **mdformat** is the editor-owned Markdown formatter outside JS projects. prettier is a
  project tool by the rules, and marksman does not format.
- **yamlls formatting is on**, so YAML formats without prettier too.

## Visuals

- **mini.base16 (Stylix's default nixvim plugin) is kept.** It already receives your palette
  from `modules/nixos/stylix.nix`, and it themes more of the plugins used here than
  base16-nvim (blink.cmp, neo-tree, fzf-lua, which-key, noice, trouble, dap-ui, gitsigns,
  render-markdown). tokyonight was removed: Stylix was already overwriting it.
- **Transparency.** Stylix's `transparentBackground.{main,signColumn,numberLine}` plus
  `highlightOverride` for `NormalNC`, neo-tree, statusline, separators, fold column and tab
  line. nixvim applies overrides with `nvim_set_hl`, which replaces the whole group, so each
  override also restores its palette foreground. Floats and the completion menu keep the
  `base01` background on purpose: transparent popups are hard to read.
- **lualine theme built from the palette.** lualine's `auto` theme guesses colours from
  highlight groups, and gets confused once `Normal` has no background.
- **nvim-notify `background_colour = base00`.** It needs a real colour to fade from when
  `Normal` is transparent. Otherwise it warns on every notification.

## Debug, tests, tasks

- **`dap.ext.vscode.load_launchjs` is not called.** In the locked nvim-dap it is deprecated
  and prints a warning. nvim-dap reads `.vscode/launch.json` by itself when a session starts.
- **overseer 2.x** reads `.vscode/tasks.json` natively and hooks `preLaunchTask` into nvim-dap.
  One template hook gives every task the project's environment.

## Startup time

The target was under 80 ms. Measured on the cloud VM this was built on (median of 6 runs,
real terminal, full config):

| Config                                              | Startup  |
| --------------------------------------------------- | -------- |
| Before (Phase 0)                                    | ~195 ms  |
| After Phase 5, without performance settings         | ~220 ms  |
| Final (`performance.nix`)                           | ~110 ms  |

`performance.nix`:
- `luaLoader.enable` (Neovim's module cache).
- Byte-compiled `init.lua` and `lua/*.lua`.
- `combinePlugins`: one runtimepath entry instead of about 60.

Some plugins are kept standalone because the merge would either fail on duplicate file paths
or drop folders they need at runtime: neotest-python's `neotest_python/`, friendly-snippets'
`snippets/`, nvim-treesitter's `runtime/`, blink.cmp's `target/`. All of these were checked
with tests: treesitter highlighting, snippets, the blink fuzzy library, neotest runs.

Rejected:
- **Byte-compiling plugins:** it rebuilds every plugin locally and runs their test suites
  (grug-far's failed).
- **Lazy-loading through lz.n:** it would bring the time down further, at the cost of a
  `lazyLoad` block per plugin.

The laptop's number is not measured yet. `nvim-smoke` prints it.

## Treesitter

All grammars come from nixpkgs (nixvim's default `grammarPackages`, about 320 of them).
`auto_install = false` is set explicitly. `:TSInstall`, `:TSInstallFromGrammar`, `:TSUpdate` and
`:TSUninstall` are replaced after startup by a message, because they would download and
compile grammars at runtime (CLAUDE.md).

## Claude Code

claudecode.nvim was an optional module in an earlier version. It was removed because of the
repository rule "never install Claude Code" (CLAUDE.md), even though the plugin itself is
only a client.

## Structure

- Extra files beyond the requested list: `treesitter.nix` (syntax trees fit no other
  topic), `tasks.nix` (overseer), `devshell.nix`, `optional.nix`, `performance.nix`,
  and `lua/*.lua` for the code that is easier to read as Lua than as Nix strings.
- Options live under `my.neovim.*`. Features that existed before Phase 1 default to *on*,
  to keep Phase 1 behaviour-identical. The new optional modules default to *off*.
- No existing keymap was renamed. Every VS Code key is an alias added next to the
  original.

## Questions

Open questions live in `docs/questions.md`.
