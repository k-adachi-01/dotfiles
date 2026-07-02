{pkgs, ...}: {
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    opts = {
      autoread = true;
      clipboard = "unnamedplus";
      guifont = "PlemolJP Console NF:h12";
      pumblend = 15;
      winblend = 0;
    };

    extraPlugins = with pkgs.vimPlugins; [
      im-select-nvim
      kanagawa-nvim
      markdown-preview-nvim
      nvim-web-devicons
      oil-nvim
    ];

    extraConfigLua = ''
      require("kanagawa").setup({
        theme = "wave",
        background = {
          dark = "wave",
          light = "lotus",
        },
      })
      vim.cmd.colorscheme("kanagawa")

      require("oil").setup({
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
      })

      vim.g.mkdp_filetypes = { "markdown" }

      vim.keymap.set("n", "<leader>e", "<cmd>Oil<cr>", { desc = "Open parent directory (oil)" })
      vim.keymap.set("n", "<leader>p", "<cmd>MarkdownPreviewToggle<cr>", { desc = "Markdown Preview Toggle" })
      vim.keymap.set("n", "<leader>r", function()
        vim.cmd("checktime")
        if package.loaded["oil"] then
          require("oil").discard_all_changes()
        end
      end, { desc = "Reload files from disk" })

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

      local autocmd = vim.api.nvim_create_autocmd

      autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
        group = vim.api.nvim_create_augroup("auto-checktime", { clear = true }),
        callback = function()
          if vim.fn.mode() ~= "c" then
            vim.cmd("silent! checktime")
          end
        end,
      })

      autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("transparent-bg", { clear = true }),
        callback = function()
          vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
          vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
          vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
        end,
      })

      vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })

      local ime_toggle = vim.fn.exepath("ime_toggle.exe")
      if ime_toggle == "" then
        local candidate = vim.fn.expand("~/bin/ime_toggle.exe")
        if vim.fn.filereadable(candidate) == 1 and vim.fn.executable(candidate) == 1 then
          ime_toggle = candidate
        end
      end

      if ime_toggle ~= "" and is_windows_or_wsl and vim.env.DISPLAY then
        autocmd("InsertLeave", {
          group = vim.api.nvim_create_augroup("ime-toggle", { clear = true }),
          pattern = "*",
          callback = function()
            vim.fn.system({ ime_toggle, "en" })
          end,
        })
      end

      if vim.fn.has("macunix") == 1 and vim.fn.executable("macism") == 1 then
        require("im_select").setup({
          default_command = "macism",
          keep_quiet_on_no_binary = true,
        })
      end

      local function before_cursor_has_japanese()
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2]
        local before = line:sub(1, col)
        return before:find("[\227-\233][\128-\191][\128-\191]") ~= nil
      end

      pcall(function()
        local cmp = require("cmp")
        cmp.setup({
          enabled = function()
            return not before_cursor_has_japanese()
          end,
        })
      end)

      local vault = vim.env.OBSIDIAN_VAULT or vim.fn.expand("~/obsidian")

      local function daily_path()
        return vault .. "/02_daily/" .. os.date("%Y-%m-%d") .. ".md"
      end

      local function insert_log_entry(input_lines)
        local filepath = daily_path()
        local time = os.date("%H:%M")
        local first = input_lines[1] or ""
        local entry_lines = { "- " .. time .. " " .. first }
        for i = 2, #input_lines do
          table.insert(entry_lines, "\t" .. input_lines[i])
        end
        local entry = table.concat(entry_lines, "\n")

        local f = io.open(filepath, "r")
        if not f then
          local date_str = os.date("%Y-%m-%d")
          local template = table.concat({
            "---",
            "tags:",
            "  - type/daily",
            'date: "' .. date_str .. '"',
            "---",
            "# ToDo",
            "",
            "",
            "---",
            "# Note",
            "",
            "",
            "---",
            "# Log",
            "",
            "",
            "---",
            "# Reflection",
            "",
            "",
          }, "\n")
          local nf = io.open(filepath, "w")
          if not nf then
            vim.notify("Cannot create: " .. filepath, vim.log.levels.ERROR)
            return
          end
          nf:write(template)
          nf:close()
          f = io.open(filepath, "r")
        end

        local lines = {}
        for line in f:lines() do
          table.insert(lines, line)
        end
        f:close()

        local insert_at = #lines + 1
        for i, line in ipairs(lines) do
          if line:match("^# Reflection") then
            local j = i - 1
            while j > 0 and lines[j]:match("^%s*$") do
              j = j - 1
            end
            if j > 0 and lines[j]:match("^%-%-%-") then
              local k = j - 1
              while k > 0 and lines[k]:match("^%s*$") do
                k = k - 1
              end
              insert_at = k + 1
            else
              insert_at = i
            end
            break
          end
        end

        local entry_split = vim.split(entry, "\n", { plain = true })
        for k = #entry_split, 1, -1 do
          table.insert(lines, insert_at, entry_split[k])
        end

        local out = io.open(filepath, "w")
        if not out then
          vim.notify("Cannot write: " .. filepath, vim.log.levels.ERROR)
          return
        end
        out:write(table.concat(lines, "\n") .. "\n")
        out:close()

        vim.notify(" " .. entry_lines[1], vim.log.levels.INFO)
      end

      local function capture()
        local buf = vim.api.nvim_create_buf(false, true)
        local width = math.min(72, vim.o.columns - 6)
        local max_height = 8
        local init_height = 3
        local col = math.floor((vim.o.columns - width) / 2)

        local win = vim.api.nvim_open_win(buf, true, {
          relative = "editor",
          width = width,
          height = init_height,
          col = col,
          row = math.floor((vim.o.lines - init_height) / 2) - 1,
          style = "minimal",
          border = "rounded",
          title = "  Thino  <C-j> Save / <Esc> Cancel ",
          title_pos = "center",
        })
        vim.bo[buf].filetype = "markdown"
        vim.bo[buf].textwidth = 0
        vim.wo[win].wrap = true
        vim.wo[win].winhl = "Normal:Normal,FloatBorder:FloatBorder"
        vim.cmd("startinsert")

        local function resize()
          if not vim.api.nvim_win_is_valid(win) then
            return
          end
          local line_count = vim.api.nvim_buf_line_count(buf)
          local new_h = math.max(init_height, math.min(line_count, max_height))
          local new_row = math.floor((vim.o.lines - new_h) / 2) - 1
          vim.api.nvim_win_set_config(win, { relative = "editor", height = new_h, row = new_row, col = col })
        end

        vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
          buffer = buf,
          callback = resize,
        })

        local standalone = vim.fn.argc() == 0

        local function quit()
          if standalone then
            vim.cmd("qa!")
          end
        end

        local function confirm()
          local raw = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
          while #raw > 0 and raw[#raw]:match("^%s*$") do
            table.remove(raw)
          end
          vim.api.nvim_win_close(win, true)
          if #raw > 0 and raw[1]:match("%S") then
            insert_log_entry(raw)
          end
          quit()
        end

        vim.keymap.set({ "i", "n" }, "<C-j>", confirm, { buffer = buf })
        vim.keymap.set("n", "<CR>", confirm, { buffer = buf })
        vim.keymap.set({ "i", "n" }, "<Esc>", function()
          vim.api.nvim_win_close(win, true)
          quit()
        end, { buffer = buf })
      end

      local function open_today()
        vim.cmd("e " .. vim.fn.fnameescape(daily_path()))
        vim.fn.search("^# Log", "w")
        vim.cmd("normal! zz")
      end

      _G.thino = { capture = capture }

      vim.keymap.set("n", "<leader>m", capture, { desc = "Thino: Quick Memo" })
      vim.keymap.set("n", "<leader>d", open_today, { desc = "Thino: Today's Log" })
    '';
  };
}
