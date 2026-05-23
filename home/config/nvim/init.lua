-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

vim.opt.clipboard = "unnamedplus"
vim.opt.guifont = "PlemolJP Console NF:h12"

local is_windows_or_wsl = vim.fn.has("win32") == 1 or vim.fn.has("wsl") == 1
local win32yank = vim.fn.exepath("win32yank.exe")

if is_windows_or_wsl and win32yank ~= "" then
  vim.g.clipboard = {
    name = "win32yank-wsl",
    copy = {
      ["+"] = win32yank .. " -i --crlf",
      ["*"] = win32yank .. " -i --crlf",
    },
    paste = {
      ["+"] = win32yank .. " -o --lf",
      ["*"] = win32yank .. " -o --lf",
    },
    cache_enabled = 0,
  }
end
