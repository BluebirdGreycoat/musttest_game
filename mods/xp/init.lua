
if not minetest.global_exists("xp") then xp = {} end
xp.modpath = minetest.get_modpath("xp")
xp.digxp_max = 1000000
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



function xp.update_players_max_hp(pname)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local amount = math_max(math_min(xp.get_xp(pname, "digxp"), 50000), 0)
	local kilos = (amount / 1000)
	local hpinc = math_floor(kilos * 2)

	local max_hp = pref:get_properties().hp_max
	local hp = pref:get_hp()
	local percent = (hp / max_hp)
	local new_max_hp = (minetest.PLAYER_MAX_HP_DEFAULT + hpinc)
	local new_hp = math_min((percent * new_max_hp), new_max_hp)

	--minetest.chat_send_all('new max hp: ' .. new_max_hp .. ', new hp: ' .. new_hp)

	pref:set_properties({hp_max = new_max_hp})
	pref:set_hp(new_hp)
end



function xp.on_joinplayer(player)
	minetest.after(10, xp.update_players_max_hp, player:get_player_name())
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



if not xp.run_once then
	xp.storage = minetest.get_mod_storage()

	-- Load data.
	local data = xp.storage:to_table() or {}
	xp.data = data.fields or {}

	-- Save data.
	minetest.register_on_shutdown(function() xp.write_xp() end)
	minetest.register_globalstep(function(...) xp.globalstep(...) end)
	minetest.register_on_joinplayer(function(...) xp.on_joinplayer(...) end)

	local c = "xp:core"
	local f = xp.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	xp.run_once = true
end
