# nix-config-g15

My NixOS flake for a **Dell G15 5511** (Intel TigerLake-H + NVIDIA RTX 3050 Mobile).

- **Desktop:** Hyprland (Lua config), greetd with tuigreet (login), ashell (bar, notifications, volume/brightness overlay), fuzzel (launcher), hyprshell (alt-tab), hyprlock/hypridle, Ghostty and LibreWolf
- **Theme:** Stylix with a blue base16 palette on a deep navy background (`modules/nixos/stylix.nix`), Papirus icons and the Bibata cursor. The wallpaper is `assets/nix-bg.png` tinted to that palette at build time, and the login screen uses the same colours
- **Disks:** declared with [disko](https://github.com/nix-community/disko): LUKS + btrfs, plus encrypted swap used for hibernation
- **User environment:** home-manager as a NixOS module
- **Editor:** Neovim (nixvim) set up for Java/Spring, Python (Django, FastAPI) and TypeScript/React/Angular. Project toolchains come from each project's devenv

Rules for working on this repository (also for AI assistants) are in `CLAUDE.md`.

## Layout

```
flake.nix                      inputs + mkHost helper (one entry per machine)
flake.lock
hosts/
  g15/
    default.nix                host-specific bits: kernel modules, microcode, stateVersion
    disko.nix                  partition layout (replaces hardware-configuration.nix)
modules/nixos/                 shared system modules, one topic per file
  base.nix                     NetworkManager with iwd, locale, system packages
  boot.nix                     systemd-boot signed by lanzaboote (Secure Boot), latest kernel
  bootvine.nix                 live systemd boot screen (from bootvine's own flake)
  storage.nix                  btrfs auto-scrub
  snapshots.nix                daily btrfs snapshots of /home (btrbk)
  secrets.nix                  oo7 as the only Secret Service (+ PAM unlock, portal)
  nix.nix                      nix settings, flake registry, GC, nh
  nvidia.nix                   PRIME offload (Intel iGPU + NVIDIA dGPU), open kernel modules
  power-sleep.nix              lid/power key, suspend-then-hibernate, power profile
  oom.nix                      earlyoom: kills a runaway process before the machine freezes
  performance.nix              sched_ext scheduler, zram memory tuning, BBR networking
  audio-bluetooth.nix          PipeWire, Bluetooth
  desktop.nix                  greetd + tuigreet (login), Hyprland, portals, udisks
  podman.nix                   rootless Podman with docker compat
  stylix.nix                   theme, fonts, opacity
  users.nix                    user account, zsh, sudo-rs
home/                          home-manager modules, one topic per file
  shell.nix  git.nix  cli.nix  session.nix  hyprland.nix
  lock-idle.nix                lock screen (hyprlock) and idle behaviour (hypridle)
  bar.nix                      ashell: bar, notifications, volume/brightness overlay
  lib/hyprland-bind.nix        helpers for Hyprland key bindings (used by hyprland.nix, desktop-extras.nix)
  editor/neovim/               nixvim, one file per topic (see the Editor section)
  yazi.nix                     Yazi file manager
  identity.nix                 name + email, shared by git.nix and jujutsu.nix
  jujutsu.nix                  jj (colocated with git), jjui, SSH agent
  desktop-scripts.nix          power menu, screenshots (+ editor), clipboard and emoji pickers, wdisplays
  desktop-extras.nix           optional: night light, colour picker, screen recorder
  battery-warning.nix          notification at 20% and 10% battery
  window-switcher.nix          alt-tab window switcher (hyprshell)
  ghostty-cursor.nix           animated cursor trail in Ghostty (custom shader)
docs/                          Neovim docs, devshell contract, jj and oo7 notes
assets/nix-bg.png              wallpaper used by Stylix
```

## Installation

Pick one of two paths, then turn on Secure Boot (C):

| | Path | Data on disk |
| --- | --- | --- |
| **A** | Switch the NixOS that is already on this laptop to this config | kept, nothing is reformatted |
| **B** | Install from the NixOS installer USB with disko | **erased** |
| **C** | Turn on Secure Boot (lanzaboote, your own keys), after A or B | kept |

Before you start, for both paths:

- Plug in the charger and have a working network connection. The first build downloads most
  packages from cache.nixos.org and compiles bootvine and lanzaboote locally, so allow some time.
- Have a backup of anything you cannot lose. Path A does not reformat, but it does change the
  boot path (bootvine shows the passphrase prompt).
- The flake output is called `g15`. Every command below names it as `.#g15`.

### A. On a NixOS install that already uses this disk layout (nothing is reformatted)

Use this to move an existing NixOS on this laptop to the current config, for example after
reinstalling it from path B. The config finds the disks by the partition labels `hosts/g15/disko.nix`
gives them; a machine partitioned some other way needs path B.

1. Clone the repository where `nh` expects it (`programs.nh.flake` in `modules/nixos/nix.nix`):

   ```bash
   git clone https://github.com/mateusbl/nix-config-g15 ~/Code/nix-config
   ```

   ```bash
   cd ~/Code/nix-config
   ```

2. **Check the partition labels.** The list must show `disk-main-ESP`, `disk-main-swap` and
   `disk-main-root`:

   ```bash
   lsblk -o NAME,PARTLABEL,FSTYPE,SIZE,MOUNTPOINTS
   ```

   If they are missing, stop here and use path B: the new system would not find its disks.

3. **Try it without touching the boot menu.** `nh` is not installed yet, so `nix-shell` fetches it
   just for this command (the `NIX_CONFIG` part turns on flakes in case they are still off).
   `test` activates the new system until the next reboot, so a plain reboot brings the old one back:

   ```bash
   NIX_CONFIG="experimental-features = nix-command flakes" nix-shell -p nh --run "nh os test -H g15 ."
   ```

   `nh` shows which packages change and asks for your password itself. Without `nh`, the same
   step is `sudo nixos-rebuild test --flake .#g15`.

4. Log out and back in at the login screen, so the new session services start. Look around: the bar, the
   launcher (`SUPER+D`), a terminal, sound, Wi-Fi. Two quick checks for things you cannot see:

   ```bash
   systemctl --failed
   ```

   ```bash
   systemctl --user --failed
   ```

   Both should list 0 units.

5. **Make it permanent** (this adds the boot entry). The test system already contains `nh`, so
   the `nrs` alias works now; if it is not found yet, use the `nix-shell` form:

   ```bash
   nrs
   ```

   ```bash
   NIX_CONFIG="experimental-features = nix-command flakes" nix-shell -p nh --run "nh os switch -H g15 ."
   ```

   The boot screen and the passphrase prompt change with this step (bootvine).

6. Reboot once and confirm the passphrase prompt, login and hibernation work.

7. Turn on Secure Boot: [C. Turn on Secure Boot](#c-turn-on-secure-boot-after-path-a-or-b).

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

2. **Boot it.** If Secure Boot is on, turn it off first (`F2` at the Dell logo → Boot
   Configuration): the installer is not signed with your keys. Then plug the stick in, power on,
   press `F12` at the Dell logo and pick the stick under *UEFI Boot*. Close the graphical
   installer window if it opens: it is not used.

3. **Network and terminal.** Connect to Wi-Fi from the menu in the top-right corner. Open the
   *Console* app. Check the connection:

   ```bash
   ping -c 3 nixos.org
   ```

4. **Get the repository.** The first command opens a shell that has `git` and `nom`
   (nix-output-monitor, which shows the install's build progress in step 7); stay in it until the
   end.

   ```bash
   nix-shell -p git nix-output-monitor
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
   `hosts/g15/disko.nix` (`nano hosts/g15/disko.nix`).

   Then write this machine's RAM into the config. The swap partition is sized from it (RAM +
   2 GiB), so hibernation fits without reserving more disk than needed:

   ```bash
   sed -i "s/my.disk.ramGiB = [0-9]*;/my.disk.ramGiB = $(awk '/MemTotal/ {print int(($2 + 1048575) / 1048576)}' /proc/meminfo);/" hosts/g15/default.nix
   ```

   ```bash
   grep ramGiB hosts/g15/default.nix
   ```

   It should show the RAM in GiB, rounded up (16 for 16 GiB).

6. **Partition, encrypt, format and mount.** This is the step that erases the disk. It asks you
   to choose a passphrase for the swap partition and then for the root partition. Use the same
   one for both, so the boot asks only once.

   ```bash
   sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko/latest -- --mode destroy,format,mount --flake .#g15
   ```

   Check the result: `/mnt`, `/mnt/boot`, `/mnt/home` and `/mnt/nix` must be listed.

   ```bash
   findmnt -R /mnt
   ```

7. **Install.** `nh` cannot install onto a new disk, so this step uses NixOS's own installer. It
   downloads the system and compiles bootvine and lanzaboote, so it takes a while. Its build output
   goes through `nom`, the same progress tree `nh` shows:

   ```bash
   sudo nixos-install --flake .#g15 --no-root-passwd --log-format internal-json -v |& nom --json
   ```

   - `--log-format internal-json -v` makes Nix print machine-readable progress, which
     `nom --json` draws as a tree. `|&` sends both output streams to `nom`.
   - `--no-root-passwd` skips the root password prompt at the end, which would be hidden behind
     `nom`. No root password is needed: your user is an admin through the `wheel` group, and
     step 8 sets its password.
   - Without `nom`, plain `sudo nixos-install --flake .#g15` works too (it then asks for a root
     password at the end).

8. **Set your own password.** The config sets none on purpose, and without one you cannot log in:

   ```bash
   sudo nixos-enter --root /mnt -c 'passwd mateus'
   ```

9. **Take the repository with you**, including the edits from step 5, to the place `nh`
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

10. **Reboot into the new system** and pull the stick out when the screen goes dark:

    ```bash
    reboot
    ```

    bootvine asks for the disk passphrase, then the login screen (tuigreet) asks for user `mateus` and the password from
    step 8. Hyprland starts after login. `SUPER + Return` opens a terminal.

11. **Finish.** Connect to Wi-Fi from the bar (click the icons on the right). Then confirm that
    rebuilding works from the installed system (`nh` is installed now, so the aliases work) and
    record the edits from step 5:

    ```bash
    cd ~/Code/nix-config
    ```

    ```bash
    nrt
    ```

    ```bash
    git commit -am "g15: installed with disko"
    ```

12. **Secure Boot:** continue with [C. Turn on Secure Boot](#c-turn-on-secure-boot-after-path-a-or-b).

If something goes wrong:

- **disko or `nixos-install` stops with an error:** nothing is bootable yet, but both can simply be
  run again from the same terminal after fixing the cause.
- **The new system does not boot or you cannot log in:** boot the USB stick again, repeat steps 3
  to 5, then mount the installed system without formatting (`--mode mount` instead of
  `--mode destroy,format,mount` in the command of step 6). After that, `nixos-install` and
  `nixos-enter` from steps 7 and 8 work again.

### C. Turn on Secure Boot (after path A or B)

The system already boots through lanzaboote (signed systemd-boot, `modules/nixos/boot.nix`), but the
firmware does not check signatures until you enroll your keys and switch Secure Boot on. Do this
once, after the first switch (path A) or the first boot of the new system (path B). Your keys are
created automatically at that first boot (`/var/lib/sbctl`).

1. **Sign everything with the new keys, then check.** The very first install could not sign yet,
   because the keys did not exist; this `nrs` signs everything:

   ```bash
   nrs
   ```

   ```bash
   sudo sbctl status
   ```

   ```bash
   sudo sbctl verify
   ```

   `status` must show your keys as installed. `verify` lists the boot files: everything must be
   signed except the files under `EFI/nixos/` whose names start with `kernel-`. Those are expected
   to show as not signed: the signed generation file in `EFI/Linux/` holds a hash of its kernel and
   checks it before loading it. If anything else is not signed, run `nrs` again before going on.

2. **Put the firmware in Setup Mode.** Reboot, press `F2` at the Dell logo and open **Boot
   Configuration**. Under **Expert Key Management**, switch **Enable Custom Mode** on, select **PK**
   in "Custom Mode Key Management", press **Delete**, then **APPLY CHANGES** and **EXIT**.
   - Leave "Deployed Mode" selected and Secure Boot itself off for now.
   - Do not press "Reset All Keys": it puts Dell's Platform Key back and you leave Setup Mode.

   Back in NixOS, check that the firmware is now in Setup Mode:

   ```bash
   sudo sbctl status
   ```

   It must say `Setup Mode: ✗ Enabled` (the ✗ only means "not protected yet") and no longer list
   `builtin-PK`.

3. **Enroll your keys, together with Microsoft's and Dell's:**

   ```bash
   sudo sbctl enroll-keys --microsoft --firmware-builtin
   ```

   Your key becomes the Platform Key, so only you decide which keys are trusted. Keep
   `--microsoft`: the NVIDIA card's own firmware is signed by Microsoft, and without that key the
   firmware can refuse it and the laptop may not show a picture at all. `--firmware-builtin` also
   keeps the keys the firmware shipped with (Dell's), so what Dell signed for this laptop keeps
   working. Afterwards `sudo sbctl status` shows `Setup Mode: ✓ Disabled` and lists `microsoft`
   and `builtin-db`/`builtin-KEK`.

   If it stops with `File is immutable: /sys/firmware/efi/efivars/…`, the kernel is protecting
   those variables from accidental changes. Remove that protection for the files it names (the
   command fetches `chattr`, which is not installed), then run `enroll-keys` again:

   ```bash
   sudo "$(nix build --no-link --print-out-paths nixpkgs#e2fsprogs.bin)/bin/chattr" -i /sys/firmware/efi/efivars/KEK-8be4df61-93ca-11d2-aa0d-00e098032b8c /sys/firmware/efi/efivars/db-d719b2cb-3d3a-4596-a3bc-dad00e67656f
   ```

4. **Turn Secure Boot on:** reboot, `F2`, Boot Configuration, enable **Secure Boot**, APPLY
   CHANGES, EXIT.

5. **Check** once NixOS is up:

   ```bash
   bootctl status
   ```

   It must say `Secure Boot: enabled (user)`.

If the laptop refuses to boot after step 4, go back into the firmware (`F2`) and turn Secure Boot
off: the system starts exactly as before, with your keys still enrolled. To start over with Dell's
original keys, use "Reset All Keys" in the same menu (with Secure Boot off).

After a reinstall (path B) the old keys were erased with the disk while the firmware still has
them, so repeat this whole section: Setup Mode, enroll the new keys, Secure Boot on.

### After either install

- **SSH key:** the config creates none. Make one with `ssh-keygen -t ed25519` and add the public key
  to your Git host. The first use in a session asks for its passphrase once.
- **Projects:** run `direnv allow` once in each project that has an `.envrc`. `docs/devshell-contract.md`
  lists what a project's devenv must provide for Neovim.
- **Secrets:** oo7 creates its keyring at the first login. Verification steps are in `docs/oo7-notes.md`.
- **Secure Boot:** off until you do [C. Turn on Secure Boot](#c-turn-on-secure-boot-after-path-a-or-b).

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
Nothing is throttled to save battery: the panel stays at 120 Hz and Wi-Fi power saving is off (set explicitly; the kernel default has it on).

- **Power profile:** every boot starts in `balanced`, on the charger and on battery. The bar's settings panel has a button to change it by hand (`performance` for games or builds); that lasts until the next reboot.
- **Low-battery safety net (UPower):** low at 20%, critical at 10%, hibernate at 5%. A notification
  warns at 20% and again (critical) at 10% (`home/battery-warning.nix`).
- Idle behaviour: dim after 5 min, lock after 10, screen off after 11, suspend-then-hibernate after 30 (and on lid close after 2 h of sleep).

## Out of memory

`modules/nixos/oom.nix` runs earlyoom. When less than 10% of RAM is available and less than 20% of swap
is free, it ends the biggest process (SIGTERM, then SIGKILL at half those values) instead of letting the
desktop freeze. It avoids the session (Hyprland, ashell, PipeWire, oo7, ...), prefers browser tab
processes, and sends a desktop notification naming what it killed.

## Disks (disko)

`hosts/g15/disko.nix` declares the whole disk:

| Partition | Size        | Contents                                                                                 |
| --------- | ----------- | ---------------------------------------------------------------------------------------- |
| ESP       | 1 GiB       | vfat → `/boot` (`fmask=0077,dmask=0077`)                                                 |
| swap      | RAM + 2 GiB | LUKS (`cryptswap`) → swap, also `boot.resumeDevice` for hibernation                      |
| root      | rest        | LUKS (`cryptroot`) → btrfs: top level `/`, subvolumes `home` → `/home`, `nix` → `/nix`  |

Every btrfs mount uses `compress=zstd,noatime`. These options used to be in `storage.nix`.

The swap size follows the RAM: `my.disk.ramGiB` (in `hosts/g15/default.nix`) plus
`my.disk.swapOffsetGiB` (2 GiB by default). Nix cannot read the RAM itself, so path B of the
install guide writes the real value just before partitioning. The sizes are only used when disko
partitions a disk; changing them on an installed machine changes nothing.

The laptop is installed with this layout: the config finds the partitions by the GPT labels disko
gives them (`disk-main-ESP`, `disk-main-swap`, `disk-main-root`), not by UUID.

A fresh install with disko is described step by step under [Installation](#installation), path B.

## NVIDIA

PRIME offload: the Intel iGPU drives the desktop and the RTX 3050 sleeps until you need it.
The basics come from nixos-hardware profiles in `flake.nix`: the TigerLake profile (Intel video drivers,
microcode, GuC/HuC firmware for the iGPU with `i915.enable_guc=3`) and `common-gpu-nvidia` (driver,
PRIME offload, `nvidia-offload`, nouveau blacklisted). `modules/nixos/nvidia.nix` adds the bus IDs,
power management, 32-bit graphics and the open kernel modules.
Run a program on the dGPU with:

```bash
nvidia-offload <program>
```

The bus IDs (`PCI:0:2:0` and `PCI:1:0:0`) come from `lspci | grep -E "VGA|3D"`.

The kernel modules are NVIDIA's open-source ones (`hardware.nvidia.open = true`), which NVIDIA
recommends for this card. If the card misbehaves after a driver update, set it back to `false` in
`modules/nixos/nvidia.nix` to try the closed modules. Check which one is loaded with:

```bash
modinfo -F license nvidia
```

`Dual MIT/GPL` means open, `NVIDIA` means closed.

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

## Secure Boot (lanzaboote)

The boot loader is systemd-boot, installed and signed by
[lanzaboote](https://github.com/nix-community/lanzaboote) (`modules/nixos/boot.nix`). Each
generation becomes one signed file (kernel, initrd and command line together), so with Secure Boot
on, the firmware only starts what your keys signed. The boot menu, the 10-generation limit and
rollbacks work as before, and editing the kernel command line from the menu is off.

- **Source:** the `lanzaboote` input in `flake.nix`, pinned to release v1.2.0 and compiled on this
  machine (it is not in nixpkgs). Its Cachix is not used, like bootvine's.
- **Keys:** your own, in `/var/lib/sbctl`, created automatically at the first boot after switching
  (`generate-sb-keys.service`). Until they exist, lanzaboote installs unsigned files, which still
  boot while Secure Boot is off. Never put these keys in git.
- **NVIDIA and hibernation keep working:** nothing in this config turns on kernel lockdown or forced
  module signatures, which are what would block them.

### Turning it on

The steps are part of the install guide: [C. Turn on Secure Boot](#c-turn-on-secure-boot-after-path-a-or-b).
Updates need nothing extra afterwards: every `nrs` signs the new generation.

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

**Cheat sheet.** Leader is **Space**: press it and wait, and which-key shows what comes next.
The most used keys (the full list, with the VS Code equivalents, is in `docs/neovim-cheatsheet.md`):

| What | Keys |
| --- | --- |
| Find file | `<C-p>`, `<leader><space>`, `<leader>ff` |
| Recent files | `<leader>fr` |
| Search text in the project | `<leader>/`, `<leader>sg` |
| Search and replace in the project | `<leader>sr` |
| Open buffers / previous / next | `<leader>,` / `<S-h>` / `<S-l>` |
| File tree / edit folder as text | `<leader>e` / `-` |
| Go to definition / references | `gd` / `gr` |
| Hover docs | `K` |
| Rename symbol | `<F2>`, `<leader>cR` |
| Code action (quick fix) | `<C-.>`, `<leader>ca` |
| Format file (also on save) | `<leader>cf` |
| Problems list / next problem | `<leader>xx` / `]d` |
| Comment line | `gcc` |
| Move line down / up | `<A-j>` / `<A-k>` |
| Save | `<C-s>` |
| Debug: start / breakpoint / step over / into | `<F5>` / `<F9>` / `<F10>` / `<F11>` |
| Test at cursor / tests in file | `<leader>tr` / `<leader>tt` |
| Run a task (tasks.json, npm, ...) | `<leader>or` |
| Git (lazygit) / blame line | `<leader>gg` / `<leader>gb` |
| Terminal | `<C-/>`, `<leader>ft` |
| Project tools found (devshell status) | `<leader>cD` |
| Restore last session for this folder | `<leader>qs` |
| Undo history | `<leader>uu` |

**Docs:**
- `docs/neovim-cheatsheet.md`: VS Code action → key
- `docs/neovim-decisions.md`: why things are the way they are, and open questions

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
  `SUPER+E` (opens it in Ghostty). It is the only file manager.
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
| `ALT+Tab` / `ALT+SHIFT+Tab` | window switcher with previews, most recent first; release `ALT` to switch, `q` closes the selected window |
| `SUPER+1`…`SUPER+0` | workspaces 1–10; with `SHIFT`, move the window there |
| three-finger swipe left/right | previous / next workspace |
| `SUPER+Escape` | lock |
| `SUPER+SHIFT+Escape` | power menu (fuzzel): lock, suspend, hibernate, reboot, poweroff, logout. Nothing happens unless you pick one |
| `Print` | region screenshot to the clipboard |
| `Shift+Print` / `Ctrl+Print` | region / full screen to `~/Pictures/Screenshots`, with a notification |
| `SUPER+Print` | region opened in satty to draw arrows, text or blur; `Ctrl+S` saves, `Ctrl+C` copies |
| `SUPER+SHIFT+V` | clipboard history (cliphist, started with the session) |
| `SUPER+.` | emoji picker (fuzzel): types the emoji and copies it |
| `XF86AudioPlay/Next/Prev` | media control via playerctl, sent to the last used player (playerctld) |
| Volume / brightness / mute keys | change the value and show it in ashell's on-screen display (5% steps, volume up to 150%) |
| `SUPER+M` | log out |

- The bar is ashell (`home/bar.nix`): workspaces, window title, CPU/memory/temperature, tray, clock (click for a calendar) and a settings group. Clicking the settings group opens a panel for volume, Wi-Fi, Bluetooth, brightness, power profile and lock/suspend/hibernate/reboot/poweroff/logout. Right-clicking the speaker opens pwvucontrol (volume mixer); right-clicking Bluetooth opens overskride (pairing).
- Notifications are ashell's too: popups in the top-right corner, and the bell in the bar keeps the list (click it to see them, right-click for do not disturb). They are kept in memory until you log out.
- Wi-Fi and Bluetooth are handled in that panel; there are no separate tray applets. Bluetooth is on from boot; turn it off there when you don't need it. For VPNs or editing a connection use `nmtui` in a terminal.
- Login: greetd runs tuigreet, a text login prompt in the palette colours, which remembers the last user and session. After login, home-manager starts the session services (bar, idle, wallpaper, clipboard, ...) with Hyprland and stops them when you log out; there is no UWSM.
- Browser: LibreWolf (Firefox with privacy and security settings on by default, uBlock Origin included). It deletes cookies and history when it closes; change that in its Settings → Privacy & Security if you want to stay logged in.
- The lock screen (hyprlock, `SUPER+Escape`) shows the time, the date, a greeting and the battery level over the wallpaper, in the palette colours (`home/lock-idle.nix`).
- The launcher is fuzzel (`SUPER+D`). The power menu, the clipboard picker and the emoji picker use it too.
- Keyboard: US with accents on `AltGr` (right Alt): `AltGr+,` = ç, `AltGr+'` then a vowel = á, `AltGr+~` then a = ã. Plain `'` and `"` still type at once.
- Ghostty draws a short fading streak when the cursor jumps (not while typing); see `home/ghostty-cursor.nix`.
- `wdisplays` arranges monitors visually. It does not save anything: copy the resulting positions into the monitor list in `home/hyprland.nix`.
- Small utility windows float centred instead of tiling: the mixer, Bluetooth manager, screenshot editor, wdisplays and file dialogs (`window_rule` in `home/hyprland.nix`).
- Optional, off by default, in `home/desktop-extras.nix`:
  - `my.desktop.nightLight.enable`: hyprsunset, warmer colours from 20:00.
  - `my.desktop.colorPicker.enable`: hyprpicker on `SUPER+SHIFT+C`.
  - `my.desktop.screenRecorder.enable`: wf-recorder on `SUPER+SHIFT+R`. It records a region and encodes on the CPU, so it works with the NVIDIA hybrid setup.

## Secrets: oo7

`modules/nixos/secrets.nix` makes [oo7](https://github.com/linux-credentials/oo7) the only Secret
Service. The keyring unlocks with your login password (greetd's PAM service includes `login`, which has pam_oo7). The CLI is `oo7-cli` (store / lookup /
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

- **sched_ext scheduler:** `scx_lavd` through `services.scx-loader`. Made for laptops and handhelds
  (the Steam Deck): it keeps the desktop, audio and games responsive while a build uses every core,
  and it is power-aware. The kernel falls back to its built-in scheduler by itself if a sched_ext
  scheduler misbehaves. `scxctl get` shows what is running; `scxctl switch --sched bpfland` tries
  another one until the next boot.
- **Memory:** the sysctl values recommended for zram (swap idle pages to compressed RAM early).
- **Network:** BBR congestion control with the `fq` queueing discipline.

Deliberately not done: disabling CPU security mitigations, and putting `/tmp` in RAM (large local
builds would run out of memory).

## Security settings

- **sudo-rs** instead of sudo, usable only by the `wheel` group (`modules/nixos/users.nix`).
- **Nix daemon:** only `wheel` members may build or add to the store (`allowed-users` in
  `modules/nixos/nix.nix`).
- **`/tmp` is emptied at every boot** (`boot.tmp.cleanOnBoot` in `modules/nixos/boot.nix`).
- Also: Secure Boot with your own keys (lanzaboote), full-disk encryption (LUKS), nftables
  firewall, rootless Podman, oo7 as the only keyring, and LibreWolf as the browser.

## Nix builds

Builds run at idle CPU and disk priority (`nix.daemonCPUSchedPolicy` / `daemonIOSchedClass` in
`modules/nixos/nix.nix`), so the desktop stays usable while something compiles.

## Binary caches

Only `cache.nixos.org` is used. `accept-flake-config = false` in `modules/nixos/nix.nix`
stops flakes from adding their own substituters, which is what keeps the Cachix caches of the
bootvine and lanzaboote flakes out. To add a cache on purpose, set `extra-substituters` and `extra-trusted-public-keys` there. To
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

**CI** (`.github/workflows/ci.yml`) runs on every pull request and every push to `main`: the
nixfmt formatting check and `nix flake check --no-build`. It evaluates only; it does not build the
system. It currently does not start at all because of a billing problem on the GitHub account.

There are no automated tests of the running machine or of the Neovim config. After a switch,
`systemctl --failed` and `systemctl --user --failed` show services that did not start.

## License

GPL-3.0, see [LICENSE](LICENSE).
