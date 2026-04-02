local map = vim.keymap.set

-- Keep the selection active while shifting indentation in visual mode.
map("x", "<", "<gv")
map("x", ">", ">gv")

-- Clear search highlights with Enter in normal mode.
map("n", "<CR>", function()
  vim.cmd.nohlsearch()
end, { silent = true, desc = "Clear search highlighting" })

-- Move through display lines when text wraps on screen.
map("n", "j", "gj", { desc = "Down by display line" })
map("n", "k", "gk", { desc = "Up by display line" })

-- Keep the cursor centered while navigating search results.
map("n", "n", "nzzzv", { desc = "Next search result" })
map("n", "N", "Nzzzv", { desc = "Previous search result" })
