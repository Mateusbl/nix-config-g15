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
3. **Neovim startup on the laptop.** Run `tests/nvim-smoke.sh` and look at the last line. If it
   is above 80 ms, do you want lazy-loading (more config per plugin)? *Default: no lazy-loading.*
4. **Django test runner.** pytest-django or `manage.py test`?
   *Default: pytest (`my.neovim.languages.python.testRunner = "pytest"`).*
5. **Spring Boot language server.** Is STS4 support (Spring-aware completion in
   `application.properties`, bean navigation) worth packaging its jar per project with
   `fetchurl`, like the JUnit jar? It is not in nixpkgs. *Default: not set up.*
6. **Ghostty keys.** Do `<C-S-p>`, `<C-S-f>` and `<C-S-m>` reach Neovim? If not, I can map
   them to other keys. *Default: keep them; the leader-key equivalents always work.*
