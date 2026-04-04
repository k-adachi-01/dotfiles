-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local autocmd = vim.api.nvim_create_autocmd

local ime_toggle = vim.fn.exepath("ime_toggle.exe")
if ime_toggle == "" then
  local candidate = vim.fn.expand("~/bin/ime_toggle.exe")
  if vim.fn.filereadable(candidate) == 1 and vim.fn.executable(candidate) == 1 then
    ime_toggle = candidate
  end
end

local has_ime_toggle = ime_toggle ~= ""
local is_windows_or_wsl = vim.fn.has("win32") == 1 or vim.fn.has("wsl") == 1

if has_ime_toggle and is_windows_or_wsl and vim.env.DISPLAY then
  autocmd("InsertLeave", {
    group = vim.api.nvim_create_augroup("ime-toggle", { clear = true }),
    pattern = "*",
    callback = function()
      vim.fn.system({ ime_toggle, "en" })
    end,
  })
end
