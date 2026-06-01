-- ============================================================
-- Neovim configuration
-- Based on kickstart.nvim, simplified and refactored.
-- ============================================================

vim.loader.enable()

-- Helper for GitHub plugin URLs.
---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

-- ============================================================
-- Core settings
-- ============================================================

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Disable unused language providers to avoid healthcheck warnings.
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Set this to true if your terminal uses a Nerd Font.
vim.g.have_nerd_font = false

-- Register custom filetypes.
vim.filetype.add {
  extension = {
    gotmpl = 'gotmpl',
  },
  pattern = {
    ['.*%.gotmpl'] = 'gotmpl',
    ['.*%.tmpl'] = 'gotmpl',
  },
}

vim.o.number = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true

vim.opt.listchars = {
  tab = '» ',
  trail = '·',
  nbsp = '␣',
}

-- Delay clipboard setup because it can slow startup.
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

-- ============================================================
-- Diagnostics
-- ============================================================

vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = 'rounded',
    source = 'if_many',
  },
  underline = {
    severity = {
      min = vim.diagnostic.severity.WARN,
    },
  },
  virtual_text = true,
  virtual_lines = false,
  jump = {
    on_jump = function(_, bufnr)
      vim.diagnostic.open_float {
        bufnr = bufnr,
        scope = 'cursor',
        focus = false,
      }
    end,
  },
}

-- ============================================================
-- Basic keymaps
-- ============================================================

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', {
  desc = 'Clear search highlight',
})

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, {
  desc = 'Open diagnostic quickfix list',
})

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', {
  desc = 'Exit terminal mode',
})

vim.keymap.set('n', '<C-h>', '<C-w><C-h>', {
  desc = 'Move focus to the left window',
})

vim.keymap.set('n', '<C-l>', '<C-w><C-l>', {
  desc = 'Move focus to the right window',
})

vim.keymap.set('n', '<C-j>', '<C-w><C-j>', {
  desc = 'Move focus to the lower window',
})

vim.keymap.set('n', '<C-k>', '<C-w><C-k>', {
  desc = 'Move focus to the upper window',
})

-- ============================================================
-- Autocommands
-- ============================================================

-- Highlight text after yanking.
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight yanked text',
  group = vim.api.nvim_create_augroup('user-highlight-yank', { clear = true }),
  callback = function()
    if vim.hl and vim.hl.hl_op then
      vim.hl.hl_op()
    elseif vim.hl and vim.hl.on_yank then
      vim.hl.on_yank()
    elseif vim.highlight and vim.highlight.on_yank then
      vim.highlight.on_yank()
    end
  end,
})

-- ============================================================
-- vim.pack build hooks
-- ============================================================

local function run_build(name, cmd, cwd)
  local result = vim.system(cmd, { cwd = cwd }):wait()

  if result.code ~= 0 then
    local stderr = result.stderr or ''
    local stdout = result.stdout or ''
    local output = stderr ~= '' and stderr or stdout

    if output == '' then output = 'No output from build command.' end

    vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
  end
end

vim.api.nvim_create_autocmd('PackChanged', {
  desc = 'Run plugin build steps after install/update',
  callback = function(ev)
    local name = ev.data.spec.name
    local kind = ev.data.kind

    if kind ~= 'install' and kind ~= 'update' then return end

    if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
      run_build(name, { 'make' }, ev.data.path)
      return
    end

    if name == 'LuaSnip' then
      if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then run_build(name, { 'make', 'install_jsregexp' }, ev.data.path) end
      return
    end

    if name == 'nvim-treesitter' then
      if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end

      vim.cmd 'TSUpdate'
    end
  end,
})

-- ============================================================
-- UI and editor plugins
-- ============================================================

vim.pack.add {
  gh 'NMAC427/guess-indent.nvim',
  gh 'lewis6991/gitsigns.nvim',
  gh 'folke/which-key.nvim',
  gh 'catppuccin/nvim',
  gh 'folke/todo-comments.nvim',
  gh 'nvim-mini/mini.nvim',
}

if vim.g.have_nerd_font then vim.pack.add {
  gh 'nvim-tree/nvim-web-devicons',
} end

require('guess-indent').setup {}

require('gitsigns').setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
}

require('which-key').setup {
  delay = 0,
  icons = {
    mappings = vim.g.have_nerd_font,
  },
  spec = {
    { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
    { '<leader>t', group = '[T]oggle' },
    { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
    { 'gr', group = 'LSP Actions', mode = { 'n' } },
  },
}

require('catppuccin').setup {
  flavour = 'macchiato',
  background = {
    light = 'macchiato',
    dark = 'mocha',
  },
  term_colors = true,
}

vim.cmd.colorscheme 'catppuccin'

require('todo-comments').setup {
  signs = false,
}

require('mini.ai').setup {
  mappings = {
    around_next = 'aa',
    inside_next = 'ii',
  },
  n_lines = 500,
}

require('mini.surround').setup()

local statusline = require 'mini.statusline'

statusline.setup {
  use_icons = vim.g.have_nerd_font,
}

---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function() return '%2l:%-2v' end

-- ============================================================
-- Telescope
-- ============================================================

local telescope_plugins = {
  gh 'nvim-lua/plenary.nvim',
  gh 'nvim-telescope/telescope.nvim',
  gh 'nvim-telescope/telescope-ui-select.nvim',
}

if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end

vim.pack.add(telescope_plugins)

require('telescope').setup {
  extensions = {
    ['ui-select'] = {
      require('telescope.themes').get_dropdown(),
    },
  },
}

pcall(require('telescope').load_extension, 'fzf')
pcall(require('telescope').load_extension, 'ui-select')

local telescope_builtin = require 'telescope.builtin'

vim.keymap.set('n', '<leader>sh', telescope_builtin.help_tags, {
  desc = '[S]earch [H]elp',
})

vim.keymap.set('n', '<leader>sk', telescope_builtin.keymaps, {
  desc = '[S]earch [K]eymaps',
})

vim.keymap.set('n', '<leader>sf', telescope_builtin.find_files, {
  desc = '[S]earch [F]iles',
})

vim.keymap.set('n', '<leader>ss', telescope_builtin.builtin, {
  desc = '[S]earch [S]elect Telescope',
})

vim.keymap.set({ 'n', 'v' }, '<leader>sw', telescope_builtin.grep_string, {
  desc = '[S]earch current [W]ord',
})

vim.keymap.set('n', '<leader>sg', telescope_builtin.live_grep, {
  desc = '[S]earch by [G]rep',
})

vim.keymap.set('n', '<leader>sd', telescope_builtin.diagnostics, {
  desc = '[S]earch [D]iagnostics',
})

vim.keymap.set('n', '<leader>sr', telescope_builtin.resume, {
  desc = '[S]earch [R]esume',
})

vim.keymap.set('n', '<leader>s.', telescope_builtin.oldfiles, {
  desc = '[S]earch recent files',
})

vim.keymap.set('n', '<leader>sc', telescope_builtin.commands, {
  desc = '[S]earch [C]ommands',
})

vim.keymap.set('n', '<leader><leader>', telescope_builtin.buffers, {
  desc = 'Find existing buffers',
})

vim.keymap.set(
  'n',
  '<leader>/',
  function()
    telescope_builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
      winblend = 10,
      previewer = false,
    })
  end,
  {
    desc = 'Fuzzy search current buffer',
  }
)

vim.keymap.set(
  'n',
  '<leader>s/',
  function()
    telescope_builtin.live_grep {
      grep_open_files = true,
      prompt_title = 'Live Grep in Open Files',
    }
  end,
  {
    desc = '[S]earch in open files',
  }
)

vim.keymap.set('n', '<leader>sn', function()
  telescope_builtin.find_files {
    cwd = vim.fn.stdpath 'config',
  }
end, {
  desc = '[S]earch [N]eovim files',
})

-- Telescope-based LSP navigation.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('user-telescope-lsp-attach', { clear = true }),
  callback = function(event)
    local buf = event.buf

    vim.keymap.set('n', 'grr', telescope_builtin.lsp_references, {
      buffer = buf,
      desc = '[G]oto [R]eferences',
    })

    vim.keymap.set('n', 'gri', telescope_builtin.lsp_implementations, {
      buffer = buf,
      desc = '[G]oto [I]mplementation',
    })

    vim.keymap.set('n', 'grd', telescope_builtin.lsp_definitions, {
      buffer = buf,
      desc = '[G]oto [D]efinition',
    })

    vim.keymap.set('n', 'gO', telescope_builtin.lsp_document_symbols, {
      buffer = buf,
      desc = 'Open document symbols',
    })

    vim.keymap.set('n', 'gW', telescope_builtin.lsp_dynamic_workspace_symbols, {
      buffer = buf,
      desc = 'Open workspace symbols',
    })

    vim.keymap.set('n', 'grt', telescope_builtin.lsp_type_definitions, {
      buffer = buf,
      desc = '[G]oto [T]ype definition',
    })
  end,
})

-- ============================================================
-- LSP
-- ============================================================

vim.pack.add {
  gh 'j-hui/fidget.nvim',
  gh 'neovim/nvim-lspconfig',
  gh 'mason-org/mason.nvim',
  gh 'mason-org/mason-lspconfig.nvim',
  gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
}

require('fidget').setup {}
require('mason').setup {}

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('user-lsp-attach', { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)

    local map = function(keys, func, desc, mode)
      mode = mode or 'n'

      vim.keymap.set(mode, keys, func, {
        buffer = event.buf,
        desc = 'LSP: ' .. desc,
      })
    end

    map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
    map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
    map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    if client and client:supports_method('textDocument/documentHighlight', event.buf) then
      local highlight_group = vim.api.nvim_create_augroup('user-lsp-highlight', {
        clear = false,
      })

      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_group,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_group,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('user-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()

          vim.api.nvim_clear_autocmds {
            group = 'user-lsp-highlight',
            buffer = event2.buf,
          }
        end,
      })
    end

    if client and client:supports_method('textDocument/inlayHint', event.buf) then
      map(
        '<leader>th',
        function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled {
            bufnr = event.buf,
          })
        end,
        '[T]oggle Inlay [H]ints'
      )
    end
  end,
})

---@type table<string, vim.lsp.Config>
local servers = {
  gopls = {},

  tailwindcss = {},
  html = {},
  cssls = {},
  emmet_ls = {},

  lua_ls = {
    on_init = function(client)
      client.server_capabilities.documentFormattingProvider = false

      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        local has_lua_config = vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')

        if path ~= vim.fn.stdpath 'config' and has_lua_config then return end
      end

      client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
        runtime = {
          version = 'LuaJIT',
          path = {
            'lua/?.lua',
            'lua/?/init.lua',
          },
        },
        workspace = {
          checkThirdParty = false,
          library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
            '${3rd}/luv/library',
            '${3rd}/busted/library',
          }),
        },
      })
    end,
    settings = {
      Lua = {
        format = {
          enable = false,
        },
        hint = {
          enable = true,
          semicolon = 'Disable',
        },
      },
    },
  },
}

local ensure_installed = vim.tbl_keys(servers)

vim.list_extend(ensure_installed, {
  'stylua',
  'goimports',
  'gofumpt',
  'prettier',
})

require('mason-tool-installer').setup {
  ensure_installed = ensure_installed,
}

for name, server in pairs(servers) do
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end

-- ============================================================
-- Formatting
-- ============================================================

vim.pack.add {
  gh 'stevearc/conform.nvim',
}

require('conform').setup {
  notify_on_error = false,

  format_on_save = function(bufnr)
    local enabled_filetypes = {
      lua = true,
      go = true,
      javascript = true,
      typescript = true,
      javascriptreact = true,
      typescriptreact = true,
      html = true,
      css = true,
      json = true,
    }

    if enabled_filetypes[vim.bo[bufnr].filetype] then return {
      timeout_ms = 500,
    } end

    return nil
  end,

  default_format_opts = {
    lsp_format = 'fallback',
  },

  formatters_by_ft = {
    lua = { 'stylua' },
    javascript = { 'prettier' },
    typescript = { 'prettier' },
    javascriptreact = { 'prettier' },
    typescriptreact = { 'prettier' },
    css = { 'prettier' },
    html = { 'prettier' },
    json = { 'prettier' },
    markdown = { 'prettier' },
    go = { 'goimports', 'gofumpt' },
  },
}

vim.keymap.set({ 'n', 'v' }, '<leader>f', function()
  require('conform').format {
    async = true,
  }
end, {
  desc = '[F]ormat buffer',
})

-- ============================================================
-- Completion and snippets
-- ============================================================

vim.pack.add {
  {
    src = gh 'L3MON4D3/LuaSnip',
    version = vim.version.range '2.*',
  },
  gh 'rafamadriz/friendly-snippets',
  {
    src = gh 'saghen/blink.cmp',
    version = vim.version.range '1.*',
  },
}

require('luasnip').setup {}
require('luasnip.loaders.from_vscode').lazy_load()

require('blink.cmp').setup {
  keymap = {
    preset = 'default',
  },

  appearance = {
    nerd_font_variant = 'mono',
  },

  completion = {
    documentation = {
      auto_show = false,
      auto_show_delay_ms = 500,
    },
  },

  sources = {
    default = {
      'lsp',
      'path',
      'snippets',
    },
  },

  snippets = {
    preset = 'luasnip',
  },

  -- Lua fuzzy matcher avoids requiring the optional Rust binary.
  fuzzy = {
    implementation = 'lua',
  },

  signature = {
    enabled = true,
  },
}

-- ============================================================
-- Treesitter
-- ============================================================

vim.pack.add {
  {
    src = gh 'nvim-treesitter/nvim-treesitter',
    version = 'main',
  },
}

local parsers = {
  'bash',
  'c',
  'diff',
  'html',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'query',
  'vim',
  'vimdoc',
}

require('nvim-treesitter').install(parsers)

---@param buf integer
---@param language string
local function treesitter_try_attach(buf, language)
  if not vim.treesitter.language.add(language) then return end

  vim.treesitter.start(buf, language)

  local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil

  if has_indent_query then vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
end

local available_parsers = require('nvim-treesitter').get_available()

vim.api.nvim_create_autocmd('FileType', {
  desc = 'Start Treesitter for supported filetypes',
  callback = function(args)
    local buf = args.buf
    local filetype = args.match
    local language = vim.treesitter.language.get_lang(filetype)

    if not language then return end

    local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

    if vim.tbl_contains(installed_parsers, language) then
      treesitter_try_attach(buf, language)
    elseif vim.tbl_contains(available_parsers, language) then
      require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
    else
      treesitter_try_attach(buf, language)
    end
  end,
})

-- ============================================================
-- Optional local modules
-- ============================================================

-- These files come from the Kickstart repository or your own config.
-- Keep only the modules you actually use.

-- require 'kickstart.plugins.debug'
require 'kickstart.plugins.indent_line'
-- require 'kickstart.plugins.lint'
require 'kickstart.plugins.autopairs'
-- require 'kickstart.plugins.neo-tree'

-- Disabled because gitsigns is already configured above.
-- require 'kickstart.plugins.gitsigns'

-- Your own plugin/config modules.
require 'custom.plugins'

-- vim: ts=2 sts=2 sw=2 et- vim: ts=2 sts=2 sw=2 et
