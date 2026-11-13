# Neovim cheatsheet (VS Code → this config)

Leader is **Space**. `<leader>` keys pop up which-key after a moment, so you can explore.
Keys marked *VS Code alias* are additions. The original keys still work.

## Files and search

| VS Code                         | Keys                                  | Notes                                  |
| ------------------------------- | ------------------------------------- | -------------------------------------- |
| Quick Open (Ctrl+P)             | `<C-p>` *VS Code alias*, `<leader><space>`, `<leader>ff` | fzf-lua files      |
| Command Palette (Ctrl+Shift+P)  | `<C-S-p>` *VS Code alias*             | fzf-lua commands                       |
| Search in files (Ctrl+Shift+F)  | `<C-S-f>` *VS Code alias*, `<leader>/`, `<leader>sg` | live grep               |
| Search and replace in files     | `<leader>sr`                          | grug-far                               |
| Open recent                     | `<leader>fr`                          |                                        |
| Switch editor (Ctrl+Tab)        | `<leader>,`, `<S-h>` / `<S-l>`        | buffers                                |
| Explorer (Ctrl+Shift+E)         | `<leader>e` (toggle), `<leader>E` (reveal file) | neo-tree                     |
| Edit parent folder as text      | `-`                                   | oil                                    |
| Go to symbol in file            | `<leader>ss`                          |                                        |
| Go to symbol in workspace       | `<leader>sS`                          |                                        |
| Breadcrumbs                     | shown in the window bar; `<leader>;` to pick | dropbar                         |
| Sticky scroll                   | on; `<leader>uc` toggles              | treesitter-context                     |

## Code

| VS Code                         | Keys                                  |
| ------------------------------- | ------------------------------------- |
| Go to definition (F12)          | `<F12>` *VS Code alias*, `gd`         |
| Find references (Shift+F12)     | `<S-F12>` *VS Code alias*, `gr`       |
| Go to implementation            | `gI`                                  |
| Peek / hover                    | `K`                                   |
| Signature help                  | `gK`                                  |
| Rename symbol (F2)              | `<F2>` *VS Code alias*, `<leader>cR`  |
| Quick fix / code action (Ctrl+.)| `<C-.>` *VS Code alias*, `<leader>ca` |
| Format document                 | `<leader>cf` (also on save; `<leader>uf` toggles format-on-save) |
| Problems panel (Ctrl+Shift+M)   | `<C-S-m>` *VS Code alias*, `<leader>xx` |
| Next / previous problem         | `]d` / `[d`; `<leader>cd` shows it    |
| Toggle comment                  | `gcc` (line), `gc` + motion           |
| Move line up/down (Alt+↑/↓)     | `<A-k>` / `<A-j>`                     |
| Inlay hints on/off              | `<leader>uh`                          |
| TODO list                       | `<leader>xt`, `<leader>st`            |

## Debugging

| VS Code                         | Keys                                     |
| ------------------------------- | ---------------------------------------- |
| Start / continue (F5)           | `<F5>` *VS Code alias*, `<leader>dc`     |
| Stop (Shift+F5)                 | `<S-F5>` *VS Code alias*, `<leader>dt`   |
| Toggle breakpoint (F9)          | `<F9>` *VS Code alias*, `<leader>db`     |
| Conditional breakpoint          | `<leader>dB`                             |
| Step over (F10)                 | `<F10>` *VS Code alias*, `<leader>dO`    |
| Step into (F11)                 | `<F11>` *VS Code alias*, `<leader>di`    |
| Step out (Shift+F11)            | `<S-F11>` *VS Code alias*, `<leader>do`  |
| Run to cursor                   | `<leader>dC`                             |
| Debug console / REPL            | `<leader>dr`                             |
| Evaluate selection              | `<leader>de`                             |
| Debug UI                        | `<leader>du` (opens by itself when a session starts) |
| Run last configuration          | `<leader>dl`                             |

`.vscode/launch.json` is picked up automatically when you press `<F5>`.

## Tests

| VS Code (Testing)               | Keys                                     |
| ------------------------------- | ---------------------------------------- |
| Run test at cursor              | `<leader>tr`                             |
| Debug test at cursor            | `<leader>td`                             |
| Run tests in file               | `<leader>tt`                             |
| Run all tests                   | `<leader>tT`                             |
| Re-run last                     | `<leader>tl`                             |
| Test explorer                   | `<leader>ts`                             |
| Test output                     | `<leader>to` (float), `<leader>tO` (panel) |
| Watch file                      | `<leader>tw`                             |
| Java: test class / method (jdtls, with debugger) | `<leader>tc` / `<leader>tm`  |

## Tasks

| VS Code                         | Keys                                     |
| ------------------------------- | ---------------------------------------- |
| Run Task (tasks.json, npm, …)   | `<leader>or`                             |
| Task list / output              | `<leader>ot`                             |
| Task actions (restart, stop, …) | `<leader>oa`                             |
| Spring Boot: run                | `<leader>os`                             |

## Git

| VS Code                         | Keys                                     |
| ------------------------------- | ---------------------------------------- |
| Source control                  | `<leader>gg` (lazygit), `<leader>gs` (status) |
| Diff editor                     | `<leader>gd` (open), `<leader>gD` (close) |
| File history / timeline         | `<leader>gh`, `<leader>gf` (lazygit)     |
| Blame line                      | `<leader>gb` (inline blame is always on) |
| Commits                         | `<leader>gc`                             |

## Java refactoring (when jdtls is attached)

| Action                    | Keys                       |
| ------------------------- | -------------------------- |
| Organize imports          | `<leader>co`               |
| Extract variable          | `<leader>crv` (normal/visual) |
| Extract constant          | `<leader>crc` (normal/visual) |
| Extract method            | `<leader>crm` (visual)     |

## Environment and misc

| What                              | Keys / command                     |
| --------------------------------- | ---------------------------------- |
| Devshell status (tools, versions) | `<leader>cD`, `:DevshellStatus`    |
| Reload devshell after editing it  | `:DevshellReload`, then `:lsp restart` |
| Terminal (Ctrl+`)                 | `<C-/>`, `<leader>ft`              |
| Undo history                      | `<leader>uu`                       |
| Markdown rendering on/off         | `<leader>um`                       |
| Zen mode                          | `<leader>uz`                       |
| Word wrap                         | `<leader>uw`                       |
| Restore session                   | `<leader>qs` (this folder), `<leader>ql` (last) |
| Save                              | `<C-s>`                            |

## Optional modules (off by default)

| Module (`my.neovim.optional.*`) | Keys                                   |
| ------------------------------- | -------------------------------------- |
| `http`: kulala                  | `<leader>Rs` send request, `<leader>Ra` send all |
| `database`: dadbod-ui           | `<leader>Du` toggle UI                 |
| `claude`: claudecode            | `<leader>ac` toggle, `<leader>as` send selection (visual) |

`<C-S-…>` keys need a terminal that reports them. Ghostty does, through the kitty keyboard
protocol that Neovim turns on. If one does nothing, use the leader key next to it.
