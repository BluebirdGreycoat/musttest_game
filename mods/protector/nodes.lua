
-- Protectors shall not emit light. By MustTest
local PROTECTOR_LIGHT_SOURCE = 0

if not protector.nodes_registered then
	protector.nodes_registered = true

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
		light_source = PROTECTOR_LIGHT_SOURCE,

		node_box = {
			type = "fixed",
			fixed = {
				{-0.5 ,-0.5, -0.5, 0.5, 0.5, 0.5},
			}
		},

		on_place = function(...)
			return protector.check_overlap(...)
		end,

		_expired_protector_name = "protector:expired1",
		_protector_supports_members = true,
		_protector_node_radius = protector.radius,

		on_timer = function(...)
			return protector.on_timer(...)
		end,

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
		light_source = PROTECTOR_LIGHT_SOURCE,

		node_box = {
			type = "fixed",
			fixed = {
				{-0.5 ,-0.5, -0.5, 0.5, 0.5, 0.5},
			}
		},

		on_place = function(...)
			return protector.check_overlap(...)
		end,

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

		on_timer = function(...)
			return protector.on_timer(...)
		end,

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
		light_source = PROTECTOR_LIGHT_SOURCE,

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

		on_timer = function(...)
			return protector.on_timer(...)
		end,

		on_place = function(...)
			return protector.check_overlap(...)
		end,

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
		light_source = PROTECTOR_LIGHT_SOURCE,

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

		on_place = function(...)
			return protector.check_overlap(...)
		end,

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

		on_timer = function(...)
			return protector.on_timer(...)
		end,

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
end
