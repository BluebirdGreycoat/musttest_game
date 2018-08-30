-- minetest/fire/init.lua

-- Global namespace for functions

fire = {}


-- Register flame nodes

minetest.register_node("fire:basic_flame", {
	drawtype = "firelike",
	tiles = {
		{
			name = "fire_basic_flame_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1
			},
		},
	},
	inventory_image = "fire_basic_flame.png",
	paramtype = "light",
	light_source = 13,
	walkable = false,
	--buildable_to = true, -- Player must remove fire before building.
	sunlight_propagates = true,
	damage_per_second = 4,
	drop = "",

	groups = {
		level=1,
		igniter = 2,
		dig_immediate = 2,
		not_in_creative_inventory = 1,
		melt_around = 3,
		flame = 1,
		flame_sound = 1,
		notify_construct = 1,
	},
    
	on_timer = function(pos)
		local f = minetest.find_node_near(pos, 1, {"group:flammable"})
		if f then
			if minetest.test_protection(f, "") then
				minetest.remove_node(pos)
				return
			end
		end
		if not f then
			minetest.remove_node(pos)
			return
		end

		-- restart timer
		local time = math.random(30, 60)
		minetest.get_node_timer(pos):start(time)
		--ambiance.fire_particles(pos, time)
	end,

    
	on_construct = function(pos)
		fireambiance.on_flame_addremove(pos)
		particles.add_flame_spawner(pos)
		local time = math.random(30, 60)
		minetest.get_node_timer(pos):start(time)
		--ambiance.fire_particles(pos, time)
		torchmelt.start_melting(pos)
	end,
    
	after_destruct = function(pos)
		particles.del_flame_spawner(pos)
		fireambiance.on_flame_addremove(pos)
	end,
    
	on_dig = function(pos, node, player)
		local pname = player and player:get_player_name() or ""
		if not heatdamage.is_immune(pname) then
			minetest.after(0, function() 
				local player = minetest.get_player_by_name(pname)
				if player and player:get_hp() > 0 then
					player:set_hp(player:get_hp() - 1)
				end
			end)
		end
		return minetest.node_dig(pos, node, player)
	end,

	--on_blast = function()
	--end, -- unaffected by explosions
})

minetest.register_node("fire:permanent_flame", {
	description = "Permanent Flame",
	drawtype = "firelike",
	tiles = {
		{
			name = "fire_basic_flame_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1
			},
		},
	},
	inventory_image = "fire_basic_flame.png",
	paramtype = "light",
	light_source = 13,
	walkable = false,
	--buildable_to = true, -- Player must remove fire before building.
	sunlight_propagates = true,
	damage_per_second = 4,
	groups = {igniter = 2, dig_immediate = 2, melt_around = 3, flame = 1, flame_sound = 1, notify_construct = 1},
	drop = "",

	on_construct = function(pos)
		fireambiance.on_flame_addremove(pos)
		particles.add_flame_spawner(pos)
		torchmelt.start_melting(pos)
	end,
	after_destruct = function(pos)
		fireambiance.on_flame_addremove(pos)
		particles.del_flame_spawner(pos)
	end,

	on_dig = function(pos, node, player)
		local pname = player and player:get_player_name() or ""
		if not heatdamage.is_immune(pname) then
			minetest.after(0, function() 
				local player = minetest.get_player_by_name(pname)
				if player and player:get_hp() > 0 then
					player:set_hp(player:get_hp() - 1)
				end
			end)
		end
		return minetest.node_dig(pos, node, player)
	end,

	--on_blast = function()
	--end,
})

minetest.register_node("fire:nether_flame", {
	description = "Nether Flame",
	drawtype = "firelike",
	tiles = {
		{
			name = "fire_nether_flame_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1
			},
		},
	},
	inventory_image = "fire_basic_flame.png",
	paramtype = "light",
	light_source = 14,
	walkable = false,
	buildable_to = false,
	sunlight_propagates = true,
	damage_per_second = 4,
	groups = {level = 1, igniter = 2, oddly_breakable_by_hand = 3, melt_around = 3, flame = 1, flame_sound = 1, notify_construct = 1},
	drop = "",
    
	on_construct = function(pos)
		fireambiance.on_flame_addremove(pos)
		particles.add_flame_spawner(pos)
		torchmelt.start_melting(pos)
	end,
    
    -- The fireportal takes care of this.
    --after_destruct = function(pos) fireambiance.on_flame_addremove(pos) end,

	on_dig = function(pos, node, player)
		local pname = player and player:get_player_name() or ""
		if not heatdamage.is_immune(pname) then
			minetest.after(0, function() 
				local player = minetest.get_player_by_name(pname)
				if player and player:get_hp() > 0 then
					player:set_hp(player:get_hp() - 1)
				end
			end)
		end
		return minetest.node_dig(pos, node, player)
	end,

	--on_blast = function()
	--end,
})



-- Override coalblock to enable permanent flame above
minetest.override_item("default:coalblock", {
	after_destruct = function(pos, oldnode)
		pos.y = pos.y + 1
		if minetest.get_node(pos).name == "fire:permanent_flame" then
			minetest.remove_node(pos)
		end
	end,
})










-- Extinguish all flames quickly with water, snow, ice

minetest.register_abm({
	label = "Extinguish flame",
	nodenames = {"group:flame"},
	neighbors = {"group:puts_out_fire"},
	interval = 3 * default.ABM_TIMER_MULTIPLIER,
	chance = 1 * default.ABM_CHANCE_MULTIPLIER,
	catch_up = false,
	action = function(pos, node, active_object_count, active_object_count_wider)
		minetest.remove_node(pos)
		minetest.sound_play("fire_extinguish_flame",
			{pos = pos, max_hear_distance = 16, gain = 0.25})
	end,
})


-- Enable the following ABMs according to 'enable fire' setting

	minetest.register_abm({
		label = "Ignite flame",
		nodenames = {"group:flammable"},
		neighbors = {"group:igniter"},
		interval = 3 * default.ABM_TIMER_MULTIPLIER,--7/2,
		chance = 6 * default.ABM_CHANCE_MULTIPLIER,--12/2,
		catch_up = false,
		action = function(pos, node, active_object_count, active_object_count_wider)
			-- If there is water or stuff like that around node, don't ignite
			if minetest.find_node_near(pos, 1, {"group:puts_out_fire"}) then
				return
			end
			local p
			local def = minetest.registered_nodes[node.name]
			if def and def.buildable_to then
				-- Flame replaces flammable node itself if node is buildable to.
				p = pos
			else
				p = minetest.find_node_near(pos, 1, {"air"})
			end
			if p then
				if minetest.test_protection(p, "") then
					return
				end
				minetest.set_node(p, {name = "fire:basic_flame"})
			end
		end,
	})

	-- Remove flammable nodes

	minetest.register_abm({
		label = "Remove flammable nodes",
		nodenames = {"fire:basic_flame", "fire:nether_flame"},
		neighbors = "group:flammable",
		interval = 3 * default.ABM_TIMER_MULTIPLIER,
		chance = 10 * default.ABM_CHANCE_MULTIPLIER,
		catch_up = false,
		action = function(pos, node, active_object_count, active_object_count_wider)
			local p = minetest.find_node_near(pos, 1, {"group:flammable"})
			if p then
				if minetest.test_protection(p, "") then
					return
				end
				-- remove flammable nodes around flame
				local flammable_node = minetest.get_node(p)
				local def = minetest.registered_nodes[flammable_node.name]
				if def.on_burn then
					def.on_burn(p)
				else
					minetest.remove_node(p)
					minetest.check_for_falling(p)
				end
			end
		end,
	})

