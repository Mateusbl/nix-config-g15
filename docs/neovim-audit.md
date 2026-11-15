# Neovim audit (Phase 0)

Snapshot of `home/neovim.nix` before the editor rework, taken at commit `d4fbaf0`.
Nothing in the configuration was changed for this audit.

## Versions (from the locked `flake.lock`)

| Thing         | Version / revision                                  |
| ------------- | --------------------------------------------------- |
| Neovim        | **0.12.6** (`nvim --version` of the built package)  |
| nixpkgs       | `f4a03c0` (nixos-unstable, 2026-11-07)              |
| nixvim        | `453dc9c` (2026-10-17)                              |
| Stylix        | `3e27b6c` (2026-10-25)                              |
| home-manager  | `a9752a6` (2026-11-09)                              |

Neovim is 0.11+, so LSP uses `vim.lsp.config()` / `vim.lsp.enable()`.
nixvim's `plugins.lsp.servers.*` already generates exactly those calls (checked in the
generated `init.lua`), so no migration away from `plugins.lsp` is needed for the API itself.

How this was measured: the nixvim package was built from the flake
(`programs.nixvim.build.package` of the home-manager user) and started together with the
`~/.config/nvim` that home-manager generates, in a real terminal (pty).

- No Lua errors, empty `:messages`.
- 43 plugins in the pack directory.
- Startup: about **195 ms** (median of 6 runs, `--startuptime`, on the cloud VM used for this
  work, so expect a faster number on the laptop).

> Correction: the first version of this audit said 39 ms. That run did not load the config
> at all (in home-manager mode `init.lua` is not part of the nixvim package), so it was wrong.

## What exists

| Area            | What is configured                                                                 |
| --------------- | ---------------------------------------------------------------------------------- |
| Options         | LazyVim-like defaults (relative numbers, `clipboard=unnamedplus`, undofile, …)     |
| Theme           | `tokyonight` (night) **and** Stylix `mini.base16` (see problems)                   |
| UI              | alpha dashboard, noice, notify, bufferline, lualine, which-key (helix preset), indent-blankline, illuminate, zen-mode |
| Files / search  | neo-tree, oil (`-`), fzf-lua, flash, grug-far, trouble, todo-comments, persistence |
| Completion      | blink.cmp + friendly-snippets                                                      |
| Treesitter      | nvim-treesitter (all grammars), textobjects (move), ts-autotag, ts-comments        |
| LSP             | nil_ls, lua_ls (editor-provided); pyright, ruff, vtsls, eslint, tailwindcss, html, cssls, jsonls, yamlls, angularls (`package = null`, expected from devenv); jdtls via nvim-jdtls |
| Formatting      | conform.nvim, format on save, `<leader>uf` toggle                                  |
| Debug           | nvim-dap, dap-ui, dap-virtual-text, dap-python; jdtls DAP via `LspAttach` hook     |
| Test            | neotest with python, jest, vitest, java adapters                                   |
| Git             | gitsigns (inline blame), lazygit (plugin + binary)                                 |
| Terminal        | toggleterm (float)                                                                 |
| Env loading     | `direnv-vim` plugin + home-manager `programs.direnv` with nix-direnv               |

Keymaps (kept as-is in every later phase): leader is space. There are LazyVim-style maps for
windows, buffers, moving lines and save, plus fzf-lua (`<leader><space>`, `<leader>/`, `<leader>f*`, `<leader>s*`),
neo-tree (`<leader>e`/`E`), oil (`-`), toggleterm (`<C-/>`, `<leader>ft`), lazygit (`<leader>gg`),
trouble (`<leader>x*`), DAP (`<leader>d*`), neotest (`<leader>t*`), persistence (`<leader>q*`),
and Java refactors on jdtls attach (`<leader>co`, `<leader>cr*`, `<leader>tc`, `<leader>tm`).

## Problems found

1. **Two colorschemes fight.** `tokyonight` is set as the colorscheme. Then Stylix's nixvim target
   (on by default through home-manager) runs `mini.base16` setup later in `init.lua`, which
   overwrites it. tokyonight is loaded for nothing, and some plugin groups end up
   half-tokyonight, half-base16.
2. **Not transparent.** Stylix `transparentBackground.*` is off, so Neovim paints an opaque
   `base00` slab inside Ghostty (opacity 0.85).
3. **jdtls `root_dir` is computed once, at startup.** The generated Lua is
   `root_dir = vim.fs.root(0, {...})`. Buffer 0 is the empty startup buffer, so every Java
   file shares one root, the one Neovim was started in, or none at all. With two Java projects open,
   the second one would attach to the first project's server.
4. **Project toolchain lives in home-manager**, which breaks the separation rule:
   - `jdt-language-server` 1.63 is put on Neovim's PATH. nixvim's `lsp.servers.jdtls.package`
     defaults to it; `plugins.jdtls.jdtLanguageServerPackage = null` does not cover that.
   - lombok, `vscode-java-debug` and `vscode-java-test` jars are hard-coded store paths in
     the jdtls config.
5. **Editor-owned servers missing outside a devshell.** `jsonls` and `yamlls` have
   `package = null`, so `.json`/`.yaml` files get no LSP outside a project shell. bashls,
   shellcheck, shfmt, taplo, marksman, dockerls and docker-compose-language-service are not
   configured at all.
6. **Project servers don't use the project's environment reliably.** They are started from
   Neovim's own PATH. That only works if Neovim was launched from inside the project
   shell. `direnv-vim` changes the *global* environment on `:cd`, so two projects in one
   session cannot each have their own JDK/Python.
7. **No "tool missing" feedback.** If a devenv lacks a server, `vim.lsp` logs a failed start
   and nothing tells you why.
8. **Small issues:**
   - `plugins.fzf-lua.settings.winopts.tittle_pos` is a typo (`title_pos`), so it is silently ignored.
   - `htmlangular` is in conform's formatter list.
   - `prettierd` is preferred, but it is not in any devshell contract.

## Gaps against the goal (VS Code replacement)

| Wanted                                        | Status                                     |
| --------------------------------------------- | ------------------------------------------ |
| Per-project toolchain via devenv              | missing (problem 6)                        |
| `:DevshellStatus`, clear missing-tool message | missing                                    |
| `.vscode/launch.json` / `tasks.json`          | missing (no overseer)                      |
| JS/TS debugging (js-debug)                    | missing                                    |
| Spring Boot run task                          | missing                                    |
| jdtls workspace per project                   | missing (jdtls default `-data`)            |
| Schema store for JSON/YAML                    | missing                                    |
| Docker, TOML, Markdown, Bash LSP              | missing                                    |
| Sticky scroll, breadcrumbs                    | missing (no treesitter-context / dropbar)  |
| Diff view, undo tree, Markdown rendering      | missing                                    |
| VS Code keys (`<C-p>`, `<C-S-f>`, `<C-S-p>`, F2, F12) | missing                            |
| Problems panel, search/replace, sessions, TODOs | present (trouble, grug-far, persistence, todo-comments) |

## Is `angularls` justified?

**No.** The stacks named for this machine are Java/Spring, Django/DRF, FastAPI and
React/Vite. None of them is Angular, and nothing in the repository points at Angular.
`angularls` is set to `package = null`, so it only starts if some devshell happens to
provide `ngserver`. Otherwise it is dead configuration that also adds an `htmlangular`
formatter entry. Phase 5 removes it and records it under "Questions for me" in
`docs/neovim-decisions.md`.

## Other files read

- `home/cli.nix`: ripgrep, fd, bat, jq, btop and friends. These are generic and stay editor-independent.
- `home/vscode.nix`: VS Code (FHS) with nix-ide, direnv and vim. It stays until the acceptance
  checklist is confirmed.
- `modules/nixos/stylix.nix`: custom base16 palette (NixOS-logo blues), `polarity = "dark"`,
  terminal opacity 0.85, FiraCode Nerd Font Mono 12. This is the palette Neovim should use.
