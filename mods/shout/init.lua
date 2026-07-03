
if not minetest.global_exists("shout") then shout = {} end
shout.modpath = minetest.get_modpath("shout")
shout.worldpath = minetest.get_worldpath()
shout.datafile = shout.worldpath .. "/hints.txt"

-- Localize for performance.
local math_floor = math.floor
local math_random = math.random

local SHOUT_COLOR = core.get_color_escape_sequence("#ff2a00")
local TEAM_COLOR = core.get_color_escape_sequence("#a8ff00")
local WHITE = core.get_color_escape_sequence("#ffffff")

shout.HINTS = {}
shout.BUILTIN_HINTS = {}

dofile(shout.modpath .. "/builtin_tips.lua")
dofile(shout.modpath .. "/channel.lua")



function shout.hint_add(name, param)
	name = name:trim()
	param = param:trim()
	param = param:gsub("%s+", " ")

	if param:len() == 0 then
		minetest.chat_send_player(name, "# Server: Not adding an empty hint message.")
		return
	end

	minetest.chat_send_player(name, "# Server: Will add hint message: \"" .. param .. "\".")

	-- Will store all hints loaded from file.
	local loaded_hints = {}

	-- Load all hints from world datafile.
	local file, err = io.open(shout.datafile, "r")
	if err then
		minetest.chat_send_player(name, "# Server: Failed to open \"" .. shout.datafile .. "\" for reading: " .. err)
	else
		local datastring = file:read("*all")
		if datastring and datastring ~= "" then
			local records = string.split(datastring, "\n")
			for record_number, record in ipairs(records) do
				local data = record:trim()
				if data:len() > 0 then
					table.insert(loaded_hints, data)
				end
			end
		end
		file:close()
	end

	minetest.chat_send_player(name, "# Server: Loaded " .. #loaded_hints .. " previously saved hints.")

	-- Add the new hint message.
	table.insert(loaded_hints, param)

	-- Custom file format. minetest.serialize() is unusable for large tables.
	local datastring = ""
	for k, record in ipairs(loaded_hints) do
		datastring = datastring .. record .. "\n"
	end

	-- Now save all non-builtin hints back to the file.
	local file, err = io.open(shout.datafile, "w")
	if err then
		minetest.chat_send_player(name, "# Server: Failed to open \"" .. shout.datafile .. "\" for writing: " .. err)
	else
		file:write(datastring)
		file:close()
	end

	-- Recombine both tables.
	shout.HINTS = {}
	for k, v in ipairs(shout.BUILTIN_HINTS) do
		table.insert(shout.HINTS, v)
	end
	for k, v in ipairs(loaded_hints) do
		table.insert(shout.HINTS, v)
	end
end



-- Load any saved hints whenever mod is reloaded or server starts.
do
	-- Will store all hints loaded from file.
	local loaded_hints = {}

	-- Load all hints from world datafile.
	local file, err = io.open(shout.datafile, "r")
	if err then
		if not err:find("No such file") then
			minetest.log("error", "Failed to open " .. shout.datafile .. " for reading: " .. err)
		end
	else
		local datastring = file:read("*all")
		if datastring and datastring ~= "" then
			local records = string.split(datastring, "\n")
			for record_number, record in ipairs(records) do
				local data = record:trim()
				if data:len() > 0 then
					table.insert(loaded_hints, data)
				end
			end
		end
		file:close()
	end

	-- Recombine both tables.
	shout.HINTS = {}
	for k, v in ipairs(shout.BUILTIN_HINTS) do
		table.insert(shout.HINTS, v)
	end
	for k, v in ipairs(loaded_hints) do
		table.insert(shout.HINTS, v)
	end
end



local function get_non_admin_players()
	local t = minetest.get_connected_players()
	local b = {}
	for k, v in ipairs(t) do
		if not minetest.check_player_privs(v, "server") then
			b[#b + 1] = v
		end
	end
	return b
end



local HINT_DELAY_MIN = 60*45
local HINT_DELAY_MAX = 60*90

function shout.print_hint()
	local HINTS = shout.HINTS

	-- Only if hints are available.
	if #HINTS > 0 then
		-- Don't speak to an empty room.
		local players = get_non_admin_players()
		if #players > 0 then
			minetest.chat_send_all("# Server: " .. HINTS[math_random(1, #HINTS)])
		end
	end

	-- Print another hint after some delay.
	minetest.after(math_random(HINT_DELAY_MIN, HINT_DELAY_MAX), function() shout.print_hint() end)
end



-- Shout a message.
function shout.shout(name, param)
	param = string.trim(param)
	if #param < 1 then
		minetest.chat_send_player(name, "# Server: No message specified.")
		easyvend.sound_error(name)
		return
	end

	if command_tokens.mute.player_muted(name) then
		minetest.chat_send_player(name, "# Server: You cannot shout while gagged!")
		easyvend.sound_error(name)
		return
	end

	-- If this succeeds, the player was either kicked, or muted and a message about that sent to everyone else.
	if chat_core.check_language(name, param) then return end

	local mk = chat_core.generate_coord_string(name)
	local stats = chat_core.player_status(name)
	local dname = rename.gpn(name)
	local players = minetest.get_connected_players()

	for _, player in ipairs(players) do
		local target_name = player:get_player_name() or ""
		if not chat_controls.player_ignored_shout(target_name, name) or target_name == name then
			chat_core.alert_player_sound(target_name)
			minetest.chat_send_player(target_name, stats .. "<!" .. chat_core.nametag_color .. dname .. WHITE .. mk .. "!> " .. SHOUT_COLOR .. param)
		end
	end

	afk.reset_timeout(name)
	chat_logging.log_public_shout(name, stats, param, mk)
end



if not shout.run_once then
	-- Post 'startup complete' message only in multiplayer.
	if not minetest.is_singleplayer() then
		minetest.after(0, function()
			minetest.chat_send_all("# Server: Startup complete.")
		end)
	end

	minetest.register_chatcommand("shout", {
		params = "<message>",
		description = "Yell a message to everyone on the server. You can also prepend your chat with '!'.",
		privs = {shout=true},
		func = function(name, param)
			shout.shout(name, param)
			return true
		end,
	})

	minetest.register_chatcommand("channel", {
		params = "<id>",
		description = "Set channel name.",
		privs = {},
		func = function(name, param)
			shout.channel(name, param)
			return true
		end,
	})

	minetest.register_chatcommand("x", {
		params = "<message>",
		description = "Speak on current channel.",
		privs = {},
		func = function(name, param)
			shout.x(name, param)
			return true
		end,
	})

	minetest.register_chatcommand("hint_add", {
		params = "<message>",
		description = "Add a hint message to the hint list. Example between quotes: '/hint_add This is a hint message. Another sentance.'",
		privs = {server=true},
		func = function(name, param)
			shout.hint_add(name, param)
			return true
		end,
	})

	-- Start hints. A hint is written into public chat every so often.
	-- But not too often, or it becomes annoying.
	minetest.after(math_random(HINT_DELAY_MIN, HINT_DELAY_MAX), function() shout.print_hint() end)

	minetest.register_on_joinplayer(function(...)
		return shout.join_channel(...) end)

	minetest.register_on_leaveplayer(function(...)
		return shout.leave_channel(...) end)

	local c = "shout:core"
	local f = shout.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	shout.run_once = true
end
