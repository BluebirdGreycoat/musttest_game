
afk = afk or {}
afk.players = afk.players or {}
afk.modpath = minetest.get_modpath("afk")
afk.steptime = 5
afk.timeout = 60 * 10 -- 10 minutes.
afk.warntime = 60 * 9
afk.disable_kick = minetest.is_singleplayer()

-- Localize vector.distance() for performance.
local vector_distance = vector.distance
local vector_round = vector.round
local math_floor = math.floor



-- Public API function.
-- This should be called from any mod that wishes to reset the kick timeout for a player.
-- For example, a chat mod may call this when a player chats.
afk.reset_timeout = function(name)
	-- localize
	local players = afk.players

	-- Ensure an entry exists for this name.
	local data = players[name]
	if not data then
		players[name] = {time=0, pos={x=0, y=0, z=0}}
		data = players[name]
	end

	data.time = 0
	data.afk = nil
end



function afk.on_joinplayer(player)
	local name = player:get_player_name()
	afk.players[name] = {time=0, pos=player:get_pos()}
end

function afk.on_leaveplayer(player, timedout)
	local pname = player:get_player_name()
	afk.players[pname] = nil
end



-- API function to query whether a player is currently AFK.
-- Note that this only has meaning for registered players.
-- Unregistered players are kicked, so you generally won't encounter those.
function afk.is_afk(pname)
	local p = afk.players
	local o = p[pname]
	if o then
		if o.afk then
			return true
		end
	end
	return false
end

-- Returns the number of seconds since player's last action.
-- Returns -1 if player data is not available (wrong player name?).
function afk.seconds_since_action(pname)
	local p = afk.players
	local o = p[pname]
	if o then
		return o.time
	end
	return -1
end



afk.update = function()
  local allplayers = minetest.get_connected_players()
  for k, player in ipairs(allplayers) do
    local name = player:get_player_name()
		local target = afk.players[name]
    
		local pos = vector_round(player:get_pos())
		local dist = vector_distance(pos, target.pos)
		local nokick = false

    if afk.disable_kick or minetest.check_player_privs(name, {allow_afk=true}) then
			nokick = true
    end

		if dist > 0.5 then
			target.pos = pos
			target.time = 0
			target.afk = nil
		else
			-- Increase time since AFK started.
			local time = target.time
			time = time + afk.steptime
			target.time = time

			if not nokick and time >= afk.warntime then
				-- Only ignore players who are registered and NOT dead.
				if player:get_hp() > 0 and passport.player_registered(name) then
					-- If player is registered and NOT dead, don't send message.
					nokick = true
				else
					local remain = afk.timeout - time
					minetest.chat_send_player(name, "# Server: You will be kicked for inactivity in " .. math_floor(remain) .. " seconds.")
					easyvend.sound_error(name)
				end
			end
		end

		-- Kick players who have done nothing for too long.
		if target.time >= afk.timeout then
			if nokick then
				-- If player is registered and NOT dead, then just mark them as AFK.
				-- If player is registered but dead, they'll be kicked anyway.
				target.afk = true
			else
				minetest.kick_player(name, "Kicked for inactivity.")
				local dname = rename.gpn(name)
				minetest.chat_send_all("# Server: <" .. dname .. "> was kicked for being AFK too long.")
			end
		end
  end
end



local timer = 0
local delay = afk.steptime
function afk.globalstep(dtime)
	timer = timer + dtime
	if timer < delay then return end
	timer = 0
	afk.update()
end



function afk.on_craft(itemstack, player, old_craft_grid, craft_inv)
	if not player then return end
	if not player:is_player() then return end
	
	-- Ensure this player has an entry in the table.
	local name = player:get_player_name()
	if not afk.players[name] then
			afk.players[name] = {time=0, pos={x=0, y=0, z=0}}
	end
	
	afk.players[name].time = 0
end



local function show_stats(name)
	local players = minetest.get_connected_players()

	local pc = 0
	local ac = 0

	-- Count AFK players, don't include invisible ones.
	for k, v in ipairs(players) do
		local pname = v:get_player_name()
		local invis = gdac_invis.is_invisible(pname)
		if not invis then
			if afk.is_afk(pname) then
				ac = ac + 1
				pc = pc + 1
			else
				pc = pc + 1
			end
		end
	end

	local ps = "players"
	if pc == 1 then
		ps = "player"
	end

	minetest.chat_send_player(name,
		"# Server: Currently " .. pc .. " " .. ps .. " logged in. " .. ac ..
		" AFK.")
end



local function show_player(name, param)
	local pname = rename.grn(param)
	local invis = gdac_invis.is_invisible(pname)

	if not invis then
		if afk.is_afk(pname) then
			minetest.chat_send_player(name, "# Server: <" .. rename.gpn(pname) .. "> is AFK!")
			return
		else
			-- If player logged in and not admin-invisible.
			if minetest.get_player_by_name(pname) then
				local time = afk.seconds_since_action(pname)
				if time < 60 then
					minetest.chat_send_player(name, "# Server: <" .. rename.gpn(pname) .. "> is active.")
				elseif time < 60*2 then
					minetest.chat_send_player(name, "# Server: <" .. rename.gpn(pname) .. "> might be AFK.")
				else
					minetest.chat_send_player(name, "# Server: <" .. rename.gpn(pname) .. "> is probably AFK.")
				end

				return
			end
		end
	end

	minetest.chat_send_player(name, "# Server: Status of <" .. param .. "> is unknown.")
end



function afk.do_afk(name, param)
	if param ~= "" then
		-- Show info for player.
		show_player(name, param)
	else
		-- Show AFK stats.
		show_stats(name)
	end
end



if not afk.registered then
	-- Crafting resets the player's AFK timeout.
	minetest.register_on_craft(function(...)
		return afk.on_craft(...)
	end)
	
	minetest.register_globalstep(function(...)
		return afk.globalstep(...)
	end)

	minetest.register_privilege("allow_afk", {
		description = "Player will not be kicked for being AFK.",
		give_to_singleplayer = false,
	})

	minetest.register_on_joinplayer(function(...)
		return afk.on_joinplayer(...)
	end)

	minetest.register_on_leaveplayer(function(...)
		return afk.on_leaveplayer(...)
	end)

	minetest.register_chatcommand("afk", {
		params = "[name]",
		description = "Query the AFK status of players.",

		func = function(...)
			afk.do_afk(...)
			return true
		end,
	})

	local c = "afk:core"
	local f = afk.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	afk.registered = true
end


