# nix-config-g15

My NixOS flake for a **Dell G15 5511** (Intel TigerLake-H + NVIDIA RTX 3050 Mobile).

- **Desktop:** Hyprland (Lua config) started through UWSM, with the `ly` display manager, ashell (bar), fuzzel (launcher), Mako, hyprlock/hypridle and Ghostty
- **Theme:** Stylix with a blue base16 palette on a deep navy background (`modules/nixos/stylix.nix`), Papirus icons and the Bibata cursor. The wallpaper is `assets/nix-bg.png` tinted to that palette at build time, and the ly login screen uses the same colours
- **Disks:** declared with [disko](https://github.com/nix-community/disko): LUKS + btrfs, plus encrypted swap used for hibernation
- **User environment:** home-manager as a NixOS module
- **Editor:** Neovim (nixvim) set up for Java/Spring, Python (Django, FastAPI) and TypeScript/React/Angular. Project toolchains come from each project's devenv. VS Code is still installed

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
  bootvine.nix                 live systemd boot screen (from bootvine's own flake)
  storage.nix                  btrfs auto-scrub
  snapshots.nix                daily btrfs snapshots of /home (btrbk)
  secrets.nix                  oo7 as the only Secret Service (+ PAM unlock, portal)
  nix.nix                      nix settings, flake registry, GC, nh
  nvidia.nix                   PRIME offload (Intel iGPU + NVIDIA dGPU)
  power-sleep.nix              lid/power key, suspend-then-hibernate, power profile
  oom.nix                      earlyoom: kills a runaway process before the machine freezes
  performance.nix              sched_ext scheduler, zram memory tuning, BBR networking
  audio-bluetooth.nix          PipeWire, Bluetooth, blueman
  desktop.nix                  ly, Hyprland/UWSM, portals, udisks
  podman.nix                   rootless Podman with docker compat
  stylix.nix                   theme, fonts, opacity
  users.nix                    user account, zsh
home/                          home-manager modules, one topic per file
  shell.nix  git.nix  cli.nix  session.nix  hyprland.nix
  editor/neovim/               nixvim, one file per topic (see the Editor section)
  yazi.nix                     Yazi file manager
  identity.nix                 name + email, shared by git.nix and jujutsu.nix
  jujutsu.nix                  jj (colocated with git), jjui, SSH agent
  desktop-scripts.nix          power menu, screenshots, clipboard picker; XDG user dirs
  desktop-extras.nix           optional: night light, colour picker, screen recorder
docs/                          Neovim docs, devshell contract, jj and oo7 notes
assets/nix-bg.png              wallpaper used by Stylix
```

## Installation

Pick one of two paths:

| | Path | Data on disk |
| --- | --- | --- |
| **A** | Switch the NixOS that is already on this laptop to this config | kept, nothing is reformatted |
| **B** | Install from the NixOS installer USB with disko | **erased** |

Before you start, for both paths:

- Plug in the charger and have a working network connection. The first build downloads most
  packages from cache.nixos.org and compiles bootvine locally, so allow some time.
- Have a backup of anything you cannot lose. Path A does not reformat, but it does change the
  boot path (bootvine shows the passphrase prompt).
- The flake output is called `g15`. Every command below names it as `.#g15`.

### A. On the current NixOS install (nothing is reformatted)

1. Clone the repository where `nh` expects it (`programs.nh.flake` in `modules/nixos/nix.nix`):

   ```bash
   git clone https://github.com/mateusbl/nix-config-g15 ~/Code/nix-config
   ```

   ```bash
   cd ~/Code/nix-config
   ```

2. **Check the disk IDs.** `hosts/g15/existing-install.nix` points at this laptop's partitions by
   UUID. If they don't match, the new system cannot find its disks at boot. Compare them:

   ```bash
   lsblk -o NAME,FSTYPE,UUID,SIZE,MOUNTPOINTS
   ```

   The `crypto_LUKS` partition holding `/` must have the UUID in `rootUuid`, the other
   `crypto_LUKS` partition (swap) the one in `swapUuid`, and the `vfat` partition mounted at `/boot`
   the one in the `fileSystems."/boot"` line. Fix the file if any differs.

3. Try it without touching the boot menu. `test` activates the new system until the next reboot,
   so a plain reboot brings the old one back:

   ```bash
   sudo nixos-rebuild test --flake .#g15
   ```

   If Nix says flakes are not enabled yet, use this once instead:

   ```bash
   sudo NIX_CONFIG="experimental-features = nix-command flakes" nixos-rebuild test --flake .#g15
   ```

4. Log out and back in through ly, so the new session services start. Look around: the bar, the
   launcher (`SUPER+D`), a terminal, sound, Wi-Fi. Two quick checks for things you cannot see:

   ```bash
   systemctl --failed
   ```

   ```bash
   systemctl --user --failed
   ```

   Both should list 0 units.

5. If everything works, make it permanent (this adds the boot entry):

   ```bash
   sudo nixos-rebuild switch --flake .#g15
   ```

   The boot screen and the passphrase prompt change with this step (bootvine).

6. Reboot once and confirm the passphrase prompt, login and hibernation work.

If something goes wrong:

- **After step 3:** reboot. Nothing was written to the boot menu, so the old system starts.
- **After step 5:** pick the previous generation in the systemd-boot menu, then make it the
  default again with `sudo nixos-rebuild switch --rollback`.

From here on, use the aliases in [Daily use](#daily-use).

### B. Fresh install from the installer USB

> **This erases the whole disk.** Copy off everything you want to keep first.

Every step from a blank USB stick to the finished desktop:

1. **Make the USB stick.** Download the *Graphical ISO image* (GNOME, 64-bit Intel/AMD) from
   <https://nixos.org/download>. It has a Wi-Fi menu and a terminal, which the steps below use.
   Find the stick's name with `lsblk`, then write the image to it (this erases the stick; replace
   both placeholders):

   ```bash
   sudo dd if=PATH-TO-THE.iso of=/dev/sdX bs=4M status=progress oflag=sync
   ```

2. **Boot it.** Plug the stick in, power on and press `F12` at the Dell logo, then pick the stick
   under *UEFI Boot*. The firmware settings that let the current NixOS boot (Secure Boot off) are
   the ones this install needs too, so there is nothing to change there. Close the graphical
   installer window if it opens: it is not used.

3. **Network and terminal.** Connect to Wi-Fi from the menu in the top-right corner. Open the
   *Console* app. Check the connection:

   ```bash
   ping -c 3 nixos.org
   ```

4. **Get the repository.** The first command opens a shell that has `git`; stay in it until the
   end.

   ```bash
   nix-shell -p git
   ```

   ```bash
   git clone https://github.com/mateusbl/nix-config-g15
   ```

   ```bash
   cd nix-config-g15
   ```

   If the config has not been merged into the default branch yet, switch to its branch now with
   `git switch BRANCH-NAME`.

5. **Check the disk settings.** List the disks:

   ```bash
   lsblk -d -o NAME,SIZE,MODEL
   ```

   The internal SSD should be `nvme0n1`. If it has another name, change `device` in
   `hosts/g15/disko.nix` (`nano hosts/g15/disko.nix`). In the same file, the swap `size` (20G)
   must be at least the amount of RAM (`free -h`), or hibernation will not work.

6. **Remove the old-install bridge.** `hosts/g15/existing-install.nix` holds the UUIDs of the
   partitions that are about to be erased. Delete its line from the imports:

   ```bash
   sed -i '/existing-install.nix/d' hosts/g15/default.nix
   ```

   ```bash
   git rm hosts/g15/existing-install.nix
   ```

7. **Partition, encrypt, format and mount.** This is the step that erases the disk. It asks you
   to choose a passphrase for the swap partition and then for the root partition. Use the same
   one for both, so the boot asks only once.

   ```bash
   sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko/latest -- --mode destroy,format,mount --flake .#g15
   ```

   Check the result: `/mnt`, `/mnt/boot`, `/mnt/home` and `/mnt/nix` must be listed.

   ```bash
   findmnt -R /mnt
   ```

8. **Install.** This downloads the system and compiles bootvine, so it takes a while. At the end
   it asks for a root password.

   ```bash
   sudo nixos-install --flake .#g15
   ```

9. **Set your own password.** The config sets none on purpose, and without one you cannot log in:

   ```bash
   sudo nixos-enter --root /mnt -c 'passwd mateus'
   ```

10. **Take the repository with you**, including the edits from steps 5 and 6, to the place `nh`
    expects it:

    ```bash
    sudo mkdir -p /mnt/home/mateus/Code
    ```

    ```bash
    sudo cp -r . /mnt/home/mateus/Code/nix-config
    ```

    ```bash
    sudo nixos-enter --root /mnt -c 'chown -R mateus:users /home/mateus'
    ```

11. **Reboot into the new system** and pull the stick out when the screen goes dark:

    ```bash
    reboot
    ```

    bootvine asks for the disk passphrase, then ly asks for user `mateus` and the password from
    step 9. Hyprland starts after login. `SUPER + Return` opens a terminal.

12. **Finish.** Connect to Wi-Fi from the bar (click the icons on the right, or the tray icon). Then confirm that rebuilding works
    from the installed system and record the edits from steps 5 and 6:

    ```bash
    cd ~/Code/nix-config
    ```

    ```bash
    nrt
    ```

    ```bash
    git commit -am "g15: installed with disko"
    ```

If something goes wrong:

- **disko or `nixos-install` stops with an error:** nothing is bootable yet, but both can simply be
  run again from the same terminal after fixing the cause.
- **The new system does not boot or you cannot log in:** boot the USB stick again, repeat steps 3
  to 6, then mount the installed system without formatting (`--mode mount` instead of
  `--mode destroy,format,mount` in the command of step 7). After that, `nixos-install` and
  `nixos-enter` from steps 8 and 9 work again.

### After either install

- **SSH key:** the config creates none. Make one with `ssh-keygen -t ed25519` and add the public key
  to your Git host. The first use in a session asks for its passphrase once.
- **Projects:** run `direnv allow` once in each project that has an `.envrc`. `docs/devshell-contract.md`
  lists what a project's devenv must provide for Neovim.
- **Secrets:** oo7 creates its keyring at the first login. Verification steps are in `docs/oo7-notes.md`.

## Daily use

Work in `~/Code/nix-config`. Nix only sees files that git tracks, so `git add` new files before you
build.

| Alias | Command | What it does |
| --- | --- | --- |
| `nrt` | `nh os test -H g15` | build and activate until the next reboot; no boot entry |
| `nrs` | `nh os switch -H g15` | build, activate and make it the default boot entry |
| `clean` | `nh clean all --keep-since 4d --keep 3` | delete old generations |
| | `nix fmt` | format every `.nix` file with nixfmt |
| | `nix flake update` | update all inputs (`flake.lock`) |
| | `nix flake check` | evaluate the whole system without building it |

`-H g15` is needed because `nh` otherwise looks for a flake output named after the machine's hostname,
which is still `nixos` (set in `flake.nix`). If you change `hostname` there to `g15`, plain
`nh os switch` works too.

## Power

Settings live in `modules/nixos/power-sleep.nix` (the NVIDIA card sleeps by itself, see `nvidia.nix`).
Nothing is throttled to save battery: the panel stays at 120 Hz and Wi-Fi power saving is off.

- **Profile follows the charger:** `performance` on AC, `balanced` on battery, set when the charger is (un)plugged and at boot. The bar's settings panel has a button to change it by hand (it is reset at the next plug/unplug).
- **Low-battery safety net (UPower):** low at 20%, critical at 10%, hibernate at 5%.
- Idle behaviour: dim after 5 min, lock after 10, screen off after 11, suspend-then-hibernate after 30 (and on lid close after 2 h of sleep).

## Out of memory

`modules/nixos/oom.nix` runs earlyoom. When less than 10% of RAM is available and less than 20% of swap
is free, it ends the biggest process (SIGTERM, then SIGKILL at half those values) instead of letting the
desktop freeze. It avoids the session (Hyprland, ashell, PipeWire, oo7, ...), prefers Firefox tab
processes, and sends a desktop notification naming what it killed.

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
UUIDs, so rebuilding keeps working and nothing is reformatted. The only visible change is
that the LUKS mappings are now named `/dev/mapper/cryptroot` and `/dev/mapper/cryptswap`.

You can drop `existing-install.nix` (and its import in `hosts/g15/default.nix`) after either of these:

- a reinstall with disko (Installation, path B)
- giving the existing partitions disko's labels. This doesn't touch any data. Check the partition numbers with `lsblk -o NAME,PARTLABEL,UUID,SIZE` first:

  ```bash
  sudo sgdisk -c 1:disk-main-ESP -c 2:disk-main-root -c 3:disk-main-swap /dev/nvme0n1
  ```

A fresh install with disko is described step by step under [Installation](#installation), path B.

## NVIDIA

PRIME offload: the Intel iGPU drives the desktop and the RTX 3050 sleeps until you need it.
Run a program on the dGPU with:

```bash
nvidia-offload <program>
```

The bus IDs (`PCI:0:2:0` and `PCI:1:0:0`) come from `lspci | grep -E "VGA|3D"`.

## Boot screen (bootvine)

`modules/nixos/bootvine.nix` turns on `services.bootvine`: a live tree of systemd jobs on the boot
console (initrd, stage 2 and shutdown). It relies on the systemd-based initrd, which is the only one
this nixpkgs still has.

- **Source:** bootvine's own flake, the `bootvine` input in `flake.nix` (codeberg.org/wvhulle/bootvine,
  pinned in `flake.lock`). Its NixOS module and its package come from there. nixos-unstable has the
  package but not yet a module, which is why the flake is used.
- **Compiled here:** the package is built from source on this machine (crane, with the Rust toolchain the
  project pins), so the first rebuild takes a while. Its Cachix cache is not used: Nix only honours
  `nixConfig` from the top-level flake, and `accept-flake-config = false` blocks it anyway. The only
  binary cache in use is cache.nixos.org.
- **Later:** once nixpkgs ships its own `services.bootvine`, delete the input and the import in
  `bootvine.nix`; declaring the options twice would be an error.
- **Update it** with `nix flake update bootvine`.
- It sits in the boot path (it shows the LUKS passphrase prompt). Try it with `nrt` first, which
  does not change the boot menu, and keep the previous generation selectable.
- Tuning goes in `services.bootvine.settings` (see the comment in the file).

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
| `devshell.nix` + `lua/devshell.nix` | starts every project tool inside that project's direnv environment |
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

## Files: Yazi

`home/yazi.nix` sets up [Yazi](https://yazi-rs.github.io) with its **default keymap**, so
tutorials match.
- **Start it:** `y` in zsh (cds to Yazi's last folder when you quit with `q`), or
  `SUPER+E` or `SUPER+SHIFT+E` (opens it in Ghostty). It is the only file manager.
- **Openers:** text and code → `$EDITOR` (Neovim), images → imv, audio/video → mpv, PDF →
  zathura, archives → Yazi's extract (7zip), anything else → `xdg-open`. These are also the
  desktop defaults. Directories open in Yazi (in a Ghostty window), and `text/plain` in Mousepad.
- **Previews:** images (kitty graphics protocol, native in Ghostty), video, PDF, archives,
  SVG, JSON, Markdown and code. The tools come with nixpkgs' Yazi wrapper.
- **Plugins** (from nixpkgs `yaziPlugins`): git status signs, mount (`M`, also for USB
  drives), chmod (`c m`). These keys are unused in Yazi's defaults.
- **Help:** Yazi's live help is `~` or `<F1>`. To debug the setup, run `ya env`.

Optional: `my.neovim.optional.yazi.enable = true;` adds yazi.nvim on `<leader>y` in Neovim.

## Desktop keys and helpers

| Key | Does |
| --- | --- |
| `SUPER+Escape` | lock |
| `SUPER+SHIFT+Escape` | power menu (fuzzel): lock, suspend, reboot, poweroff, logout. Nothing happens unless you pick one |
| `Print` | region screenshot to the clipboard |
| `Shift+Print` / `Ctrl+Print` | region / full screen to `~/Pictures/Screenshots`, with a notification |
| `SUPER+SHIFT+V` | clipboard history (cliphist, started with the session) |
| `XF86AudioPlay/Next/Prev` | media control via playerctl, sent to the last used player (playerctld) |
| Volume / brightness / mute keys | change the value and show it in a small notification with a bar (`osd`, drawn by mako in the theme colours) |

- The bar is ashell (`home/session.nix`): workspaces, window title, CPU/memory/temperature, tray, clock (click for a calendar) and a settings group. Clicking the settings group opens a panel for volume, Wi-Fi, Bluetooth, brightness, power profile and lock/suspend/hibernate/reboot/poweroff/logout. Right-clicking the speaker opens pavucontrol; right-clicking Bluetooth opens blueman-manager.
- Wi-Fi and Bluetooth are handled in that panel; there are no separate tray applets. Bluetooth is off after boot until you turn it on there. For VPNs or editing a connection use `nmtui` in a terminal.
- The launcher is fuzzel (`SUPER+D`). The power menu and the clipboard picker use it too.
- Small utility windows float centred instead of tiling: the mixer, Bluetooth manager and file dialogs (`window_rule` in `home/hyprland.nix`).
- Optional, off by default, in `home/desktop-extras.nix`:
  - `my.desktop.nightLight.enable`: hyprsunset, warmer colours from 20:00.
  - `my.desktop.colorPicker.enable`: hyprpicker on `SUPER+SHIFT+C`.
  - `my.desktop.screenRecorder.enable`: wf-recorder on `SUPER+SHIFT+R`. It records a region and encodes on the CPU, so it works with the NVIDIA hybrid setup.

## Secrets: oo7

`modules/nixos/secrets.nix` makes [oo7](https://github.com/linux-credentials/oo7) the only Secret
Service. The keyring unlocks with your ly login password. The CLI is `oo7-cli` (store / lookup /
search / delete). gnome-keyring is forced off. Verification steps, gaps and the fallback are in
`docs/oo7-notes.md`.

## Version control: jj + git

Git and [Jujutsu](https://jj-vcs.github.io) share one identity (`home/identity.nix`).
- jj repos are colocated, so git, lazygit and gitsigns keep working.
- Diffs go through delta. The TUI is `jjui`.
- Remotes are reached over SSH through `services.ssh-agent`. No keys are created. The first use of a key in a session asks for its passphrase and adds it to the agent (`AddKeysToAgent yes`), so later pushes don't ask again.
- There is no `gh`; pull requests are made in the browser.

git → jj translations are in `docs/jj-cheatsheet.md`.

## Snapshots of /home

`modules/nixos/snapshots.nix` runs btrbk once a day and keeps 14 daily read-only
snapshots of the `home` subvolume in `/.snapshots` (root only). To get a file back:

```bash
sudo ls /.snapshots
```

```bash
sudo cp /.snapshots/home.<date>/<user>/path/to/file ~/path/to/file
```

These snapshots are on the same disk, so they are **not** a backup. Off-disk backups are
made by hand, outside this config.

## Speed

The base is current: `nixos-unstable`, the newest kernel (`linuxPackages_latest`), dbus-broker, a
systemd initrd and zstd-compressed zram. Update everything to the newest revisions with
`nix flake update`. `modules/nixos/performance.nix` adds:

- **sched_ext scheduler:** `scx_bpfland` through `services.scx-loader`. It favours interactive tasks,
  so the desktop stays smooth while a build uses every core. The kernel falls back to its built-in
  scheduler by itself if a sched_ext scheduler misbehaves. `scxctl get` shows what is running.
- **Memory:** the sysctl values recommended for zram (swap idle pages to compressed RAM early).
- **Network:** BBR congestion control with the `fq` queueing discipline.

Deliberately not done: disabling CPU security mitigations, and putting `/tmp` in RAM (large local
builds would run out of memory).

## Nix builds

Builds run at idle CPU and disk priority (`nix.daemonCPUSchedPolicy` / `daemonIOSchedClass` in
`modules/nixos/nix.nix`), so the desktop stays usable while something compiles.

## Binary caches

Only `cache.nixos.org` is used. `accept-flake-config = false` in `modules/nixos/nix.nix`
stops flakes from adding their own substituters, which is what keeps the bootvine flake's Cachix
out. To add a cache on purpose, set `extra-substituters` and `extra-trusted-public-keys` there. To
use none at all, set `substituters = [ ]`; everything, including the kernel, is then compiled
locally.

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

There are no automated tests of the running machine or of the Neovim config. After a switch,
`systemctl --failed` and `systemctl --user --failed` show services that did not start.

## License

GPL-3.0, see [LICENSE](LICENSE).
