local home = os.getenv("HOME")

if not home or home == "" then
	return {}
end

return dofile(home .. "/.wezterm.lua.patched")
