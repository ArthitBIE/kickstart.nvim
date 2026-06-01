local gh = function(repo) return 'https://github.com/' .. repo end

-- 1. nvim-ts-autotag for auto-closing/renaming HTML/JSX/TSX tags
vim.pack.add { gh 'windwp/nvim-ts-autotag' }
require('nvim-ts-autotag').setup {
  opts = {
    enable_close = true,          -- Auto close tags
    enable_rename = true,         -- Auto rename pairs of tags
    enable_close_on_slash = false -- Auto close on trailing </
  }
}

-- 2. typescript-tools.nvim for JS/TS/JSX/TSX QoL
vim.pack.add {
  gh 'pmizio/typescript-tools.nvim',
  -- dependencies plenary and lspconfig are already loaded in init.lua
}
require('typescript-tools').setup {
  on_attach = function(client, bufnr)
    -- Disable formatting to use conform.nvim (prettier) instead
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false

    -- TS QoL buffer-local keymaps
    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'TS: ' .. desc })
    end
    map('<leader>co', '<cmd>TSToolsOrganizeImports<CR>', '[C]ode [O]rganize Imports')
    map('<leader>cr', '<cmd>TSToolsRenameFile<CR>', '[C]ode [R]ename File')
    map('<leader>ci', '<cmd>TSToolsAddMissingImports<CR>', '[C]ode Add Missing [I]mports')
    map('<leader>cu', '<cmd>TSToolsRemoveUnused<CR>', '[C]ode Remove [U]nused')
    map('<leader>ca', '<cmd>TSToolsFixAll<CR>', '[C]ode Fix [A]ll Issues')
  end,
  settings = {
    jsx_close_tag = {
      enable = true,
      filetypes = { 'javascriptreact', 'typescriptreact' },
    },
    tsserver_file_preferences = {
      includeInlayParameterNameHints = 'all',
      includeInlayFunctionParameterTypeHints = true,
      includeInlayVariableTypeHints = false,
      importModuleSpecifierPreference = 'non-relative',
    },
  },
}
