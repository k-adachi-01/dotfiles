local is_mac = vim.fn.has("macunix") == 1

local function before_cursor_has_japanese()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before = line:sub(1, col)
  -- ひらがな(U+3040-)・漢字(-U+9FFF)は UTF-8 で 0xE3-0xE9 始まりの 3 バイト列
  return before:find("[\227-\233][\128-\191][\128-\191]") ~= nil
end

return {
  {
    "keaising/im-select.nvim",
    enabled = is_mac,
    config = function()
      require("im_select").setup()
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local original_enabled = opts.enabled
      opts.enabled = function()
        if before_cursor_has_japanese() then
          return false
        end
        if type(original_enabled) == "function" then
          return original_enabled()
        end
        return original_enabled ~= false
      end
    end,
  },
}
