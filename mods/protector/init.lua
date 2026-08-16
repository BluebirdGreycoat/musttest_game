
if not minetest.global_exists("protector") then protector = {} end
protector.players = protector.players or {} -- Security contexts.
protector.player_guis = protector.player_guis or {} -- GUI contexts (not security).
protector.mod = "redo"
protector.modpath = minetest.get_modpath("protector")
protector.radius = 5 -- Radius is permanent and can never be changed.
protector.radius_small = 3 -- Must always be smaller than primary radius.
protector.max_share_count = 16 -- If you go this high you are stupid.
protector.PROTECTION_ENABLED = true
protector.flip = minetest.settings:get_bool("protector_flip") or false
protector.hurt = (tonumber(minetest.settings:get("protector_hurt")) or 0)
protector.display_time = 60*2
reload.install_simple_signals(protector)

dofile(protector.modpath .. "/hud.lua")
dofile(protector.modpath .. "/tool.lua")
dofile(protector.modpath .. "/formspec.lua")
dofile(protector.modpath .. "/functions.lua")
dofile(protector.modpath .. "/memlist.lua")
dofile(protector.modpath .. "/override.lua")



--= Protection Lock

minetest.register_node("protector:protect", {
	description = "Advanced Protector Stone\nArea Protected: 11x11x11",
	drawtype = "nodebox",
	tiles = {
		"moreblocks_circle_stone_bricks.png",
		"moreblocks_circle_stone_bricks.png",
		"moreblocks_circle_stone_bricks.png^protector_logo_item.png"
	},
	sounds = default.node_sound_stone_defaults(),
	groups = utility.dig_groups("bigitem", {
    immovable = 1, -- No pistons, no nothing.
		protector = 1,
  }),
	is_ground_content = false,
	paramtype = "light",
	movement_speed_multiplier = default.NORM_SPEED,

	-- Protectors shall not emit light. By MustTest
	--light_source = 4,

	node_box = {
		type = "fixed",
		fixed = {
			{-0.5 ,-0.5, -0.5, 0.5, 0.5, 0.5},
		}
	},

	on_place = protector.check_overlap,

	_expired_protector_name = "protector:expired1",
	_protector_supports_members = true,
	_protector_node_radius = protector.radius,

	on_timer = protector.on_timer,

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		protector.timed_setup(pos, placer, meta)
		protector.initialize_meta(meta, placer)

		-- Notify nearby players.
		protector.update_nearby_players(pos)
		protector.clear_protection_cancel(pos)
	end,

	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end

		protector.can_dig(protector.radius, 1, "protector:protect", pointed_thing.under, user:get_player_name(), false, 2)
	end,

	on_rightclick = function(pos, node, clicker, itemstack)
		local meta = minetest.get_meta(pos)
		local name = clicker:get_player_name() or ""

		if meta and protector.can_dig(1, 1, "protector:protect", pos, name, true, 1) then
			protector.players[name] = pos
			minetest.show_formspec(name, "protector:node", protector.generate_formspec(name, meta))
		end
	end,

	on_punch = function(pos, node, puncher)
		if minetest.test_protection(pos, puncher:get_player_name()) then
			return
		end

		protector.toggle_area_display(pos, "protector:display")
	end,

	can_dig = function(pos, player)
		return player and protector.can_dig(1, 1, "protector:protect", pos, player:get_player_name(), true, 1)
	end,

	-- TNT-proof.
	on_blast = function() end,

	-- Called by rename LBM.
	_on_update_infotext = function(pos)
		protector.on_update_infotext_lbm(pos)
	end,

	on_destruct = function(pos)
		-- Notify nearby players.
		minetest.after(0, protector.update_nearby_players, pos)

		return protector.remove_area_display(pos)
	end,
})

minetest.register_node("protector:protect3", {
	description = "Protector Stone\nArea Protected: 7x7x7",
	drawtype = "nodebox",
	tiles = {"cityblock.png"},
	sounds = default.node_sound_stone_defaults(),
	groups = utility.dig_groups("bigitem", {
    immovable = 1, -- No pistons, no nothing.
		protector = 1,
  }),
	is_ground_content = false,
	paramtype = "light",
	movement_speed_multiplier = default.NORM_SPEED,

	-- Protectors shall not emit light. By MustTest
	--light_source = 4,

	node_box = {
		type = "fixed",
		fixed = {
			{-0.5 ,-0.5, -0.5, 0.5, 0.5, 0.5},
		}
	},

	on_place = protector.check_overlap,

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		protector.timed_setup(pos, placer, meta)
		protector.initialize_meta(meta, placer)

		-- Notify nearby players.
		protector.update_nearby_players(pos)
		protector.clear_protection_cancel(pos)
	end,

	_expired_protector_name = "protector:expired1",
	_protector_node_radius = protector.radius_small,

	on_timer = protector.on_timer,

	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end

		protector.can_dig(protector.radius, 1, "protector:protect3", pointed_thing.under, user:get_player_name(), false, 2)
	end,

	-- This protector does not have a formspec, no on_rightclick defined.

	on_punch = function(pos, node, puncher)
		if minetest.test_protection(pos, puncher:get_player_name()) then
			return
		end

		protector.toggle_area_display(pos, "protector:display_small")
	end,

	can_dig = function(pos, player)
		return player and protector.can_dig(1, 1, "protector:protect3", pos, player:get_player_name(), true, 1)
	end,

	-- TNT-proof.
	on_blast = function() end,

	-- Called by rename LBM.
	_on_update_infotext = function(pos)
		protector.on_update_infotext_lbm(pos)
	end,

	on_destruct = function(pos)
		-- Notify nearby players.
		minetest.after(0, protector.update_nearby_players, pos)

		return protector.remove_area_display(pos)
	end,
})


--= Protection Logo

minetest.register_node("protector:protect2", {
	description = "Skyway Protector\nArea Protected: 11x11x11\nWarning: nearly invisible!",
	tiles = {"protector_logo.png"},
	wield_image = "protector_logo_item.png",
	inventory_image = "protector_logo_item.png",
	sounds = default.node_sound_stone_defaults(),
	groups = utility.dig_groups("bigitem", {
    immovable = 1, -- No pistons, no nothing.
		protector = 1,
  }),
  use_texture_alpha = "blend",
	paramtype = 'light',
	paramtype2 = "wallmounted",
	legacy_wallmounted = true,

	-- Protectors shall not emit light. By MustTest
	--light_source = 4,

	drawtype = "nodebox",
	sunlight_propagates = true,
	walkable = false,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.375, 0.4375, -0.5, 0.375, 0.5, 0.5},
		wall_bottom = {-0.375, -0.5, -0.5, 0.375, -0.4375, 0.5},
		wall_side   = {-0.5, -0.5, -0.375, -0.4375, 0.5, 0.375},
	},
	selection_box = {type = "wallmounted"},

	_expired_protector_name = "protector:expired2",
	_protector_supports_members = true,
	_protector_node_radius = protector.radius,

	on_timer = protector.on_timer,

	on_place = protector.check_overlap,

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		protector.timed_setup(pos, placer, meta)
		protector.initialize_meta(meta, placer)

		-- Notify nearby players.
		protector.update_nearby_players(pos)
		protector.clear_protection_cancel(pos)
	end,

	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end

		protector.can_dig(protector.radius, 1, "protector:protect2", pointed_thing.under, user:get_player_name(), false, 2)
	end,

	on_rightclick = function(pos, node, clicker, itemstack)
		local meta = minetest.get_meta(pos)
		local name = clicker:get_player_name() or ""

		if meta and protector.can_dig(1, 1, "protector:protect2", pos, name, true, 1) then
			protector.players[name] = pos
			minetest.show_formspec(name, "protector:node", protector.generate_formspec(name, meta))
		end
	end,

	on_punch = function(pos, node, puncher)
		if minetest.test_protection(pos, puncher:get_player_name()) then
			return
		end

		protector.toggle_area_display(pos, "protector:display")
	end,

	can_dig = function(pos, player)
		return player and protector.can_dig(1, 1, "protector:protect2", pos, player:get_player_name(), true, 1)
	end,

	-- TNT-proof.
	on_blast = function() end,

	-- Called by rename LBM.
	_on_update_infotext = function(pos)
		protector.on_update_infotext_lbm(pos)
	end,

	on_destruct = function(pos)
		-- Notify nearby players.
		minetest.after(0, protector.update_nearby_players, pos)

		return protector.remove_area_display(pos)
	end,
})

minetest.register_node("protector:protect4", {
	description = "Protection Lock\nArea Protected: 7x7x7",
	tiles = {"protector_lock.png"},
	wield_image = "protector_lock.png",
	inventory_image = "protector_lock.png",
	sounds = default.node_sound_stone_defaults(),
	groups = utility.dig_groups("bigitem", {
    immovable = 1, -- No pistons, no nothing.
		protector = 1,
  }),
	paramtype = 'light',
	paramtype2 = "wallmounted",
	legacy_wallmounted = true,

	-- Protectors shall not emit light. By MustTest
	--light_source = 4,

	drawtype = "nodebox",
	sunlight_propagates = true,
	walkable = false,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.375, 0.4375, -0.5, 0.375, 0.5, 0.5},
		wall_bottom = {-0.375, -0.5, -0.5, 0.375, -0.4375, 0.5},
		wall_side   = {-0.5, -0.5, -0.375, -0.4375, 0.5, 0.375},
	},
	selection_box = {type = "wallmounted"},

	on_place = protector.check_overlap,

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		protector.timed_setup(pos, placer, meta)
		protector.initialize_meta(meta, placer)

		-- Notify nearby players.
		protector.update_nearby_players(pos)
		protector.clear_protection_cancel(pos)
	end,

	_expired_protector_name = "protector:expired2",
	_protector_node_radius = protector.radius_small,

	on_timer = protector.on_timer,

	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end

		protector.can_dig(protector.radius, 1, "protector:protect4", pointed_thing.under, user:get_player_name(), false, 2)
	end,

	-- This protector does not have a formspec, no on_rightclick defined.

	on_punch = function(pos, node, puncher)
		if minetest.test_protection(pos, puncher:get_player_name()) then
			return
		end

		protector.toggle_area_display(pos, "protector:display_small")
	end,

	can_dig = function(pos, player)
		return player and protector.can_dig(1, 1, "protector:protect4", pos, player:get_player_name(), true, 1)
	end,

	-- TNT-proof.
	on_blast = function() end,

	-- Called by rename LBM.
	_on_update_infotext = function(pos)
		protector.on_update_infotext_lbm(pos)
	end,

	on_destruct = function(pos)
		-- Notify nearby players.
		minetest.after(0, protector.update_nearby_players, pos)

		return protector.remove_area_display(pos)
	end,
})

-- If name entered or button press

minetest.register_on_player_receive_fields(function(...)
	return protector.on_receive_fields(...)
end)

-- Display entity shown when protector node is punched

minetest.register_entity("protector:display", {
	physical = false,
	collisionbox = {0, 0, 0, 0, 0, 0},
	visual = "wielditem",
	-- wielditem seems to be scaled to 1.5 times original node size
	visual_size = {x = 1.0 / 1.5, y = 1.0 / 1.5},
	textures = {"protector:display_node"},
	timer = 0,
	glow = 14,

	on_step = function(self, dtime)
		self.timer = self.timer + dtime
		if self.timer > protector.display_time then
			self.object:remove()
		end
	end,

	on_blast = function(self, damage)
		return false, false, {}
	end,
})

minetest.register_entity("protector:display_small", {
	physical = false,
	collisionbox = {0, 0, 0, 0, 0, 0},
	visual = "wielditem",
	-- wielditem seems to be scaled to 1.5 times original node size
	visual_size = {x = 1.0 / 1.5, y = 1.0 / 1.5},
	textures = {"protector:display_node_small"},
	timer = 0,
	glow = 14,

	on_step = function(self, dtime)
		self.timer = self.timer + dtime
		if self.timer > protector.display_time then
			self.object:remove()
		end
	end,

	on_blast = function(self, damage)
		return false, false, {}
	end,
})

-- Display-zone node, Do NOT place the display as a node,
-- it is made to be used as an entity (see above)

do
	local x = protector.radius
	minetest.register_node("protector:display_node", {
		tiles = {"protector_display.png"},
		use_texture_alpha = "blend",
		walkable = false,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				-- sides
				{-(x+.55), -(x+.55), -(x+.55), -(x+.45), (x+.55), (x+.55)},
				{-(x+.55), -(x+.55), (x+.45), (x+.55), (x+.55), (x+.55)},
				{(x+.45), -(x+.55), -(x+.55), (x+.55), (x+.55), (x+.55)},
				{-(x+.55), -(x+.55), -(x+.55), (x+.55), (x+.55), -(x+.45)},
				-- top
				{-(x+.55), (x+.45), -(x+.55), (x+.55), (x+.55), (x+.55)},
				-- bottom
				{-(x+.55), -(x+.55), -(x+.55), (x+.55), -(x+.45), (x+.55)},
				-- middle (surround protector)
				{-.55,-.55,-.55, .55,.55,.55},
			},
		},
		selection_box = {
			type = "regular",
		},
		paramtype = "light",
		groups = utility.dig_groups("item", {not_in_creative_inventory = 1}),
		drop = "",
	})
end



do
	local x = protector.radius_small
	minetest.register_node("protector:display_node_small", {
		tiles = {"protector_display.png"},
		use_texture_alpha = "blend",
		walkable = false,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				-- sides
				{-(x+.55), -(x+.55), -(x+.55), -(x+.45), (x+.55), (x+.55)},
				{-(x+.55), -(x+.55), (x+.45), (x+.55), (x+.55), (x+.55)},
				{(x+.45), -(x+.55), -(x+.55), (x+.55), (x+.55), (x+.55)},
				{-(x+.55), -(x+.55), -(x+.55), (x+.55), (x+.55), -(x+.45)},
				-- top
				{-(x+.55), (x+.45), -(x+.55), (x+.55), (x+.55), (x+.55)},
				-- bottom
				{-(x+.55), -(x+.55), -(x+.55), (x+.55), -(x+.45), (x+.55)},
				-- middle (surround protector)
				{-.55,-.55,-.55, .55,.55,.55},
			},
		},
		selection_box = {
			type = "regular",
		},
		paramtype = "light",
		groups = utility.dig_groups("item", {not_in_creative_inventory = 1}),
		drop = "",
	})
end



function protector.remove_area_display(pos)
	local ents = minetest.get_objects_inside_radius(pos, 0.5)
	for k, n in ipairs(ents) do
		if not n:is_player() and n:get_luaentity() then
			local name = n:get_luaentity().name or ""
			if name == "protector:display" or name == "protector:display_small" then
				n:remove()
			end
		end
	end
end

function protector.toggle_area_display(pos, entity)
	local got_any = false
	local ents = minetest.get_objects_inside_radius(pos, 0.5)
	for k, n in ipairs(ents) do
		if not n:is_player() and n:get_luaentity() then
			local name = n:get_luaentity().name or ""
			if name == "protector:display" or name == "protector:display_small" then
				n:remove()
				got_any = true
			end
		end
	end
	if not got_any then
		minetest.add_entity(pos, entity)
	end
	return not got_any -- True if entity added, otherwise false.
end

dofile(protector.modpath .. "/crafts.lua")



-- Expired protector node.
minetest.register_node("protector:expired1", {
	description = "Expired Protector",
	drawtype = "nodebox",
	tiles = {"cityblock.png"},
	sounds = default.node_sound_stone_defaults(),
	groups = utility.dig_groups("bigitem"),
	paramtype = "light",
	movement_speed_multiplier = default.NORM_SPEED,

	node_box = {
		type = "fixed",
		fixed = {
			{-0.5 ,-0.5, -0.5, 0.5, 0.5, 0.5},
		}
	},
})

minetest.register_node("protector:expired2", {
	description = "Expired Protector",
	tiles = {"protector_lock.png"},
	wield_image = "protector_lock.png",
	inventory_image = "protector_lock.png",
	sounds = default.node_sound_stone_defaults(),
	groups = utility.dig_groups("bigitem"),
	paramtype = 'light',
	paramtype2 = "wallmounted",
	legacy_wallmounted = true,

	drawtype = "nodebox",
	sunlight_propagates = true,
	walkable = false,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.375, 0.4375, -0.5, 0.375, 0.5, 0.5},
		wall_bottom = {-0.375, -0.5, -0.5, 0.375, -0.4375, 0.5},
		wall_side   = {-0.5, -0.5, -0.375, -0.4375, 0.5, 0.375},
	},
	selection_box = {type = "wallmounted"},
})

minetest.register_privilege("delprotect", {
	description = "Ignore player protection.",
	give_to_singleplayer = false,
})
