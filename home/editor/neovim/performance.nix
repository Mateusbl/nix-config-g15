# Startup speed. These are nixvim features; none changes what the editor does.
{
  programs.nixvim = {
    # Neovim's own module cache (vim.loader): Lua modules are found and loaded faster.
    luaLoader.enable = true;

    performance = {
      # The generated init.lua and lua/*.lua files are compiled to bytecode at build time.
      # Plugins are left as they come from cache.nixos.org: compiling them means rebuilding
      # every plugin locally (and running their test suites).
      byteCompileLua = {
        enable = true;
        configs = true;
        initLua = true;
      };
      # All plugins are merged into one directory, so 'runtimepath' has one entry instead
      # of ~60 and every runtime file lookup is faster.
      combinePlugins = {
        enable = true;
        # Kept separate instead of merged:
        # - overseer, nvim-jdtls, conform, blink.cmp: ship a file with the same path as
        #   another plugin (doc/recipes.md, lsp/jdtls.lua), which the merge refuses.
        # - blink.cmp, neotest-python, friendly-snippets, nvim-treesitter: need folders the
        #   merge does not copy (target/, neotest_python/, snippets/, runtime/).
        standalonePlugins = [
          "overseer.nvim"
          "nvim-jdtls"
          "conform.nvim"
          "blink.cmp"
          "neotest-python"
          "friendly-snippets"
          "nvim-treesitter"
        ];
      };
    };
  };
}
