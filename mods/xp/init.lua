
if not minetest.global_exists("xp") then xp = {} end
xp.modpath = minetest.get_modpath("xp")
xp.digxp_max = 1000000
xp.digxp_hp_max = 50000
xp.data = xp.data or {} -- Data is stored in string form.
xp.dirty = true
xp.dirty_players = xp.dirty_players or {}

-- Localize for performance.
local math_floor = math.floor
local math_min = math.min
local math_max = math.max



-- This code supports multiple types of XP.
-- Different types of XP are stored seperately.
function xp.set_xp(pname, kind, amount)
	local key = pname .. ":" .. kind
	xp.data[key] = tostring(amount)
	xp.dirty = true
	xp.dirty_players[pname] = true
end



function xp.get_xp(pname, kind)
	local key = pname .. ":" .. kind
	if not xp.data[key] then
		return 0
	end
	return tonumber(xp.data[key])
end



function xp.subtract_xp(pname, kind, count)
	local points = xp.get_xp(pname, kind)
	points = points - count
	if points < 0 then
		points = 0
	end
	xp.set_xp(pname, kind, points)
	hud_clock.update_xp(pname)
end



-- 500 internal hp = 1 player-visible HP.
--
-- Note: max hp gain from XP must be no greater than 40000.
-- Add 10000 which is the base hp, and we get 50000 hp, which is 100 HP.
-- Adding 15000 to that brings us to 65000 hp, which is near the maximum the
-- engine allows us; a total of 130 HP, obtainable with the health boost item.
-- Unfortunately, this means that a bunch of people who used to have 120 HP
-- just from the XP are now suddenly down 20 HP ... and they're probably not
-- going to be happy.
--
-- The upside is that the health boost drink gives a fixed amount of HP, and is
-- available much sooner than high XP normally is. Hope it's worth it.
--
-- Note: this function must return HP from XP ONLY, without taking any other
-- factors into account, esp. NOT health boosts.
function xp.get_hp_max(pname)
	local amount = math_max(math_min(xp.get_xp(pname, "digxp"), xp.digxp_hp_max), 0)
	local hpinc = math_floor(amount / 620)
	local scale = 500
	local max_hp = math_floor((minetest.PLAYER_MAX_HP_DEFAULT + hpinc) * scale)
	return max_hp
end



function xp.update_players_max_hp(pname, login)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local pmeta = pref:get_meta()
	local max_hp = pova.get_active_modifier(pref, "properties").hp_max
	local cur_hp = pref:get_hp()

	--minetest.chat_send_all('first: hp_max: ' .. max_hp .. ', hp: ' .. cur_hp)

	if login then
		-- Get stored values.
		local str_max_hp = pmeta:get_string("hp_max")
		local str_cur_hp = pmeta:get_string("hp_cur")

		--minetest.chat_send_all('second: hp_max: ' .. str_max_hp .. ', hp: ' .. str_cur_hp)

		-- Should only happen for new players (and existing that don't have 'hp_max'
		-- or 'hp_cur' in their meta info yet).
		if str_max_hp == "" or str_cur_hp == "" then
			max_hp = minetest.PLAYER_MAX_HP_DEFAULT
			cur_hp = max_hp
		else
			max_hp = tonumber(str_max_hp)
			cur_hp = tonumber(str_cur_hp)
		end
	end

	local percent = (cur_hp / max_hp)
	if percent > 1 then percent = 1 end

	--minetest.chat_send_all('third: hp_max: ' .. max_hp .. ', hp: ' .. cur_hp .. ', percent: ' .. percent)

	local new_max_hp = xp.get_hp_max(pname)
	local new_hp = math.floor(math.min((percent * new_max_hp), new_max_hp))

	--minetest.chat_send_all('new hp: ' .. new_hp)

	-- Note: 'hp_max' must be manually stored in player meta, because Minetest
	-- does not store this itself, and reverts to HP_MAX=20 on every login. The
	-- same logic applies to 'hp_cur', which we must keep track of ourselves.
	--
	-- Note: HP max must be set *before* HP update!
	-- Otherwise set_hp() will be ignored if hp is higher than existing max!
	--
	-- Note: must manually notify the HP change reason, here.
	pova.set_modifier(pref, "properties", {hp_max = new_max_hp}, "xphp")
	armor.notify_set_hp_reason({reason="xp_update"})
	pref:set_hp(new_hp)
	pmeta:set_int("hp_max", new_max_hp)
	pmeta:set_int("hp_cur", new_hp)

	-- Manually update HUD.
	hud.player_event(pref, "health_changed")
end



function xp.on_joinplayer(player)
	minetest.after(0, xp.update_players_max_hp, player:get_player_name(), true)
end

function xp.on_leaveplayer(player)
	local meta = player:get_meta()
	meta:set_int("hp_cur", player:get_hp())
	--print("CURRENT HP ON LOGOUT: " .. meta:get_int("hp_cur"))
end



function xp.write_xp()
	if xp.dirty then
		local temp = {}
		for k, v in pairs(xp.data) do
			-- Only save XP if >= min XP.
			local n = tonumber(v)
			if n >= 5.0 then
				temp[k] = v
			end
		end
		xp.storage:from_table({fields=temp})
	end
	xp.dirty = false
end



-- Leaveplayer callbacks are not called if there are players connected during shutdown.
function xp.save_player_hps()
	local players = minetest.get_connected_players()

	for k, v in ipairs(players) do
		local meta = v:get_meta()
		meta:set_int("hp_cur", v:get_hp())
		--print("CURRENT HP ON SHUTDOWN: " .. meta:get_int("hp_cur"))
	end
end



local timer = 0
local delay = 60*5
function xp.globalstep(dtime)
	timer = timer + dtime
	if timer >= delay then
		timer = 0
		xp.write_xp()

		local done_players = {}
		for k, v in pairs(xp.dirty_players) do
			xp.update_players_max_hp(k)
			done_players[k] = true
		end
		for k, v in pairs(done_players) do
			xp.dirty_players[k] = nil
		end
	end
end



function xp.do_chatcommand(pname, param)
	local tokens = param:split(" ")
	if #tokens < 2 then
		minetest.chat_send_player(pname, "# Server: Wrong number of arguments.")
		return
	end

	if tokens[1] == "get" then
		if not minetest.player_exists(tokens[2]) then
			minetest.chat_send_player(pname, "# Server: No such player.")
			return
		end
		local amount = xp.get_xp(tokens[2], "digxp")
		minetest.chat_send_player(pname, "# Server: <" .. rename.gpn(tokens[2]) .. "> has " .. amount .. " XP.")
	elseif tokens[1] == "set" then
		if #tokens ~= 3 then
			minetest.chat_send_player(pname, "# Server: Wrong number of arguments.")
			return
		end
		if not minetest.player_exists(tokens[2]) then
			minetest.chat_send_player(pname, "# Server: No such player.")
			return
		end
		local amount = tonumber(tokens[3])
		if type(amount) == "nil" then
			minetest.chat_send_player(pname, "# Server: Couldn't parse amount.")
			return
		end
		if amount > xp.digxp_max then
			amount = xp.digxp_max
		end
		if amount < 0 then
			amount = 0
		end
		xp.set_xp(tokens[2], "digxp", amount)
		hud_clock.update_xp(tokens[2])
		amount = xp.get_xp(tokens[2], "digxp")
		minetest.chat_send_player(pname, "# Server: <" .. rename.gpn(tokens[2]) .. "> now has " .. amount .. " XP.")
	elseif tokens[1] == "add" then
		if #tokens ~= 3 then
			minetest.chat_send_player(pname, "# Server: Wrong number of arguments.")
			return
		end
		if not minetest.player_exists(tokens[2]) then
			minetest.chat_send_player(pname, "# Server: No such player.")
			return
		end
		local amount = tonumber(tokens[3])
		if type(amount) == "nil" then
			minetest.chat_send_player(pname, "# Server: Couldn't parse amount.")
			return
		end
		local total = xp.get_xp(tokens[2], "digxp")
		total = total + amount
		if total > xp.digxp_max then
			total = xp.digxp_max
		end
		if total < 0 then
			total = 0
		end
		xp.set_xp(tokens[2], "digxp", total)
		hud_clock.update_xp(tokens[2])
		amount = xp.get_xp(tokens[2], "digxp")
		minetest.chat_send_player(pname, "# Server: <" .. rename.gpn(tokens[2]) .. "> now has " .. amount .. " XP.")
	else
		minetest.chat_send_player(pname, "# Server: Invalid operation.")
		return
	end
end



if not xp.run_once then
	xp.storage = minetest.get_mod_storage()

	-- Load data.
	local data = xp.storage:to_table() or {}
	xp.data = data.fields or {}

	-- Save data.
	minetest.register_on_shutdown(function() xp.write_xp() end)
	minetest.register_on_shutdown(function() xp.save_player_hps() end)
	minetest.register_globalstep(function(...) xp.globalstep(...) end)
	minetest.register_on_joinplayer(function(...) xp.on_joinplayer(...) end)
	minetest.register_on_leaveplayer(function(...) xp.on_leaveplayer(...) end)

	minetest.register_chatcommand("digxp", {
		params = "get|set|add <player> <amount>",
		description = "Manage players' mining XP.",
		privs = {server=true},

		func = function(...)
			return xp.do_chatcommand(...)
		end
	})

	local c = "xp:core"
	local f = xp.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	xp.run_once = true
end
