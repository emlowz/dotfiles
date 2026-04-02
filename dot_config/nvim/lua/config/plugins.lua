if vim.fn.has("nvim-0.12") == 0 then
  return
end

local ok, err = pcall(vim.pack.add, {
  {
    src = "https://github.com/nvim-lualine/lualine.nvim",
  },
}, { confirm = false })

if not ok then
  vim.schedule(function()
    vim.notify("vim.pack failed to add plugins: " .. err, vim.log.levels.WARN)
  end)
  return
end

require("config.lualine")
