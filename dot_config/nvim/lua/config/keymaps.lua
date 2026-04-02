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

-- Find files, buffers, help, and text with Telescope.
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Find buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Help tags" })

-- Git helpers from gitsigns.
map("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<cr>", { desc = "Preview hunk" })
map("n", "<leader>gb", "<cmd>Gitsigns blame_line<cr>", { desc = "Blame line" })
map("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", { desc = "Reset hunk" })
