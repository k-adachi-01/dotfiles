local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()
config.automatically_reload_config = true

local home = os.getenv("HOME")

local function current_working_dir_path(pane)
local cwd_uri = pane:get_current_working_dir()
	if cwd_uri == nil then
		return nil
	end
	if type(cwd_uri) == "string" then
		return cwd_uri:match("^file://[^/]*(/.*)$") or cwd_uri
	end
	return cwd_uri.file_path
end

local function split_spawn_command(pane)
	local cwd = current_working_dir_path(pane)
	if cwd == nil or cwd == "" then
		return { domain = "CurrentPaneDomain" }
	end
	return { domain = "CurrentPaneDomain", cwd = cwd }
end

local function split_action(direction)
	return wezterm.action_callback(function(window, pane)
		local spawn = split_spawn_command(pane)
		window:perform_action(
			act.SplitPane({
				direction = direction == "vertical" and "Down" or "Right",
				command = spawn,
			}),
			pane
		)
	end)
end

-- 背景透過率ステップ
local opacity_steps = { 0.85, 0.95, 1.0 }
local opacity_index = 1

-- フォント
config.font = wezterm.font_with_fallback({
	"PlemolJP Console NF",
	"JetBrains Mono",
	"Segoe UI Symbol",
	"Segoe UI Emoji",
})
config.font_size = 12.0
config.line_height = 1.05
config.use_ime = true

-- ウィンドウ
config.window_decorations = "RESIZE"
config.window_padding = {
	left = 6,
	right = 6,
	top = 4,
	bottom = 4,
}
config.window_background_opacity = 0.85

-- タブバー
config.color_scheme = "Catppuccin Mocha"
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = false

config.colors = {
	tab_bar = {
		background = "none",
		inactive_tab_edge = "none",
	},
	-- Catppuccin Mocha の ANSI green (#a6e3a1) はそのまま使うが、
	-- kiro-cli の diff 背景に使われる pure green (#00ff00) を抑えるため
	-- ANSI index 2 / 10 を落ち着いた緑に差し替える
	ansi = {
		"#45475a", -- black   (Surface1)
		"#f38ba8", -- red     (Red)
		"#40a060", -- green   ← #a6e3a1 から落ち着いた緑へ
		"#f9e2af", -- yellow  (Yellow)
		"#89b4fa", -- blue    (Blue)
		"#cba6f7", -- magenta (Mauve)
		"#94e2d5", -- cyan    (Teal)
		"#bac2de", -- white   (Subtext1)
	},
	brights = {
		"#585b70", -- bright black   (Surface2)
		"#f38ba8", -- bright red     (Red)
		"#52b472", -- bright green   ← 明るめだが蛍光ではない緑
		"#f9e2af", -- bright yellow  (Yellow)
		"#89b4fa", -- bright blue    (Blue)
		"#cba6f7", -- bright magenta (Mauve)
		"#94e2d5", -- bright cyan    (Teal)
		"#a6adc8", -- bright white   (Subtext0)
	},
}

-- タブのカスタマイズ（三角形 + Catppuccin カラー）
local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle

local SPINNER_CHARS = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local function pane_has_spinner(pane)
	local ok, text = pcall(function()
		return pane:get_lines_as_text(5)
	end)
	if not ok or not text then
		return false
	end
	for _, ch in ipairs(SPINNER_CHARS) do
		if text:find(ch, 1, true) then
			return true
		end
	end
	return false
end

local function claude_tab_colors(pane)
	local ok, proc = pcall(function()
		return pane:get_foreground_process_info()
	end)
	if not ok or not proc then
		return nil, nil
	end
	local name = proc.name or ""
	if not name:find("claude") and not name:find("Claude") then
		return nil, nil
	end
	if pane_has_spinner(pane) then
		return "#fab387", "#1e1e2e"
	else
		return "#a6e3a1", "#1e1e2e"
	end
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local background = "#45475a"
	local foreground = "#cdd6f4"

	if tab.is_active then
		background = "#f9e2af"
		foreground = "#1e1e2e"
	end

	local pane = wezterm.mux.get_pane(tab.active_pane.pane_id)
	if pane then
		local claude_bg, claude_fg = claude_tab_colors(pane)
		if claude_bg then
			background = claude_bg
			foreground = claude_fg
		end
	end

	local edge_background = "none"
	local edge_foreground = background
	local title = "   " .. wezterm.truncate_right(tab.tab_title ~= "" and tab.tab_title or tab.active_pane.title, max_width - 1) .. "   "

	return {
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = SOLID_LEFT_ARROW },
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = title },
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = SOLID_RIGHT_ARROW },
	}
end)

-- その他
config.default_cursor_style = "SteadyBlock"
config.cursor_blink_rate = 0
config.animation_fps = 60
config.term = "xterm-256color"
config.audible_bell = "Disabled"
config.adjust_window_size_when_changing_font_size = false
config.window_close_confirmation = "NeverPrompt"

-- tmux っぽい leader（Ctrl+A）
config.leader = {
	key = "a",
	mods = "CTRL",
	timeout_milliseconds = 1000,
}

config.keys = {
	-- pane 移動
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

	-- pane 分割（s = 上下, v = 左右）
	{ key = "s", mods = "LEADER", action = split_action("vertical") },
	{ key = "v", mods = "LEADER", action = split_action("horizontal") },

	-- pane サイズ変更
	{ key = "H", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "J", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Down", 3 }) },
	{ key = "K", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Up", 3 }) },
	{ key = "L", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },

	-- よく使う操作
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },
	{ key = "w", mods = "LEADER", action = act.CloseCurrentTab({ confirm = false }) },
	{ key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = false }) },

	-- leader+a で本来の Ctrl-A を送る
	{ key = "a", mods = "LEADER", action = act.SendKey({ key = "a", mods = "CTRL" }) },

	-- タブ名変更
	{
		key = ",",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Tab name:",
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},

	-- クリップボード
	{ key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
	{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },

	-- コマンドパレット
	{ key = "p", mods = "LEADER", action = act.ActivateCommandPalette },

	-- 背景透過率サイクル（0.85 → 0.95 → 1.0）
	{
		key = "o",
		mods = "LEADER",
		action = wezterm.action_callback(function(window)
			opacity_index = (opacity_index % #opacity_steps) + 1
			window:set_config_overrides({ window_background_opacity = opacity_steps[opacity_index] })
		end),
	},

-- 新しいタブ（ホームで開く）
	{ key = "t", mods = "LEADER", action = act.SpawnCommandInNewTab({ cwd = home }) },
	{ key = "t", mods = "CTRL|SHIFT", action = act.SpawnCommandInNewTab({ cwd = home }) },

	-- leader+n: nvim . + 右paneで codex
	{
		key = "n",
		mods = "LEADER",
		action = wezterm.action_callback(function(window, pane)
			window:perform_action(act.SendString("nvim .\n"), pane)
			local cwd = current_working_dir_path(pane) or home
			window:perform_action(
				act.SplitPane({
					direction = "Right",
					command = {
						domain = "CurrentPaneDomain",
						cwd = cwd,
						args = { "/bin/zsh", "-lc", "codex; exec /bin/zsh -l" },
					},
				}),
				pane
			)
		end),
	},

	-- leader+c: nvim . + 右paneで codex
	{
		key = "c",
		mods = "LEADER",
		action = wezterm.action_callback(function(window, pane)
			window:perform_action(act.SendString("nvim .\n"), pane)
			local cwd = current_working_dir_path(pane) or home
			window:perform_action(
				act.SplitPane({
					direction = "Right",
					command = {
						domain = "CurrentPaneDomain",
						cwd = cwd,
						args = { "/bin/zsh", "-lc", "codex; exec /bin/zsh -l" },
					},
				}),
				pane
			)
		end),
	},
}

return config
