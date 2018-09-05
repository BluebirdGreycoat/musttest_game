--------------------------------------------------------------------------------
-- Mapfix, MTS version.
-- Authored by MustTest.
-- License: MIT.
--------------------------------------------------------------------------------

-- Mod is reloadable.
mapfix = mapfix or {}
mapfix.players = mapfix.players or {}
mapfix.modpath = minetest.get_modpath("mapfix")

-- Configurable settings.
local MIN_TIMEOUT = 30
local DEFAULT_RADIUS = 40
local MAX_RADIUS = 60

local function work(minp, maxp)
	local vm = minetest.get_voxel_manip(minp, maxp)
	vm:update_liquids()
	vm:write_to_map(true) -- Fix lighting while you're at it.
	return vm:get_emerged_area()
end

-- Public API function. May be called from other mods.
function mapfix.execute(pos, radius)
	pos = vector.round(pos)
	radius = math.floor(radius)

	local minp = vector.subtract(pos, radius)
	local maxp = vector.add(pos, radius)

	work(minp, maxp)
end

-- Chat-command callback function.
-- Handles minimum timeout and required privileges.
-- Called by PoC.
mapfix.command = function(pname, param)
	-- Profile function execution time.
	local t1 = os.clock()

	local player = minetest.get_player_by_name(pname)
	if not player or not player:is_player() then
		return
	end

	-- Determine radius.
	local radius = DEFAULT_RADIUS
	if param and param ~= "" then
		radius = tonumber(param:trim())
		if not radius then
			minetest.chat_send_player(pname, "# Server: Usage: /mapfix [<radius>].")
			return
		end
	end

	-- Check timeout delay for this user.
	if mapfix.players[pname] then
		local tnow = os.time()
		local prev = mapfix.players[pname]
		local diff = tnow - prev

		-- Check if function was called too soon.
		if diff < MIN_TIMEOUT then
			local remain = math.ceil(MIN_TIMEOUT - diff)

			-- Grammar adjustment.
			local str = "seconds"
			if remain == 1 then
				str = "second"
			end

			minetest.chat_send_player(pname,
				"# Server: Too soon to run /mapfix again! Wait " .. remain ..
				" more " .. str .. ".")
			return
		end

		-- Store time of last call to this function.
		mapfix.players[pname] = tnow
	else
		-- Store time of last call to this function.
		mapfix.players[pname] = os.time()
	end

	local pos = vector.round(player:get_pos())
	radius = math.floor(radius)

	-- Check privs.
	if radius > MAX_RADIUS then
		local privs = minetest.check_player_privs(pname, {mapfix=true})
		if not privs then
			minetest.chat_send_player(pname,
				"# Server: You cannot exceed radius " .. MAX_RADIUS ..
				"! Your privileges are insufficient.")
			return
		end
	elseif radius < 0 then
		minetest.chat_send_player(pname, "# Server: Radius cannot be negative!")
		return
	end

	local minp = vector.subtract(pos, radius)
	local maxp = vector.add(pos, radius)

	minetest.log("action",
		"Player <" .. pname .. "> executed /mapfix with radius " .. radius ..
		" at " .. minetest.pos_to_string(pos) .. ".")

	minp, maxp = work(minp, maxp)

	-- Calculate elapsed time.
	local t2 = os.clock()
	local totalms = math.ceil((t2 - t1) * 1000)

	minetest.chat_send_player(pname,
		"# Server: Liquid & light recalculation finished! Extents: " ..
		minetest.pos_to_string(minp) .. " to " .. minetest.pos_to_string(maxp) ..
		". Radius: " .. radius .. ". Took " .. totalms .. " milliseconds.")
end

if not mapfix.registered then
	-- Privilege required in order to execute /mapfix for very large areas.
	minetest.register_privilege("mapfix", {
		description = "Player may execute /mapfix with an arbitrary radius.",
		give_to_singleplayer = false,
	})

	-- Allow players to use command from chat console.
	-- No privs required.
	minetest.register_chatcommand("mapfix", {
		params = "[<radius>]",
		description = "Request a recalculation of nearby liquids and light.",

		func = function(...)
			mapfix.command(...)
		end,
	})

	-- Register mod as reloadable.
	local c = "mapfix:core"
	local f = mapfix.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	mapfix.registered = true
end
