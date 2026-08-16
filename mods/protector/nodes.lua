
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
		_protector_displayent_name = "protector:display",

		on_timer = function(...)
			return protector.on_timer(...)
		end,

		after_place_node = function(...)
			return protector.after_place_node(...)
		end,

		on_use = function(...)
			return protector.node_on_use(...)
		end,

		on_rightclick = function(...)
			return protector.node_on_rightclick(...)
		end,

		on_punch = function(...)
			return protector.node_on_punch(...)
		end,

		can_dig = function(...)
			return protector.node_can_dig(...)
		end,

		-- TNT-proof.
		on_blast = function(...)
			return protector.on_blast(...)
		end,

		-- Called by rename LBM.
		_on_update_infotext = function(pos)
			protector.on_update_infotext_lbm(pos)
		end,

		on_destruct = function(...)
			return protector.on_destruct(...)
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

		after_place_node = function(...)
			return protector.after_place_node(...)
		end,

		_expired_protector_name = "protector:expired1",
		_protector_node_radius = protector.radius_small,
		_protector_displayent_name = "protector:display_small",

		on_timer = function(...)
			return protector.on_timer(...)
		end,

		on_use = function(...)
			return protector.node_on_use(...)
		end,

		-- This protector does not have a formspec, no on_rightclick defined.

		on_punch = function(...)
			return protector.node_on_punch(...)
		end,

		can_dig = function(...)
			return protector.node_can_dig(...)
		end,

		-- TNT-proof.
		on_blast = function(...)
			return protector.on_blast(...)
		end,

		-- Called by rename LBM.
		_on_update_infotext = function(pos)
			protector.on_update_infotext_lbm(pos)
		end,

		on_destruct = function(...)
			return protector.on_destruct(...)
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
		_protector_displayent_name = "protector:display",

		on_timer = function(...)
			return protector.on_timer(...)
		end,

		on_place = function(...)
			return protector.check_overlap(...)
		end,

		after_place_node = function(...)
			return protector.after_place_node(...)
		end,

		on_use = function(...)
			return protector.node_on_use(...)
		end,

		on_rightclick = function(...)
			return protector.node_on_rightclick(...)
		end,

		on_punch = function(...)
			return protector.node_on_punch(...)
		end,

		can_dig = function(...)
			return protector.node_can_dig(...)
		end,

		-- TNT-proof.
		on_blast = function(...)
			return protector.on_blast(...)
		end,

		-- Called by rename LBM.
		_on_update_infotext = function(pos)
			protector.on_update_infotext_lbm(pos)
		end,

		on_destruct = function(...)
			return protector.on_destruct(...)
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

		after_place_node = function(...)
			return protector.after_place_node(...)
		end,

		_expired_protector_name = "protector:expired2",
		_protector_node_radius = protector.radius_small,
		_protector_displayent_name = "protector:display_small",

		on_timer = function(...)
			return protector.on_timer(...)
		end,

		on_use = function(...)
			return protector.node_on_use(...)
		end,

		-- This protector does not have a formspec, no on_rightclick defined.

		on_punch = function(...)
			return protector.node_on_punch(...)
		end,

		can_dig = function(...)
			return protector.node_can_dig(...)
		end,

		-- TNT-proof.
		on_blast = function(...)
			return protector.on_blast(...)
		end,

		-- Called by rename LBM.
		_on_update_infotext = function(pos)
			protector.on_update_infotext_lbm(pos)
		end,

		on_destruct = function(...)
			return protector.on_destruct(...)
		end,
	})

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
end
