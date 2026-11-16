# Devshell layer: project tools (language servers, formatters, tests, debuggers) run
# inside the project's direnv/devenv environment. See lua/devshell.nix for how, and
# docs/devshell-contract.md for what each project's devenv has to provide.
#
# This replaces the direnv.vim plugin on purpose: direnv.vim changes Neovim's own
# environment on :cd, which cannot work with two projects open at the same time.
# Only one mechanism loads environments, so nothing is loaded twice.
{ config, ... }:

{
  programs.nixvim = {
    # Install lua/devshell.lua next to init.lua so `require("devshell")` finds it.
    extraFiles."lua/devshell.lua".text = import ./lua/devshell.nix;

    # Run early, so the commands and autocommands exist before any file is opened.
    # The direnv binary is the same one home/shell.nix installs for zsh.
    extraConfigLuaPre = ''
      require("devshell").setup({ direnv = "${config.programs.direnv.package}/bin/direnv" })
    '';

    keymaps = [
      {
        mode = "n";
        key = "<leader>cD";
        action = "<cmd>DevshellStatus<cr>";
        options.desc = "Devshell Status";
      }
    ];
  };
}
