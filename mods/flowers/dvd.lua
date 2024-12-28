-- Flowers by DragonsVolcanoDance.
--
-- Message to DVD: you gave me this code in an *.odt file.
-- This remark forever marks your utter noobishness. :p
-- Also, you forgot some } and ).

local function pixel_box(x1, y1, z1, x2, y2, z2)
	return {
		x1 / 16 - 0.5,
		y1 / 16 - 0.5,
		z1 / 16 - 0.5,
		x2 / 16 - 0.5,
		y2 / 16 - 0.5,
		z2 / 16 - 0.5,
	}
end

local function get_selection_box(x1, y1, z1, x2, y2, z2)
	return {
		type = "fixed",
		fixed = {
			pixel_box(x1, y1, z1, x2, y2, z2),
		},
	}
end

flowers.aradonia_flowers_list = {
	{node="aradonia:caveflower6"},
	{node="aradonia:caveflower8"},
	{node="aradonia:caveflower9"},
	{node="aradonia:caveflower10"},
	{node="aradonia:caveflower11"},
	{node="aradonia:caveflower12"},
	{node="aradonia:caveflower13"},
	{node="aradonia:caveflower14"},
	{node="aradonia:caveflower15"},
	{node="aradonia:caveflower16"},
	{node="aradonia:caveflower17"},
	{node="aradonia:caveflower18"},
}

-- Giant Luminous Flower
minetest.register_node(':aradonia:caveflower6', {
	description = 'Midnight Sun',
	drawtype = "plantlike",
	visual_scale =  2.0,
	walkable = false,
	tiles = {'dvd_luminousflower.png'},
	inventory_image = 'dvd_luminousflower.png',
	paramtype = "light",
	light_source = 6,
	selection_box = get_selection_box(0, 0, 0, 16, 32, 16),
	groups = utility.dig_groups("hardplant", {
		attached_node = 1, flammable = 3,
	}),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
})

-- Fairy Flower
minetest.register_node(':aradonia:caveflower8', {
	description = 'Fairy Flower',
	drawtype = "plantlike",
	visual_scale =  2.0,
	walkable = false,
	tiles = {'dvd_fairyflower2.png'},
	inventory_image = 'dvd_fairyflower2.png',
	paramtype = "light",
	light_source = 5,
	selection_box = get_selection_box(-2, 0, -2, 18, 28, 18),
	groups = utility.dig_groups("plant", {
		attached_node = 1, flammable = 3,
	}),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
	buildable_to = true,
})

--------------------------------------------------------------------------------
local function sunflower_choose(pos)
	local time = minetest.get_timeofday()
	local node = minetest.get_node(pos)

	if time < 0.2 or time > 0.8 then
		-- Night.
		if node.name ~= "aradonia:caveflower9" then
			node.name = "aradonia:caveflower9"
			minetest.swap_node(pos, node)
		end
	else
		-- Day.
		if node.name ~= "aradonia:caveflower10" then
			node.name = "aradonia:caveflower10"
			minetest.swap_node(pos, node)
		end
	end
end

local function sunflower_on_construct(pos)
	sunflower_choose(pos)
	minetest.get_node_timer(pos):start(math.random(50, 100) / 10)
end

local function sunflower_on_timer(pos, elapsed)
	sunflower_choose(pos)
	minetest.get_node_timer(pos):start(math.random(50, 100) / 10)
end

-- Weeping Sunset Flower
minetest.register_node(':aradonia:caveflower9', {
	description = 'Weeping Sunset',
	drawtype = "plantlike",
	visual_scale =  2.0,
	walkable = false,
	tiles = {'dvd_weepingsunset.png'},
	inventory_image = 'dvd_weepingsunset.png',
	paramtype = "light",
	light_source = 4,
	groups = utility.dig_groups("plant", {
		attached_node = 1, flammable = 3,
	}),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
	on_construct = sunflower_on_construct,
	on_timer = sunflower_on_timer,
	buildable_to = true,
})

-- Weeping Sunrise Flower
minetest.register_node(':aradonia:caveflower10', {
	description = 'Weeping Sunrise',
	drawtype = "plantlike",
	visual_scale =  2.0,
	walkable = false,
	tiles = {'dvd_weepingsunrise.png'},
	inventory_image = 'dvd_weepingsunrise.png',
	paramtype = "light",
	light_source = 4,
	groups = utility.dig_groups("plant", {
		attached_node = 1, flammable = 3,
	}),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
	on_construct = sunflower_on_construct,
	on_timer = sunflower_on_timer,
	buildable_to = true,
})
--------------------------------------------------------------------------------

local function fire_lantern_punch(pos)
	local p1 = vector.offset(pos, 0, 1, 0)
	if minetest.get_node(p1).name == "air" then
		minetest.set_node(p1, {name="fire:basic_flame"})
	end
end

local function fire_lantern_after_destruct(pos)
	minetest.set_node(pos, {name="fire:basic_flame"})
end

-- Fiery Lantern
minetest.register_node(':aradonia:caveflower11', {
	description = 'Fiery Lantern',
	drawtype = "plantlike",
	visual_scale =  2.0,
	walkable = false,
	tiles = {'dvd_fierylantern.png'},
	inventory_image = 'dvd_fierylantern.png',
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 2,
	light_source = 5,
	selection_box = get_selection_box(0, 0, 0, 16, 27, 16),
	groups = utility.dig_groups("hardplant", {
		attached_node = 1, flammable = 3,
	}),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
	on_punch = fire_lantern_punch,
	after_destruct = fire_lantern_after_destruct,
})
--------------------------------------------------------------------------------

-- Candle Flowers
minetest.register_node(':aradonia:caveflower12', {
	description = 'Candle Flowers',
	drawtype = "plantlike",
	visual_scale =  1.0,
	walkable = false,
	tiles = {'dvd_fireflowers.png'},
	inventory_image = 'dvd_fireflowers.png',
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 10,
	light_source = 5,
	selection_box = {
		type = "fixed",
		fixed = {
			pixel_box(0, 0, 0, 16, 7, 16),
	  },
	},
	groups = utility.dig_groups("plant", {
		attached_node = 1, flammable = 3,
	}),
	sounds = default.node_sound_leaves_defaults(),

	-- No slowdown for this.
	--movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

	buildable_to = true,
})

-- Fiery Thorns
minetest.register_node(':aradonia:caveflower13', {
	description = 'Fiery Thorns',
	drawtype = "plantlike",
	visual_scale =  1.0,
	walkable = false,
	tiles = {'dvd_fierythorns.png'},
	inventory_image = 'dvd_fierythorns.png',
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 3+32,
	light_source = 1,
	groups = utility.dig_groups("plant", {
		attached_node = 1, flammable = 3,
	}),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
	buildable_to = true,

	damage_per_second = 2*500,
  _damage_per_second_type = "snappy",
	_death_message = {
		"The firethorns got <player>.",
		"<player> was pierced by firethorns.",
	},
})

-- Star Moss
minetest.register_node(':aradonia:caveflower14', {
	description = 'Star Moss',
	drawtype = "plantlike",
	visual_scale =  1.0,
	walkable = false,
	tiles = {'dvd_glowflowers.png'},
	inventory_image = 'dvd_glowflowers.png',
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 10,
	light_source = 4,
	selection_box = {
		type = "fixed",
		fixed = {
			pixel_box(0, 0, 0, 16, 7, 16),
	  },
	},
	groups = utility.dig_groups("plant", {
		attached_node = 1, flammable = 3,
	}),
	sounds = default.node_sound_leaves_defaults(),

	-- No slowdown for this.
	--movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

	buildable_to = true,
})

-- Moon Flower
minetest.register_node(':aradonia:caveflower15', {
	description = 'Moon Flower',
	drawtype = "plantlike",
	visual_scale =  1.0,
	walkable = false,
	tiles = {'dvd_moonflower.png'},
	inventory_image = 'dvd_moonflower.png',
	paramtype = "light",
	paramtype2 = "meshoptions",
	light_source = 4,
	groups = utility.dig_groups("plant", {
		attached_node = 1, flammable = 3,
	}),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
	buildable_to = true,
})

-- Pink Moon Flower
minetest.register_node(':aradonia:caveflower16', {
	description = 'Pink Moon Flower',
	drawtype = "plantlike",
	visual_scale =  1.0,
	walkable = false,
	tiles = {'dvd_pinkmoonflower.png'},
	inventory_image = 'dvd_pinkmoonflower.png',
	paramtype = "light",
	paramtype2 = "meshoptions",
	light_source = 4,
	groups = utility.dig_groups("plant", {
		attached_node = 1, flammable = 3,
	}),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
	buildable_to = true,
})

-- Dustflower
minetest.register_node(':aradonia:caveflower17', {
	description = 'Dust Squab',
	drawtype = "plantlike",
	visual_scale =  1.0,
	walkable = false,
	tiles = {'dvd_dustflower.png'},
	inventory_image = 'dvd_dustflower.png',
	paramtype = "light",
	paramtype2 = "meshoptions",
	light_source = 4,
	groups = utility.dig_groups("hardplant", {
		attached_node = 1, flammable = 3,
	}),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
})

-- That other Dustflower
minetest.register_node(':aradonia:caveflower18', {
	description = 'Dust Flower',
	drawtype = "plantlike",
	visual_scale =  2.0,
	walkable = false,
	tiles = {'dvd_emergantdustflower.png'},
	inventory_image = 'dvd_emergantdustflower.png',
	paramtype = "light",
	paramtype2 = "meshoptions",
	light_source = 6,
	selection_box = {
		type = "fixed",
		fixed = {
			pixel_box(0, 0, 0, 16, 32, 16),
	  },
	},
	groups = utility.dig_groups("hardplant", {
		attached_node = 1, flammable = 3,
	}),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
})
