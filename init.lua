-- Basic settings
vim.o.number = true
vim.o.relativenumber = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.wrap = false
vim.o.cursorline = true
vim.o.termguicolors = true
vim.g.copilot_node_command = '/usr/bin/node'
vim.o.updatetime = 300
vim.o.timeoutlen = 500
vim.opt.encoding = "utf-8"

-- Set leader key
vim.g.mapleader = ' '

-- Function to get Python path (for LSP switching)
local function get_python_path()
    local conda_env = vim.fn.getenv("CONDA_PREFIX")
    if conda_env ~= vim.NIL and conda_env ~= "" then
        return conda_env .. "/bin/python"
    else
        return vim.g.python3_host_prog
    end
end
    

-- Plugin management with lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin specifications
require("lazy").setup({
  -- LSP
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
  },
  
  -- Completion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
  },
  
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },
  
  -- Copilot
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = {
          enabled = true,
          auto_trigger = true,
          debounce = 75,
          keymap = {
            accept = false,
            accept_word = false,
            accept_line = "<S-Tab>",
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
          },
        },
        panel = { enabled = false },
      })
    end,
  },

  -- Vim-Illuminate
  {
    "RRethy/vim-illuminate",
    config = function()
      require('illuminate').configure({
        providers = {
          'lsp',
          'treesitter',
          'regex',
        },
        delay = 100,
        filetype_overrides = {},
        filetypes_denylist = {
          'dirvish',
          'fugitive',
        },
        under_cursor = true,
      })
    end
  },
  
  -- Solarized Theme
  {
    "svrana/neosolarized.nvim",
    dependencies = { "tjdevries/colorbuddy.nvim" }
  },

  -- LSP Signature
  {
    "ray-x/lsp_signature.nvim",
    event = "VeryLazy",
    opts = {},
    config = function(_, opts) require'lsp_signature'.setup(opts) end
  },

  -- nvim-conda
  {
    "kmontocam/nvim-conda",
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- show conda env
  {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local function conda_env()
      local env = vim.fn.getenv("CONDA_DEFAULT_ENV")
      return env ~= vim.NIL and env ~= "" and "🐍: " .. env or ""
    end

    require('lualine').setup {
      options = {
          component_separators = {left = '|', right = '|'},
          section_separators = {left = '', right = ''},
          theme = 'neosolarized',
      },
      sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch'},
        lualine_c = {'filename', conda_env},
        lualine_x = {'progress'},
        lualine_y = {'location'}
      },
    }
  end
  },

  -- Add other plugins as needed
})

-- LSP setup
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "pyright" },
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()

require("lspconfig").pyright.setup({
  capabilities = capabilities,
  on_init = function(client)
      client.config.settings.python.pythonPath = get_python_path()
  end,
  on_attach = function(client, bufnr)
    require "lsp_signature".on_attach({
      bind = true,
      handler_opts = {
        border = "rounded"
      }
    }, bufnr)
  end,
})

-- Completion setup
local cmp = require('cmp')
cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = false }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }, {
    { name = 'buffer' },
  })
})

-- Treesitter setup
require('nvim-treesitter.configs').setup({
  ensure_installed = { "python" },
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
})

-- Solarized Theme setup
vim.opt.termguicolors = true -- Enable true color support
require('neosolarized').setup({
    comment_italics = true,
    background_set = true,
})
vim.cmd [[colorscheme neosolarized]]

-- LSP Signature setup
require('lsp_signature').setup({
  bind = true,
  handler_opts = {
    border = "rounded"
  },
  hint_enable = false,
  hint_prefix = "🐼 ",
  floating_window = true,
  fix_pos = true,
  auto_close_after = nil,
  padding = '',
  transparency = nil,
  timer_interval = 200,
  toggle_key = nil,
})

-- Additional keymaps and settings
-- Indent in visual mode
vim.api.nvim_set_keymap('v', '<Tab>', '>gv', {noremap = true, silent = true})
vim.api.nvim_set_keymap('v', '<S-Tab>', '<gv', {noremap = true, silent = true})

-- Add single space in front of selected block
vim.api.nvim_set_keymap('v', '<leader>i', ':s/^/ /<CR>', {noremap = true, silent = true})

-- Copilot panel
vim.api.nvim_set_keymap('n', '<leader>cp', ':Copilot panel<CR>', {noremap = true, silent = true})

-- Python path for LSP (adjust as needed for your Miniconda setup)
vim.g.python3_host_prog = '~/miniconda3/bin/python'
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, { noremap = true, silent = true })

-- You may want to add Conda environment switching commands here
-- For example:
-- vim.api.nvim_create_user_command('CondaActivate', function(opts)
--   -- Add your Conda activation logic here
-- end, { nargs = '?' })

-- End of init.lua
