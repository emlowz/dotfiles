local ok, which_key = pcall(require, "which-key")
if not ok then
  return
end

which_key.setup({
  delay = 300,
  preset = "modern",
  icons = {
    mappings = false,
  },
  spec = {
    { "<leader>f", group = "find" },
    { "<leader>g", group = "git" },
  },
})
