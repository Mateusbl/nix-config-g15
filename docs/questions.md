# Questions for the owner

Decisions only you can make. Until you answer, the config uses the default given here.

Answered and applied: VS Code deleted; Angular supported; no Neovim lazy-loading, pytest as the
Django runner, no Spring Boot language server and the Ghostty keys kept as they are; no
smart-enter in Yazi; Bluetooth off at boot; tray applets dropped; Thunar removed; Neovim's Lua
helpers moved into Nix files.

## Baseline

1. **Off-disk backups: which target drive?** `/home` gets local btrfs snapshots (btrbk, hourly
   and daily, `modules/nixos/snapshots.nix`). They live on the same disk, so they don't help if
   the disk dies or the laptop is lost. btrbk can send them to an external btrfs drive or over
   SSH once you name a target. *Default: local snapshots only.*

## Nix

2. **Disable cache.nixos.org too?** Cachix is not used: bootvine's extra cache was never turned
   on, and `accept-flake-config = false` keeps flakes from adding one. cache.nixos.org is the
   official NixOS cache, not Cachix. Without it every rebuild compiles everything locally, kernel
   and browsers included, for hours. To do that anyway, set `nix.settings.substituters = [ ]` in
   `modules/nixos/nix.nix`. *Default: cache.nixos.org stays.*

## Repository

3. **Remaining non-Nix files.** Kept because removing them loses something: `flake.lock` (pins
   every input), `assets/nix-bg.png` (wallpaper), `README.md`, `docs/*.md`, `CLAUDE.md`,
   `LICENSE`, `.gitignore`. Say which of these should go. *Default: keep them.*
