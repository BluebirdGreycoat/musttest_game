
-- Customize the /help chat-command.
if not minetest.global_exists("help") then help = {} end
help.modpath = minetest.get_modpath("help")

dofile(help.modpath .. "/formspecs.lua")



local function show_all(pname, param)
	-- Is worldedit installed?
	local we = minetest.get_modpath("worldedit")

	local commands = {}
	for name, data in pairs(minetest.registered_chatcommands) do
		local privs = data.privs or {}
		if minetest.check_player_privs(pname, privs) then
			-- If worldedit is installed, skip commands beginning with '/', because
			-- worldedit leaks them due to missing privs.
			if not we or name:sub(1, 1) ~= "/" then
				commands[#commands + 1] = name
			end
		end
	end

	minetest.chat_send_player(pname,
		"# Server: The commands available to you are: " ..
		table.concat(commands, ", ") .. ".")
end



local function show_single(pname, param)
	local def = minetest.registered_chatcommands[param]
	if not def then return end

	local privs = def.privs or {}
	if minetest.check_player_privs(pname, privs) then
		local cmd = "/" .. param
		local args = def.params and def.params ~= "" and (" " .. def.params .. ": ") or ": "
		local desc = def.description or "No description provided."
		minetest.chat_send_player(pname, "# Server: " .. cmd .. args .. desc)
		return
	end

	minetest.chat_send_player(pname,
		"# Server: That command is not available to you.")
end



function help.do_help(pname, param)
	local user = minetest.get_player_by_name(pname)
	if not user or not user:is_player() then return end

	if not param or param == "" then
		show_all(pname, param)
		return
	end

	if minetest.registered_chatcommands[param] then
		show_single(pname, param)
		return
	end

	minetest.chat_send_player(pname, "# Server: Named command does not exist.")
end



if not help.registered then
	help.registered = true

	-- The builtin /help tries to split commands and privs into mods. Enyekala
	-- doesn't support modding due to the massive differences, so the help
	-- formspecs need to be altered.
	minetest.override_chatcommand("help", {
		params = "",
		description = "Get help on privs and commands.",

		func = function(...)
			help.do_help(...)
			return true
		end,
	})

	-- This game doesn't really have any mod support due to the massive changes.
	-- There's no point in displaying the "mods" because they're not used as such.
	minetest.override_chatcommand("mods", {
		params = "",
		description = "Mods are unsupported.",

		func = function(name, param)
			local s = "# Server: Enyekala does not support mods at this time."
			minetest.chat_send_player(name, s)
			return true
		end,
	})

	local function add_required_priv(name, priv)
		local def = minetest.registered_chatcommands[name]
		if not def then return end
		def = table.copy(def)
		def.privs = def.privs or {}
		def.privs[priv] = true
		minetest.override_chatcommand(name, def)
	end

	-- Note: can only override *builtin* chat-commands without needing dependency.
	if not minetest.is_singleplayer() then
		add_required_priv("revoke", "server")
		add_required_priv("revokeme", "server")
		add_required_priv("grant", "server")
		add_required_priv("grantme", "server")
	end

	local c = "help:core"
	local f = help.modpath .. "/init.lua"
	reload.register_file(c, f, false)
end
