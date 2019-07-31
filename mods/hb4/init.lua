
hb4 = hb4 or {}
hb4.modpath = minetest.get_modpath("hb4")

dofile(hb4.modpath .. "/leafscatter.lua")
dofile(hb4.modpath .. "/fruitregrow.lua")
dofile(hb4.modpath .. "/floodfill.lua")
dofile(hb4.modpath .. "/breath.lua")
dofile(hb4.modpath .. "/notify.lua")
dofile(hb4.modpath .. "/mailall.lua")
dofile(hb4.modpath .. "/spawn_sanitizer.lua")
dofile(hb4.modpath .. "/nodeinspector.lua")
dofile(hb4.modpath .. "/diving_equipment.lua")
dofile(hb4.modpath .. "/countdown.lua")

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
			return
		end

		-- already dead?
		if player:get_hp() <= 0 then
			if data.poison then
				hud.change_item(player, "hunger", {text="hud_hunger_fg.png"})
			end
			return
		end

		if data.poison then
			hud.change_item(player, "hunger", {text="hunger_statbar_poisen.png"})
		end

		local damage = math.random(data.min, data.max)
		player:set_hp(player:get_hp() - damage)
		if data.msg and player:get_hp() <= 0 then
			minetest.chat_send_all(data.msg)
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

if not hb4.reload_registered then
	local c = "hb4:core"
	local f = hb4.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	hb4.reload_registered = true
end
