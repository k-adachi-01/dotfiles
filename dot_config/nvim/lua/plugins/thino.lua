local vault = "/mnt/c/Users/adachi/obsidian"

local function daily_path()
  return vault .. "/02_daily/" .. os.date("%Y-%m-%d") .. ".md"
end

local function insert_log_entry(input_lines)
  local filepath = daily_path()
  local time = os.date("%H:%M")
  -- 1行目: "- HH:MM text"、2行目以降: タブインデント
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

  -- # Reflection の直前の --- を探し、最後のエントリの直後に挿入
  local insert_at = #lines + 1
  for i, line in ipairs(lines) do
    if line:match("^# Reflection") then
      local j = i - 1
      -- 空行をスキップして --- を探す
      while j > 0 and lines[j]:match("^%s*$") do
        j = j - 1
      end
      if j > 0 and lines[j]:match("^%-%-%-") then
        -- --- の前の空行もスキップして最後のエントリの直後に挿入
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

  -- 複数行エントリを展開して挿入
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
    title = "  Thino  <C-j> 保存 / <Esc> キャンセル ",
    title_pos = "center",
  })
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].textwidth = 0
  vim.wo[win].wrap = true
  vim.wo[win].winhl = "Normal:Normal,FloatBorder:FloatBorder"
  vim.cmd("startinsert")

  -- 行数に合わせてウィンドウの高さを自動調整
  local function resize()
    if not vim.api.nvim_win_is_valid(win) then return end
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
    if standalone then vim.cmd("qa!") end
  end

  local function confirm()
    local raw = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    -- 末尾の空行を除去
    while #raw > 0 and raw[#raw]:match("^%s*$") do
      table.remove(raw)
    end
    vim.api.nvim_win_close(win, true)
    if #raw > 0 and raw[1]:match("%S") then
      insert_log_entry(raw)
    end
    quit()
  end

  -- <C-j>: 確定（Insert / Normal どちらでも）
  vim.keymap.set({ "i", "n" }, "<C-j>", confirm, { buffer = buf })
  -- <CR>: 通常の改行（Insert モード）
  -- Normal モードの <CR> でも確定できるよう残す
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

-- nvim --cmd からも呼べるようにグローバルに公開
_G.thino = { capture = capture }

return {
  {
    "LazyVim/LazyVim",
    optional = true,
    init = function()
      vim.keymap.set("n", "<leader>m", capture, { desc = "Thino: Quick Memo" })
      vim.keymap.set("n", "<leader>d", open_today, { desc = "Thino: Today's Log" })
    end,
  },
}
