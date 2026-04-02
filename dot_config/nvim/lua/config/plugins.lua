if vim.fn.has("nvim-0.12") == 0 then
  return
end

local ok, err = pcall(vim.pack.add, {
  {
    src = "https://github.com/nvim-lualine/lualine.nvim",
  },
  {
    src = "https://github.com/nvim-lua/plenary.nvim",
  },
  {
    src = "https://github.com/nvim-telescope/telescope.nvim",
  },
  {
    src = "https://github.com/folke/which-key.nvim",
  },
  {
    src = "https://github.com/lewis6991/gitsigns.nvim",
  },
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
  },
}, { confirm = false })

if not ok then
  vim.schedule(function()
    vim.notify("vim.pack failed to add plugins: " .. err, vim.log.levels.WARN)
  end)
  return
end

require("config.lualine")
require("config.which-key")
require("config.gitsigns")
require("config.telescope")
require("config.treesitter")
