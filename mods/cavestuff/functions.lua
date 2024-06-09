
if not minetest.global_exists("cavestuff") then cavestuff = {} end
cavestuff.modpath = minetest.get_modpath("cavestuff")

-- Localize for performance.
local math_random = math.random

-- Node functions.
cavestuff.hotcobble = cavestuff.hotcobble or {}
cavestuff.white_crystal = cavestuff.white_crystal or {}



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



function cavestuff.white_crystal.after_dig_node(pos, oldnode, metadata, digger)
	if not digger or not digger:is_player() then
		return
	end
	local pname = digger:get_player_name()
	--minetest.chat_send_all('oldnode: ' .. dump(oldnode))
	-- Drop nodes hanging.
	for k = 1, 16 do
		local p = vector.add(pos, {x=0, y=-k, z=0})
		local n = minetest.get_node(p)
		--minetest.chat_send_all(dump(n))
		if n.name == oldnode.name and not minetest.test_protection(p, pname) then
			--minetest.chat_send_all('drop node')
			--local time = 1/k
			minetest.after(0, sfn.drop_node, p)
			--minetest.set_node(p, {name="default:stone"})
		else
			break
		end
	end
	-- Drop nodes standing.
	for k = 1, 16 do
		local p = vector.add(pos, {x=0, y=k, z=0})
		local n = minetest.get_node(p)
		--minetest.chat_send_all(dump(n))
		if n.name == oldnode.name and not minetest.test_protection(p, pname) then
			--minetest.chat_send_all('drop node')
			--local time = 1/k
			minetest.after(0, sfn.drop_node, p)
			--minetest.set_node(p, {name="default:stone"})
		else
			break
		end
	end
end



-- For testing.
local FAST_CRYSTAL_GROWTH = false

function cavestuff.white_crystal.on_construct(pos)
	local timer = minetest.get_node_timer(pos)
	if not FAST_CRYSTAL_GROWTH then
		timer:start(60*math.random(15, 60))
	else
		timer:start(5)
	end
end



function cavestuff.white_crystal.on_timer(pos, elapsed)
	local sides = {
		{x=pos.x+1, y=pos.y, z=pos.z},
		{x=pos.x-1, y=pos.y, z=pos.z},
		{x=pos.x, y=pos.y, z=pos.z+1},
		{x=pos.x, y=pos.y, z=pos.z-1},
	}

	local lava = 0
	local water = 0

	for k = 1, #sides do
		local n = minetest.get_node(sides[k])
		if minetest.get_item_group(n.name, "lava") ~= 0 then
			lava = lava + 1
		end
		if minetest.get_item_group(n.name, "water") ~= 0 then
			water = water + 1
		end
	end

	if water > 0 and lava > 0 then
		local above = {x=pos.x, y=pos.y+1, z=pos.z}
		local c = minetest.get_node(above)
		if c.name == "cavestuff:whitespike4" then
			local under = {x=pos.x, y=pos.y-1, z=pos.z}
			local n = minetest.get_node(under)
			local ndef = minetest.registered_nodes[n.name]
			-- Only ground content in group "ore" is eligible to be a transmutation source.
			if ndef.is_ground_content and minetest.get_item_group(n.name, "ore") ~= 0 then
				minetest.set_node(pos, {name="glowstone:minerals"})
				minetest.sound_play("default_cool_lava", {pos=pos, max_hear_distance=16, gain=0.25}, true)
				return
			end
		elseif c.name == "cavestuff:whitespike3" then
			minetest.swap_node(above, {name="cavestuff:whitespike4", param2=math.random(0, 3)})
			minetest.sound_play("default_cool_lava", {pos=pos, max_hear_distance=16, gain=0.25}, true)
		elseif c.name == "cavestuff:whitespike2" then
			minetest.swap_node(above, {name="cavestuff:whitespike3", param2=math.random(0, 3)})
			minetest.sound_play("default_cool_lava", {pos=pos, max_hear_distance=16, gain=0.25}, true)
		elseif c.name == "cavestuff:whitespike1" then
			minetest.swap_node(above, {name="cavestuff:whitespike2", param2=math.random(0, 3)})
			minetest.sound_play("default_cool_lava", {pos=pos, max_hear_distance=16, gain=0.25}, true)
		elseif c.name == "air" then
			minetest.swap_node(above, {name="cavestuff:whitespike1", param2=math.random(0, 3)})
			minetest.sound_play("default_cool_lava", {pos=pos, max_hear_distance=16, gain=0.25}, true)
		end
	end

	-- If transmutation not finished, restart timer.
	local timer = minetest.get_node_timer(pos)
	if not FAST_CRYSTAL_GROWTH then
		timer:start(60*math.random(15, 60))
	else
		timer:start(5)
	end
end



if not cavestuff.run_once then
	local c = "cavestuff:core"
	local f = cavestuff.modpath .. "/functions.lua"
	reload.register_file(c, f, false)

	cavestuff.run_once = true
end

