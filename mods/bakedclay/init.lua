
-- Baked Clay by TenPlus1
-- Modified for "Must Test" server by MustTest

-- Note: must match the colors defined by the 'dye' mod.
local clay = {
	{"white", "White"},
	{"grey", "Grey"},
	{"black", "Black"},
	{"red", "Red"},
	{"yellow", "Yellow"},
	{"green", "Green"},
	{"cyan", "Cyan"},
	{"blue", "Blue"},
	{"magenta", "Magenta"},
	{"orange", "Orange"},
	{"violet", "Violet"},
	{"brown", "Brown"},
	{"pink", "Pink"},
	{"dark_grey", "Dark Grey"},
	{"dark_green", "Dark Green"},
}

-- Register "natural" baked clay.
do
	local v = {"natural", "Natural"}

	minetest.register_node("bakedclay:" .. v[1], {
		description = v[2] .. " Baked Clay",
		tiles = {"baked_clay_" .. v[1] ..".png"},
		groups = utility.dig_groups("hardclay", {bakedclay = 1}),
		sounds = default.node_sound_stone_defaults(),
	})

	stairs.register_stair_and_slab(
		"bakedclay_".. v[1],
		"bakedclay:".. v[1],
		utility.dig_groups("hardclay"),
		{"baked_clay_" .. v[1] .. ".png"},
		v[2] .. " Baked Clay",
		default.node_sound_stone_defaults()
	)
end

for _, clay in ipairs(clay) do

	-- node definition

	minetest.register_node("bakedclay:" .. clay[1], {
		description = clay[2] .. " Baked Clay",
		tiles = {"baked_clay_" .. clay[1] ..".png"},
		groups = utility.dig_groups("hardclay", {bakedclay = 1}),
		sounds = default.node_sound_stone_defaults(),
	})

	-- craft from dye and natural baked clay

	minetest.register_craft({
		type = "shapeless",
		output = "bakedclay:" .. clay[1],
		recipe = {"bakedclay:natural", "dye:" .. clay[1]},
	})

	-- register stair and slab
	stairs.register_stair_and_slab(
		"bakedclay_".. clay[1],
		"bakedclay:".. clay[1],
		utility.dig_groups("hardclay"),
		{"baked_clay_" .. clay[1] .. ".png"},
		clay[2] .. " Baked Clay",
		default.node_sound_stone_defaults()
	)
end

-- Terracotta blocks (textures by D3monPixel, thanks for use :)
for k, v in ipairs(clay) do
	local texture = "baked_clay_terracotta_" .. v[1] ..".png"

	minetest.register_node("bakedclay:terracotta_" .. v[1], {
		description = v[2] .. " Glazed Terracotta",
		tiles = {
			texture .. "",
			texture .. "",
			texture .. "^[transformR180",
			texture .. "",
			texture .. "^[transformR270",
			texture .. "^[transformR90",
		},
		paramtype2 = "facedir",
		groups = utility.dig_groups("hardclay", {terracotta = 1}),
		sounds = default.node_sound_stone_defaults(),
		on_place = minetest.rotate_node,
	})

	minetest.register_craft({
		type = "cooking",
		output = "bakedclay:terracotta_" .. v[1],
		recipe = "bakedclay:" .. v[1],
		cooktime = 10,
	})

	stairs.register_stair_and_slab(
		"bakedclay_terracotta_".. v[1],
		"bakedclay:terracotta_".. v[1],
		utility.dig_groups("hardclay"),
		{"baked_clay_terracotta_" .. v[1] .. ".png"},
		v[2] .. " Baked Clay",
		default.node_sound_stone_defaults()
	)
end

-- Need to handle "light_blue" specifically because not present in clay list.
do
	local v = {"light_blue", "Light Blue"}
	local texture = "baked_clay_terracotta_" .. v[1] ..".png"

	minetest.register_node("bakedclay:terracotta_" .. v[1], {
		description = v[2] .. " Glazed Terracotta",
		tiles = {
			texture .. "",
			texture .. "",
			texture .. "^[transformR180",
			texture .. "",
			texture .. "^[transformR270",
			texture .. "^[transformR90",
		},
		paramtype2 = "facedir",
		groups = utility.dig_groups("hardclay", {terracotta = 1}),
		sounds = default.node_sound_stone_defaults(),
		on_place = minetest.rotate_node,
	})

	minetest.register_craft({
		type = "cooking",
		output = "bakedclay:terracotta_" .. v[1],
		recipe = "bakedclay:terracotta_cyan",
		cooktime = 10,
	})

	stairs.register_stair_and_slab(
		"bakedclay_terracotta_".. v[1],
		"bakedclay:terracotta_".. v[1],
		utility.dig_groups("hardclay"),
		{"baked_clay_terracotta_" .. v[1] .. ".png"},
		v[2] .. " Baked Clay",
		default.node_sound_stone_defaults()
	)
end

-- cook clay block into natural baked clay

minetest.register_craft({
	type = "cooking",
	output = "bakedclay:natural",
	recipe = "default:clay",
	cooktime = 10,
})

-- register a few extra dye colour options

minetest.register_craft( {
	type = "shapeless",
	output = "dye:dark_grey 3",
	recipe = {"dye:black", "dye:black", "dye:white"}
})

minetest.register_craft( {
	type = "shapeless",
	output = "dye:grey 3",
	recipe = {"dye:black", "dye:white", "dye:white"}
})

minetest.register_craft( {
	type = "extracting",
	output = "dye:brown 4",
	recipe = "default:dry_shrub"
})

minetest.register_craft( {
	type = "extracting",
	output = "dye:brown 4",
	recipe = "default:dry_shrub2"
})

-- 2x2 red bakedclay makes 16x clay brick
minetest.register_craft( {
	output = "default:clay_brick 16",
	recipe = {
		{"bakedclay:red", "bakedclay:red"},
		{"bakedclay:red", "bakedclay:red"},
	}
})

-- register some new flowers to fill in missing dye colours
-- flower registration (borrowed from default game)

local function add_simple_flower(name, desc, box, f_groups)

	f_groups.flower = 1
	f_groups.flora = 1
	f_groups.attached_node = 1
	f_groups.flammable = 3,

	minetest.register_node(":flowers:" .. name, {
		description = desc,
		drawtype = "plantlike",
		waving = 1,
		tiles = {"baked_clay_" .. name .. ".png"},
		inventory_image = "baked_clay_" .. name .. ".png",
		wield_image = "baked_clay_" .. name .. ".png",
		sunlight_propagates = true,
		paramtype = "light",
		walkable = false,
		buildable_to = true,
		groups = utility.dig_groups("plant", f_groups),
		sounds = default.node_sound_leaves_defaults(),
		selection_box = {
			type = "fixed",
			fixed = box
		},
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

		on_construct = function(...)
			return flowers.on_flora_construct(...)
		end,

		on_destruct = function(...)
			return flowers.on_flora_destruct(...)
		end,

		on_timer = function(...)
			return flowers.on_flora_timer(...)
		end,

		on_punch = function(...)
			return flowers.on_flora_punch(...)
		end,
	})
end

local flowers = {
	{"delphinium", "Blue Delphinium",
	{-5 / 16, -0.5, -5 / 16, 5 / 16, 5 / 16, 5 / 16},
	{color_cyan = 1}},

	{"thistle", "Thistle",
	{-0.15, -0.5, -0.15, 0.15, 0.2, 0.15},
	{color_magenta = 1}},

	{"lazarus", "Lazarus Bell",
	{-0.15, -0.5, -0.15, 0.15, 0.2, 0.15},
	{color_pink = 1}},

	{"mannagrass", "Reed Mannagrass",
	{-5 / 16, -0.5, -5 / 16, 5 / 16, 5 / 16, 5 / 16},
	{color_dark_green = 1}},

	{"lockspur", "Lockspur",
	{-0.15, -0.5, -0.15, 0.15, 0.3, 0.15},
	{color_cyan = 1}},
}

for _,item in pairs(flowers) do
	add_simple_flower(unpack(item))
end

minetest.register_craft({
  type = "extracting",
  output = 'dye:cyan 5',
  recipe = 'flowers:delphinium',
  time = 3,
})

minetest.register_craft({
  type = "extracting",
  output = 'dye:cyan 5',
  recipe = 'flowers:lockspur',
  time = 3,
})

minetest.register_craft({
  type = "extracting",
  output = 'dye:magenta 5',
  recipe = 'flowers:thistle',
  time = 3,
})

minetest.register_craft({
  type = "extracting",
  output = 'dye:pink 5',
  recipe = 'flowers:lazarus',
  time = 3,
})

minetest.register_craft({
  type = "extracting",
  output = 'dye:dark_green 5',
  recipe = 'flowers:mannagrass',
  time = 3,
})

minetest.register_craft({
	type = "shapeless",
	output = "default:clay_lump",
	recipe = {"darkage:silt_lump", "darkage:mud_lump"},
})
