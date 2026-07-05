
-- Localize for performance.
local math_floor = math.floor
local math_random = math.random

shout.HINTS = {}
shout.BUILTIN_HINTS = {}

local HINT_DELAY_MIN = 60*45
local HINT_DELAY_MAX = 60*90



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



function shout.print_hint()
	local HINTS = shout.HINTS

	-- Only if hints are available.
	if #HINTS > 0 then
		-- Don't speak to an empty room.
		local players = get_non_admin_players()
		if #players > 0 then
			minetest.chat_send_all("hints", "# Server: " .. HINTS[math_random(1, #HINTS)])
		end
	end

	-- Print another hint after some delay.
	minetest.after(math_random(HINT_DELAY_MIN, HINT_DELAY_MAX), function() shout.print_hint() end)
end



-- Called at server startup.
function shout.start_hints()
	minetest.after(math_random(HINT_DELAY_MIN, HINT_DELAY_MAX), function() shout.print_hint() end)
end
