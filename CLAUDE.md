# Rules for this repository

NixOS flake for a Dell G15: Hyprland (UWSM), Stylix, home-manager as a NixOS module.
Layout: `flake.nix`, `hosts/g15`, `modules/nixos/*`, `home/*`.

- Never install Claude Code: no `claude-code` package, no claudecode.nvim or other Claude Code integration.
- Don't guess option or package names: confirm them against the locked versions (`nix eval`, the source in the store).
- Only nixpkgs. No new flake inputs or substituters without asking. Allowed by the owner: the `bootvine` flake (codeberg) and the `lanzaboote` flake (Secure Boot), both compiled locally; its Cachix and every other binary cache beyond cache.nixos.org stay unused.
- Never install or enable: nix-ld; gh or similar imperative CLIs; FHS shims (vscode-fhs, buildFHSEnv wrappers, steam-run, appimage-run, Flatpak); Mason or any runtime downloader (sdkman, `npm -g`, `pip --user`, `cargo install`, `go install`, `ya pkg`, `:TSInstall`). Only exception: `programs.steam`. If a task seems to need one of these, ask.
- Neovim is configured only through nixvim (`home/editor/neovim`). Project toolchains (JDK, Maven/Gradle, jdtls, Python, debugpy, pyright/ruff, Node, tsserver, eslint/prettier, Tailwind LS, debug adapters, test runners) come from each project's devenv, never from the editor config. Editor-owned: UI, keymaps, plugins, generic wiring and language-agnostic tools (nil, nixfmt, lua-language-server, stylua, bash-language-server, shellcheck, shfmt, YAML/JSON/TOML/Markdown/Docker servers).
- The Secret Service is oo7 only. Version control is jj + git over SSH; no gh.
- Don't touch hardware, nvidia or boot modules unless asked.
- Anything needing the owner's decision goes in `docs/questions.md`; continue with the safest default.
- README describes only what exists now. Keep modules small and commented with the *why*; the owner is learning.
- Before committing: `nix flake check` and `nix build .#nixosConfigurations.g15.config.system.build.toplevel` must pass.
