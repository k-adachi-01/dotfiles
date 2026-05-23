-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Reload filesystem changes (e.g. files created in another terminal pane)
vim.keymap.set("n", "<leader>r", function()
  vim.cmd("checktime")
  if package.loaded["oil"] then
    require("oil").discard_all_changes()
  end
end, { desc = "Reload files from disk" })

