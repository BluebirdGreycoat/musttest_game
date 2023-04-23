
if not minetest.global_exists("hb4") then hb4 = {} end
hb4.modpath = minetest.get_modpath("hb4")

-- Localize for performance.
local math_random = math.random
local math_max = math.max

dofile(hb4.modpath .. "/leafscatter.lua")
dofile(hb4.modpath .. "/fruitregrow.lua")
dofile(hb4.modpath .. "/floodfill.lua")
dofile(hb4.modpath .. "/breath.lua")
dofile(hb4.modpath .. "/notify.lua")
dofile(hb4.modpath .. "/mailall.lua")
dofile(hb4.modpath .. "/spawn_sanitizer.lua")
dofile(hb4.modpath .. "/nodeinspector.lua")
dofile(hb4.modpath .. "/diving_equipment.lua")
dofile(hb4.modpath .. "/find_ground.lua")

-- Server restart countdown not active in singleplayer.
if not minetest.is_singleplayer() then
	dofile(hb4.modpath .. "/countdown.lua")
end

--[[
	{name="player", step=2, min=1, max=3, msg="He died!", poison=false}
--]]
function hb4.delayed_harm2(data)
	local player = minetest.get_player_by_name(data.name)
	if player then
		-- finished harming?
		if data.step < 1 then
			if data.poison then
				hud.change_item(player, "hunger", {text="hud_hunger_fg.png"})
			end
			-- Execute termination callback.
			if data.done then
				data.done()
			end
			return
		end

		if data.poison then
			hud.change_item(player, "hunger", {text="hunger_statbar_poisen.png"})
		end

		local damage = math_random(data.min, data.max)
		local hp = player:get_hp()
		if hp > (data.hp_min or 0) then
			local new_hp = hp - damage
			new_hp = math_max(new_hp, (data.hp_min or 0))

			-- Ensure damage is not greater than would cause player to go under 'hp_min'.
			local hpdiff = (hp - new_hp)
			local dtype = "fleshy"
			if data.poison then
				dtype = "poison"
			end
			utility.damage_player(player, dtype, hpdiff)
		end

		-- Message is printed only if player died. Return if we killed them.
		if player:get_hp() <= 0 then
			if data.poison then
				hud.change_item(player, "hunger", {text="hud_hunger_fg.png"})
			end
			-- Execute termination callback.
			if data.done then
				data.done()
			end
			if data.msg then
				minetest.chat_send_all(data.msg)
			end
			return
		end

		data.step = data.step - 1
		local time = (data.time or 1)
		minetest.after(time, hb4.delayed_harm2, data)
	else
		-- Player logged off. Wait until they come back.
		-- Player cannot escape harm!
		minetest.after(10, hb4.delayed_harm2, data)
	end
end

function hb4.delayed_harm(data)
	minetest.after(0, hb4.delayed_harm2, data)
end



-- Return reference to nearest player, or nil.
function hb4.nearest_player(pos)
	local players = minetest.get_connected_players()

	local pref
	local dist = 100000

	for i=1, #players, 1 do
		local p = players[i]
		local d = vector.distance(p:get_pos(), pos)
		if d < dist then
			dist = d
			pref = p
		end
	end

	return pref
end



-- Return reference to nearest player, or nil.
function hb4.nearest_player_not(pos, pnot)
	local players = minetest.get_connected_players()
	local admin = minetest.get_player_by_name(gdac.name_of_admin)

	local pref
	local dist = 100000

	for i=1, #players, 1 do
		local p = players[i]
		if p ~= pnot and p ~= admin then
			local d = vector.distance(p:get_pos(), pos)
			if d < dist then
				dist = d
				pref = p
			end
		end
	end

	return pref
end



if not hb4.reload_registered then
	local c = "hb4:core"
	local f = hb4.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	hb4.reload_registered = true
end
