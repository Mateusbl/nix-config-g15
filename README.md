# nix-config-g15

My NixOS flake for a **Dell G15 5511** (Intel TigerLake-H + NVIDIA RTX 3050 Mobile).

- **Desktop:** Hyprland (Lua config) started through UWSM, with the `ly` display manager, Waybar, Rofi, Mako, hyprlock/hypridle and Ghostty
- **Theme:** Stylix with a custom palette based on the NixOS logo colours (`assets/nix-bg.png`)
- **Disks:** declared with [disko](https://github.com/nix-community/disko): LUKS + btrfs, plus encrypted swap used for hibernation
- **User environment:** home-manager as a NixOS module. VS Code is the main editor; nixvim is kept as a fallback

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
  shell.nix  git.nix  cli.nix  session.nix  hyprland.nix  vscode.nix  neovim.nix
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

- **VS Code** (`home/vscode.nix`): the FHS build, so extensions with native binaries work. It comes with nix-ide (nil + nixfmt), direnv and vim. Stylix themes it.
- **nixvim** (`home/neovim.nix`): the old Neovim setup, kept as a fallback. To remove it, delete the `nixvim` input, the `sharedModules` line in `flake.nix` and the `./neovim.nix` import in `home/default.nix`.

Project toolchains (language servers, formatters, JDKs…) come from each project's
`devenv`/direnv shell, not from the global config.

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

Known evaluation warnings that don't break anything:

- nixvim warns that its nixpkgs `follows` differs from its own pin. This goes away when nixvim is removed.
- Stylix sets `programs.rofi.font`, which is deprecated upstream.

## License

GPL-3.0, see [LICENSE](LICENSE).
