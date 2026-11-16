# Questions for the owner

Decisions only you can make. Until you answer, the config uses the default given here.

## Editors

1. **VS Code: delete, or keep a plain `pkgs.vscode`?**
   It is now plain `pkgs.vscode` (no vscode-fhs) with read-only, nixpkgs-only extensions
   (nix-ide, direnv, vim). Once the Neovim acceptance checklist passes, should
   `home/vscode.nix` be deleted, or kept as a fallback?
   *Default: keep it; it will not be deleted before you confirm the checklist.*
2. **Angular.** Do you use Angular anywhere? If yes, angularls can come back as a project
   server (one line in `home/editor/neovim/languages/web.nix` plus `@angular/language-server`
   in that devenv). *Default: no angularls.*
3. **Neovim startup on the laptop.** Run `nvim --startuptime /tmp/nvim.log +qa` and read the last line of `/tmp/nvim.log`. If it
   is above 80 ms, do you want lazy-loading (more config per plugin)? *Default: no lazy-loading.*
4. **Django test runner.** pytest-django or `manage.py test`?
   *Default: pytest (`my.neovim.languages.python.testRunner = "pytest"`).*
5. **Spring Boot language server.** Is STS4 support (Spring-aware completion in
   `application.properties`, bean navigation) worth packaging its jar per project with
   `fetchurl`, like the JUnit jar? It is not in nixpkgs. *Default: not set up.*
6. **Ghostty keys.** Do `<C-S-p>`, `<C-S-f>` and `<C-S-m>` reach Neovim? If not, I can map
   them to other keys. *Default: keep them; the leader-key equivalents always work.*

## Yazi

7. **smart-enter on `l`?** The smart-enter plugin is meant to replace `l` (enter a directory
   *or* open a file). That changes a default key, so the tutorials would no longer match.
   *Default: smart-enter on `<C-l>`, `l` unchanged.*

## Baseline

8. **Off-disk backups: which target drive?** `/home` gets local btrfs snapshots (btrbk, hourly
   and daily, `modules/nixos/snapshots.nix`). They live on the same disk, so they don't help if
   the disk dies or the laptop is lost. btrbk can send them to an external btrfs drive or over
   SSH once you name a target. *Default: local snapshots only.*

## Power

9. **Bluetooth at boot.** `hardware.bluetooth.powerOnBoot = true` keeps the radio on after every boot.
   *Default: unchanged (on).*
10. **Disable cache.nixos.org too?** Only bootvine's extra Cachix is excluded (and it was never turned on).
    I kept cache.nixos.org, because without it every rebuild compiles everything locally, kernel and browsers
    included, for hours. If you want that anyway, set `nix.settings.substituters = [ ]` in
    `modules/nixos/nix.nix`. *Default: cache.nixos.org stays.*

## Repository

11. **"Remove all .sh and non nix files": how far?** The two shell scripts and the rest of `tests/` are gone. The
    remaining non-Nix files were kept because removing them loses something: `flake.lock` (pins
    every input), `home/editor/neovim/lua/*.lua` (loaded by Neovim; inlining them into Nix strings
    loses Lua highlighting and stylua), `assets/nix-bg.png` (wallpaper), `README.md`, `docs/*.md`,
    `CLAUDE.md`, `LICENSE`, `.gitignore`. Say which of these should go.
    *Default: keep them.*

## Desktop

12. **Drop the two tray applets?** ashell's settings panel already connects to Wi-Fi networks and
    toggles Bluetooth, so nm-applet and blueman-applet now partly duplicate it. They still add
    things the panel lacks: editing connections and VPNs (nm-applet) and pairing new devices
    (blueman). *Default: keep both.*
