
local box = {
	type = "fixed",
	fixed = {-0.5, -0.5, (-0.5/8)*4, 0.5, 0.5, (0.5/8)*4},
}

local anim = {
	type = "vertical_frames",
	aspect_w = 16,
	aspect_h = 16,
	length = 0.9
}



-- Portal liquid. The event-horizon of a portal.
-- Specifically designed with obsidian gates (4x5 vertical frames) in mind.
minetest.register_node("nether:portal_liquid", {
	description = 'Portal Liquid (You Hacker, You!)',
	paramtype2 = "colorfacedir",
	groups = {unbreakable=1, immovable=1, not_in_creative_inventory=1},
	drop = "",
	drawtype = "nodebox",
	paramtype = "light",
	palette = "nether_portals_palette.png",
	tiles = {
		'nether_transparent.png',
		'nether_transparent.png',
		'nether_transparent.png',
		'nether_transparent.png',
		{name='nether_portal.png', animation=anim},
		{name='nether_portal.png', animation=anim},
	},
	node_box = box,
	use_texture_alpha = "blend",
	walkable = false,
	pointable = false,
	floodable = true,

	-- Necessary to allow bone placement, and to let players "pop" the portal by
	-- e.g., placing a torch inside.
	buildable_to = true,

	is_ground_content = false,
	diggable = false,
	light_source = 5,
	sunlight_propagates = true,
	post_effect_color = {a = 160, r = 128, g = 0, b = 80},
	on_rotate = false,

	-- No fixed functions.
	on_construct = function(...)
		return nether.liquid_on_construct(...)
	end,

	on_destruct = function(...)
		return nether.liquid_on_destruct(...)
	end,

	on_timer = function(...)
		return nether.liquid_on_timer(...)
	end,

	on_flood = function(...)
		return nether.liquid_on_flood(...)
	end,

	-- Slow down player movement.
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,
	move_resistance = 3,

	-- Prevent obtaining this node by getting it to fall.
	on_finish_collapse = function(pos, node) minetest.remove_node(pos) end,
	on_collapse_to_entity = function() end,
})



-- Invisible portal node. Must be as similar to the regular portal liquid as
-- possible, to permit swapping without damage to metadata/param2 values.
minetest.register_node("nether:portal_hidden", {
	description = 'Portal Hidden (You Hacker, You!)',
	paramtype2 = "colorfacedir",
	groups = {unbreakable=1, immovable=1, not_in_creative_inventory=1},
	drop = "",
	drawtype = "airlike",
	paramtype = "light",
	palette = "nether_portals_palette.png",
	tiles = {
		'nether_transparent.png',
		'nether_transparent.png',
		'nether_transparent.png',
		'nether_transparent.png',
		'nether_transparent.png',
		'nether_transparent.png',
	},
	node_box = box,
	use_texture_alpha = "blend",
	walkable = false,
	pointable = false,
	floodable = true,

	-- Necessary to allow bone placement, and to let players "pop" the portal by
	-- e.g., placing a torch inside.
	buildable_to = true,

	is_ground_content = false,
	diggable = false,
	sunlight_propagates = true,
	post_effect_color = {a = 0, r = 0, g = 0, b = 0},
	on_rotate = false,

	-- No fixed functions.
	on_construct = function(...)
		return nether.hidden_on_construct(...)
	end,

	on_destruct = function(...)
		return nether.hidden_on_destruct(...)
	end,

	on_timer = function(...)
		return nether.hidden_on_timer(...)
	end,

	on_flood = function(...)
		return nether.liquid_on_flood(...)
	end,

	-- Prevent obtaining this node by getting it to fall.
	on_finish_collapse = function(pos, node) minetest.remove_node(pos) end,
	on_collapse_to_entity = function() end,
})
