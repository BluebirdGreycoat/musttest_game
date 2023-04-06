------------------------------------------------------------------------------
-- This file is registered as reloadable.
------------------------------------------------------------------------------

-- This file obtains options for the mod.
if not minetest.global_exists("reload") then reload = {} end
reload.impl = reload.impl or {}

reload.impl.setting_get = function(setting)
	local str = minetest.setting_get(setting)
	if str and string.len(str) >= 2 then
		-- Strip quotes.
		str = string.gsub(str, "^\"", "")
		str = string.gsub(str, "\"$", "")
	end
	return str
end



-- Prefix for chat messages.
reload.chat_prefix = reload.impl.setting_get("reload_chat_prefix") or "[Reload] "

-- Path to the root directory when executing arbitrary Lua files.
-- Executing files outside this directory (via the chatcommands) is forbidden.
-- Be sure to change this to suit your needs.
reload.root_path = reload.impl.setting_get("reload_root_path") or "/home"

