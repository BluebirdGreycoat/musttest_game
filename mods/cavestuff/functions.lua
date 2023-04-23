
if not minetest.global_exists("cavestuff") then cavestuff = {} end
cavestuff.modpath = minetest.get_modpath("cavestuff")

-- Localize for performance.
local math_random = math.random

-- Hot cobble functions.
cavestuff.hotcobble = cavestuff.hotcobble or {}



function cavestuff.hotcobble.after_place_node(pos, placer, itemstack, pointed_thing)
	if not placer or not placer:is_player() then
		return
	end
	-- Prevent players from placing hot cobble.
	if not heatdamage.is_immune(placer:get_player_name()) then
		utility.damage_player(placer, "heat", (2*500))
	end

	minetest.sound_play("default_cool_lava", {pos=pos, max_hear_distance=16, gain=0.25}, true)

	if rc.position_underground(pos) then
		-- Underground, placing hot cobble is the same as placing a lava source.
		-- The action of placing it destabilizes it enough to become fully melted.
		minetest.add_node(pos, {name="default:lava_flowing"})
	else
		-- Don't allow hot cobble to be placed above surface level.
		minetest.add_node(pos, {name="default:cobble"})
	end
end



function cavestuff.hotcobble.after_dig_node(pos, oldnode, oldmetadata, digger)
	if not digger or not digger:is_player() then
		return
	end
	-- Damage player when digging.
	if not heatdamage.is_immune(digger:get_player_name()) then
		utility.damage_player(digger, "heat", (2*500))
	end
	minetest.sound_play("default_cool_lava", {pos=pos, max_hear_distance=16, gain=0.25}, true)

	-- Rockmelt always turns back to lava when dug if there is lava beside it.
	-- This makes it possible to farm lava above -20.
	local positions = {
		{x=pos.x+1, y=pos.y, z=pos.z},
		{x=pos.x-1, y=pos.y, z=pos.z},
		{x=pos.x, y=pos.y, z=pos.z+1},
		{x=pos.x, y=pos.y, z=pos.z-1},
	}
	for k, v in ipairs(positions) do
		local node = minetest.get_node(v)
		if string.find(node.name, ":lava_") then
			minetest.add_node(pos, {name="default:lava_source"})
			return
		end
	end

	if rc.position_underground(pos) then
		-- Underground, digging hot cobble is enough to destabilize it and turn it into a lava source.
		minetest.add_node(pos, {name="default:lava_source"})
	else
		-- To prevent lava griefs of buildings on the surface, don't convert hot cobble to lava when dug.
		minetest.add_node(pos, {name="default:cobble"})
	end
end



function cavestuff.hotcobble.on_player_walk_over(pos, player)
	-- Damage players who walk on hot cobble.
	if not heatdamage.is_immune(player:get_player_name()) then
		utility.damage_player(player, "heat", (1*500))
	end
end



function cavestuff.hotcobble.on_finish_collapse(pos, node)
	if pos.y < -10 then
		if math_random(1, 10) > 8 then
			minetest.swap_node(pos, {name="default:lava_source"})
		elseif math_random(1, 75) == 1 then
			minetest.remove_node(pos)
			
			-- Detonate some TNT!
			-- Warning: this causes fatal lava tunneling which can ruin the map!
			-- (And player's fun.)
			-- Increased chance from 2 in 10 to 1 in 75. Let us see how it goes.
			--[[
			tnt.boom(pos, {
				radius = 5,
				ignore_protection = false,
				ignore_on_blast = false,
				damage_radius = 10,
				disable_drops = true,
				make_sound = false, -- The TNT boom sound wrecks the ambiance.
			})
			--]]
		else
			-- Do nothing.
		end
	else
		minetest.swap_node(pos, {name="default:cobble"})
	end
end



if not cavestuff.run_once then
	local c = "cavestuff:core"
	local f = cavestuff.modpath .. "/functions.lua"
	reload.register_file(c, f, false)

	cavestuff.run_once = true
end

