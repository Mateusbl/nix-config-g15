# Formatting engine (conform.nvim). Per-language formatters are set in languages/*.nix.
_:

{
  programs.nixvim = {
    plugins = {
      # --- Formatting (binaries come from PATH / devenv) ---
      conform-nvim = {
        enable = true;
        settings = {
          format_on_save.__raw = ''
            function(bufnr)
              if not vim.g.autoformat then
                return
              end
              return { timeout_ms = 500, lsp_format = "fallback" }
            end
          '';
        };
      };
    };
    keymaps = [
      # --- Formatting ---
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>cf";
        action.__raw = "function() require('conform').format({ async = true, lsp_format = 'fallback' }) end";
        options.desc = "Format Document";
      }
      {
        mode = "n";
        key = "<leader>uf";
        action.__raw = "function() vim.g.autoformat = not vim.g.autoformat; vim.notify('Autoformat: ' .. tostring(vim.g.autoformat)) end";
        options.desc = "Toggle Auto Format";
      }
    ];
  };
}
