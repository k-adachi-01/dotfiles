return {
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    opts = {
      default_file_explorer = true,
      view_options = {
        show_hidden = true,
      },
      keymaps = {
        gy = {
          callback = function()
            local oil = require("oil")
            local entry = oil.get_cursor_entry()
            local dir = oil.get_current_dir()
            if not entry or not dir then
              return
            end

            local path = dir .. entry.name
            vim.fn.setreg("+", path)
            vim.notify("Copied path: " .. path)
          end,
          desc = "Copy absolute path",
          mode = "n",
        },
      },
    },
    keys = {
      { "<leader>e", "<cmd>Oil<cr>", desc = "Open parent directory (oil)" },
    },
  },
}
