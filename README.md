# nix-config-g15

My NixOS flake for a **Dell G15 5511** (Intel TigerLake-H + NVIDIA RTX 3050 Mobile).

- **Desktop:** Hyprland (Lua config) started through UWSM, with the `ly` display manager, Waybar, Rofi, Mako, hyprlock/hypridle and Ghostty
- **Theme:** Stylix with a custom palette based on the NixOS logo colours (`assets/nix-bg.png`)
- **Disks:** declared with [disko](https://github.com/nix-community/disko): LUKS + btrfs, plus encrypted swap used for hibernation
- **User environment:** home-manager as a NixOS module
- **Editor:** Neovim (nixvim) set up for Java/Spring, Python (Django, FastAPI) and TypeScript/React. Project toolchains come from each project's devenv. VS Code is still installed

Rules for working on this repository (also for AI assistants) are in `CLAUDE.md`.

## Layout

```
flake.nix                      inputs + mkHost helper (one entry per machine)
flake.lock
hosts/
  g15/
    default.nix                host-specific bits: kernel modules, microcode, stateVersion
    disko.nix                  partition layout (replaces hardware-configuration.nix)
    existing-install.nix       maps disko names onto the current partitions' UUIDs (temporary)
modules/nixos/                 shared system modules, one topic per file
  base.nix                     networking, locale, system packages
  boot.nix                     systemd-boot, latest kernel, git revision in generations
  bootvine.nix                 live systemd boot screen (off for now, see below)
  storage.nix                  btrfs auto-scrub
  nix.nix                      nix settings, flake registry, GC, nh
  nvidia.nix                   PRIME offload (Intel iGPU + NVIDIA dGPU)
  power-sleep.nix              lid/power key, suspend-then-hibernate, thermald
  audio-bluetooth.nix          PipeWire, Bluetooth, blueman
  desktop.nix                  ly, Hyprland/UWSM, portals, Thunar
  podman.nix                   rootless Podman with docker compat
  stylix.nix                   theme, fonts, opacity
  users.nix                    user account, zsh
home/                          home-manager modules, one topic per file
  shell.nix  git.nix  cli.nix  session.nix  hyprland.nix  vscode.nix
  editor/neovim/               nixvim, one file per topic (see the Editor section)
  yazi.nix, yazi-learn.nix     Yazi file manager and its lessons (yazi-learn/ has the generator)
docs/                          Neovim docs, devshell contract, open questions (questions.md)
tests/nvim-smoke.sh            headless Neovim smoke test
assets/nix-bg.png              wallpaper used by Stylix
```

## Daily use

The `nh` flake path is `~/Code/nix-config` (`modules/nixos/nix.nix`), so clone the repo there:

```bash
git clone https://github.com/mateusbl/nix-config-g15 ~/Code/nix-config
```

| Command          | Alias | What it does                                        |
| ---------------- | ----- | --------------------------------------------------- |
| `nh os test`     | `nrt` | build and activate, but don't add a boot entry      |
| `nh os switch`   | `nrs` | build, activate and make it the default boot entry  |
| `nh clean all …` | `clean` | delete old generations (keeps the last 4 days / 3 generations) |
| `nix fmt`        |       | format every `.nix` file with nixfmt               |
| `nix flake update` |     | update all inputs (`flake.lock`)                    |

Nix only sees files that git tracks, so `git add` new files before you build.

The flake output is `g15`, but the hostname is still `nixos` so it matches the
running system. To rename the machine, change `hostname` in `flake.nix`. The
first switch after that needs `nh os switch -H g15`.

## Disks (disko)

`hosts/g15/disko.nix` describes the same layout the old generated
`hardware-configuration.nix` mounted:

| Partition | Size        | Contents                                                                                 |
| --------- | ----------- | ---------------------------------------------------------------------------------------- |
| ESP       | 1 GiB       | vfat → `/boot` (`fmask=0077,dmask=0077`)                                                 |
| swap      | 20 GiB      | LUKS (`cryptswap`) → swap, also `boot.resumeDevice` for hibernation                      |
| root      | rest        | LUKS (`cryptroot`) → btrfs: top level `/`, subvolumes `home` → `/home`, `nix` → `/nix`  |

Every btrfs mount uses `compress=zstd,noatime`. These options used to be in `storage.nix`.

Swap has to be at least as large as RAM for hibernation. Change `size` in `disko.nix` if
the machine has more than 16 GiB.

### Already installed machine

The current machine was installed with the NixOS installer, not with disko. Its partitions
don't have disko's GPT labels (`disk-main-ESP`, `disk-main-swap`, `disk-main-root`).
`hosts/g15/existing-install.nix` points the LUKS devices and `/boot` back at their existing
UUIDs, so `nh os switch` keeps working and nothing is reformatted. The only visible change is
that the LUKS mappings are now named `/dev/mapper/cryptroot` and `/dev/mapper/cryptswap`.

You can drop `existing-install.nix` (and its import in `hosts/g15/default.nix`) after either of these:

- a reinstall with disko (see below)
- giving the existing partitions disko's labels. This doesn't touch any data. Check the partition numbers with `lsblk -o NAME,PARTLABEL,UUID,SIZE` first:

  ```bash
  sudo sgdisk -c 1:disk-main-ESP -c 2:disk-main-root -c 3:disk-main-swap /dev/nvme0n1
  ```

### Fresh install

> **This erases the whole disk.** Check `device` in `hosts/g15/disko.nix` with `lsblk` first.

From a NixOS live ISO, with this repo cloned:

1. Delete the `./existing-install.nix` import from `hosts/g15/default.nix`. On a fresh
   disk those UUIDs don't exist.
2. Partition, encrypt, format and mount. It asks for the LUKS passphrase:

   ```bash
   sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko/latest -- --mode destroy,format,mount --flake .#g15
   ```

3. Install:

   ```bash
   sudo nixos-install --flake .#g15
   ```

## NVIDIA

PRIME offload: the Intel iGPU drives the desktop and the RTX 3050 sleeps until you need it.
Run a program on the dGPU with:

```bash
nvidia-offload <program>
```

The bus IDs (`PCI:0:2:0` and `PCI:1:0:0`) come from `lspci | grep -E "VGA|3D"`.

## Boot screen (bootvine)

`modules/nixos/bootvine.nix` turns on `services.bootvine`, a live view of the systemd job tree
during boot and shutdown. The module was merged into nixpkgs master on 2026-11-12. When this
was tested, `nixos-unstable` (2026-11-11) didn't have it yet, so evaluation failed with
``The option `services.bootvine' does not exist``.

That's why the import is commented out in `modules/nixos/default.nix`. To turn it on:

1. Update nixpkgs and check that the option exists:

   ```bash
   nix flake update nixpkgs
   ```

2. Uncomment `./bootvine.nix` in `modules/nixos/default.nix`.
3. Test it with `nh os test` before you switch. bootvine handles the LUKS passphrase prompt, so keep the previous generation in the boot menu.

## Editor

### Neovim

`home/editor/neovim/` is a nixvim configuration, one file per topic:

| File | What it does |
| --- | --- |
| `default.nix` | entry point, `my.neovim.*` switches, editor-wide tools (ripgrep, fd, fzf, lazygit) |
| `options.nix`, `keymaps.nix` | editor options and core keymaps (leader = Space), plus VS Code aliases (`<C-p>`, `<C-S-p>`, `<C-S-f>`, F2, F12, `<C-.>`, …) |
| `ui.nix` | Stylix colours (transparent inside Ghostty), lualine, bufferline, which-key, noice, dropbar breadcrumbs |
| `navigation.nix` | neo-tree, oil, fzf-lua, flash, grug-far, trouble, todo-comments, persistence, toggleterm, undotree |
| `completion.nix`, `treesitter.nix` | blink.cmp + snippets; treesitter, text objects, sticky scroll |
| `lsp.nix`, `format.nix` | LSP keymaps and inlay hints; conform.nvim (format on save, `<leader>uf` toggles) |
| `git.nix` | gitsigns, lazygit, diffview |
| `debug.nix`, `test.nix`, `tasks.nix` | nvim-dap + UI (reads `.vscode/launch.json`), neotest, overseer (reads `.vscode/tasks.json`) |
| `devshell.nix` + `lua/devshell.lua` | starts every project tool inside that project's direnv environment |
| `languages/java.nix` | jdtls (workspace per project), Java debugging/tests, Spring Boot run task |
| `languages/python.nix` | pyright, ruff, debugpy, pytest or Django runner, Django templates |
| `languages/web.nix` | vtsls, ESLint, Tailwind, biome/prettier, js-debug, jest/vitest |
| `languages/nix.nix`, `languages/config-files.nix` | nil, nixfmt; JSON/YAML (SchemaStore), TOML, Markdown, shell, Docker, HTML/CSS |
| `optional.nix` | off by default: kulala (HTTP), vim-dadbod-ui (databases) |
| `performance.nix` | Lua loader, byte-compiled config, merged plugin directory |

**Who provides what.** The editor installs only language-agnostic tools: nil, nixfmt,
lua-language-server, stylua, bash-language-server, shellcheck, shfmt, taplo, marksman,
mdformat, and the JSON/YAML/HTML/CSS/Docker servers. Each project's devenv provides its own
JDK, jdtls, Python, pyright, ruff, Node, vtsls, eslint, prettier, debug adapters and test
runners. `docs/devshell-contract.md` lists what each stack needs, with a `devenv.nix` example.

**How project tools are found.** For each file, Neovim looks for the nearest `.envrc`, loads
that environment once (if `direnv allow` was run) and starts the project's tools with it.
Two projects open at the same time each use their own toolchain. Without a devshell the editor
still works: config files get full LSP and formatting, and project languages show one clear
message such as `jdtls not found: no devshell here`.
- `:DevshellStatus` (`<leader>cD`) shows the `.envrc` state and every expected tool with its path and version.
- `:DevshellReload` reloads the environments after you change a devshell.

**Docs:**
- `docs/neovim-cheatsheet.md`: VS Code action → key
- `docs/neovim-decisions.md`: why things are the way they are, and open questions
- `docs/neovim-audit.md`: the starting point

Switches (set in `home/default.nix`):

```nix
my.neovim.languages.java.enable = false;          # also: python, web
my.neovim.debug.enable = false;                   # also: test, tasks
my.neovim.languages.python.testRunner = "django"; # default "pytest"
my.neovim.optional.http.enable = true;            # also: database
```

### VS Code

`home/vscode.nix`: plain `pkgs.vscode` with read-only extensions from nixpkgs only (nix-ide,
direnv, vim). Stylix themes it. Whether it stays is an open question in `docs/questions.md`.

## Files: Yazi

`home/yazi.nix` sets up [Yazi](https://yazi-rs.github.io) with its **default keymap**, so
tutorials match.
- **Start it:** `y` in zsh (cds to Yazi's last folder when you quit with `q`), or
  `SUPER+SHIFT+E` (opens it in Ghostty). `SUPER+E` stays Thunar.
- **Openers:** text and code → `$EDITOR` (Neovim), images → imv, audio/video → mpv, PDF →
  zathura, archives → Yazi's extract (7zip), anything else → `xdg-open`. These are also the
  desktop defaults. Directories still open in Thunar, and `text/plain` in Mousepad.
- **Previews:** images (kitty graphics protocol, native in Ghostty), video, PDF, archives,
  SVG, JSON, Markdown and code. The tools come with nixpkgs' Yazi wrapper.
- **Plugins** (from nixpkgs `yaziPlugins`): git status signs, smart-enter (`<C-l>`), mount
  (`M`), chmod (`c m`). There is also "reveal in Thunar" (`g r`). All of these keys are unused
  in Yazi's defaults.
- **Help:** Yazi's live help is `~` or `<F1>`. To debug the setup, run `ya env`.

**Learning:** `yazi-learn start`, then `yazi-learn lesson`. The 12 lessons, the quiz and the
cheatsheet are generated from the installed Yazi's real keymap at build time; see
`docs/yazi-lessons.md`.

Optional: `my.neovim.optional.yazi.enable = true;` adds yazi.nvim on `<leader>y` in Neovim.

## Binary caches

Only `cache.nixos.org` is used. `accept-flake-config = false` in `modules/nixos/nix.nix`
stops flakes from adding their own substituters. To add a cache on purpose, set
`extra-substituters` and `extra-trusted-public-keys` there.

## Testing

These checks ran before this layout was committed, and all of them pass:

```bash
nix flake check --no-build
```

```bash
nix eval .#nixosConfigurations.g15.config.system.build.toplevel.drvPath
```

```bash
nix build .#nixosConfigurations.g15.config.system.build.diskoScript
```

The first checks the flake outputs and evaluates the whole NixOS configuration. The second
instantiates the system closure. The third builds the disko partitioning script without
running it.

After switching, check Neovim with:

```bash
tests/nvim-smoke.sh
```

It opens a file of every supported language headless, fails on any Lua error, and prints the
startup time.

Known evaluation warnings that don't break anything:

- nixvim warns that its nixpkgs `follows` differs from its own pin. The `follows` is on purpose (one nixpkgs for the whole system).
- Stylix sets `programs.rofi.font`, which is deprecated upstream.

## License

GPL-3.0, see [LICENSE](LICENSE).
