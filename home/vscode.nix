# VS Code, kept until the Neovim acceptance checklist passes (see docs/questions.md).
#
# Plain pkgs.vscode, not vscode-fhs: no FHS shims in this config (CLAUDE.md). Extensions
# come only from nixpkgs (pkgs.vscode-extensions). Marketplace extensions that ship
# prebuilt binaries may therefore not run; that is accepted.
{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    # Extensions are read-only and come only from the list below. home-manager defaults
    # this to true when there is a single profile, so it is set explicitly.
    mutableExtensionsDir = false;

    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;

      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide # Nix language support (uses nil + nixfmt from the system)
        mkhl.direnv # applies your direnv / devenv environment inside the editor
        vscodevim.vim # keep the Vim motions you learned in Neovim
      ];

      userSettings = {
        # Nix
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.serverSettings".nil.formatting.command = [ "nixfmt" ];
        "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";

        # Editor behaviour
        "editor.formatOnSave" = true;
        "files.autoSave" = "onFocusChange";
        "telemetry.telemetryLevel" = "off";
        "update.mode" = "none";
        "extensions.autoUpdate" = false;
        "extensions.autoCheckUpdates" = false;

        # Vim extension: share the system clipboard like Neovim did
        "vim.useSystemClipboard" = true;
        "vim.leader" = "<space>";
      };
    };
  };

  # Stylix themes VS Code through this profile. Set `stylix.targets.vscode.enable = false;`
  # instead if you would rather pick a theme inside the editor.
  stylix.targets.vscode.profileNames = [ "default" ];
}
