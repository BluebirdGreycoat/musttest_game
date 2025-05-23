
if not minetest.global_exists("cavestuff") then cavestuff = {} end
cavestuff.modpath = minetest.get_modpath("cavestuff")

-- Localize for performance.
local math_random = math.random

-- Functions.
dofile(cavestuff.modpath .. "/functions.lua")



minetest.register_node("cavestuff:cobble_with_moss", {
  description = "Cave Stone With Moss",
  tiles = {
		"default_cobble.png^caverealms_moss.png",
		"default_cobble.png",
		"default_cobble.png^caverealms_moss_side.png",
	},
  groups = utility.dig_groups("softcobble", {
		falling_node = 1,
		melts = 1,
		cavern_soil = 1, cobble_type = 1,
	}),
	_melts_to = "cavestuff:cobble_with_rockmelt",
  sounds = default.node_sound_gravel_defaults({
    footstep = {name="default_grass_footstep", gain=0.25},
  }),
  light_source = 1,
	movement_speed_multiplier = default.SLOW_SPEED_GRASS,

	drop = "default:cobble",
	silverpick_drop = true,
	_is_bulk_mapgen_stone = true,

	-- Common stone does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},

	on_finish_collapse = function(pos)
		minetest.swap_node(pos, {name="default:cobble"})
	end,

	on_collapse_to_entity = function(pos)
		return {ItemStack("default:cobble")}
	end,
})

minetest.register_node("cavestuff:cobble_with_lichen", {
  description = "Cave Stone With Lichen",
  tiles = {
		"default_cobble.png^caverealms_lichen.png",
		"default_cobble.png",
		"default_cobble.png^caverealms_lichen_side.png",
	},
  groups = utility.dig_groups("softcobble", {
		falling_node = 1,
		melts = 1,
		cavern_soil = 1, cobble_type = 1,
	}),
	_melts_to = "cavestuff:cobble_with_rockmelt",
  sounds = default.node_sound_gravel_defaults({
    footstep = {name="default_grass_footstep", gain=0.25},
  }),
  light_source = 1,
	movement_speed_multiplier = default.SLOW_SPEED_GRASS,

	drop = "default:cobble",
	silverpick_drop = true,
	_is_bulk_mapgen_stone = true,

	-- Common stone does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},

	on_finish_collapse = function(pos)
		minetest.swap_node(pos, {name="default:cobble"})
	end,

	on_collapse_to_entity = function(pos)
		return {ItemStack("default:cobble")}
	end,
})

minetest.register_node("cavestuff:cobble_with_algae", {
  description = "Cave Stone With Algae",
  tiles = {
		"default_cobble.png^caverealms_algae.png",
		"default_cobble.png",
		"default_cobble.png^caverealms_algae_side.png",
	},
  groups = utility.dig_groups("softcobble", {
		falling_node = 1,
		melts = 1,
		cavern_soil = 1, cobble_type = 1,
	}),
	_melts_to = "cavestuff:cobble_with_rockmelt",
  sounds = default.node_sound_gravel_defaults({
    footstep = {name="default_grass_footstep", gain=0.25},
  }),
  light_source = 1,
	movement_speed_multiplier = default.SLOW_SPEED_GRASS,

	drop = "default:cobble",
	silverpick_drop = true,
	_is_bulk_mapgen_stone = true,

	-- Common stone does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},

	on_finish_collapse = function(pos)
		minetest.swap_node(pos, {name="default:cobble"})
	end,

	on_collapse_to_entity = function(pos)
		return {ItemStack("default:cobble")}
	end,
})

minetest.register_node("cavestuff:cobble_with_salt", {
  description = "Cave Stone With Salt",
  tiles = {
		"default_cobble.png^caverealms_salty.png",
		"default_cobble.png",
		"default_cobble.png^caverealms_salty_side.png",
	},
  groups = utility.dig_groups("softcobble", {
		falling_node = 1,
		melts = 1, cobble_type = 1,
	}),
	_melts_to = "cavestuff:cobble_with_rockmelt",
  sounds = default.node_sound_gravel_defaults(),
  light_source = 1,
	movement_speed_multiplier = default.SLOW_SPEED_GRASS,

	drop = "default:cobble",
	silverpick_drop = true,
	_is_bulk_mapgen_stone = true,

	-- Common stone does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},

	on_finish_collapse = function(pos)
		minetest.swap_node(pos, {name="default:cobble"})
	end,

	on_collapse_to_entity = function(pos)
		return {ItemStack("default:cobble")}
	end,
})

minetest.register_node("cavestuff:cobble_with_rockmelt", {
  description = "Rockmelt Cobble",
  tiles = {"caverealms_hot_cobble.png"},
  groups = utility.dig_groups("softcobble", {hot=1, falling_node=1, melt_around=3, cobble_type=1, rockmelt=1}),
  damage_per_second = 1*500,
  _damage_per_second_type = "heat",
	_death_message = "<player> succumbed to melted rock.",
  light_source = 5,
  sounds = default.node_sound_stone_defaults(),
	drop = "default:cobble",
	_is_bulk_mapgen_stone = true,
	movement_speed_multiplier = default.SLOW_SPEED,

	on_construct = function(pos)
		torchmelt.start_melting(pos)
	end,

	after_place_node = function(...)
		return cavestuff.hotcobble.after_place_node(...)
	end,

	after_dig_node = function(...)
		return cavestuff.hotcobble.after_dig_node(...)
	end,

	on_player_walk_over = function(...)
		return cavestuff.hotcobble.on_player_walk_over(...)
	end,

	on_finish_collapse = function(...)
		return cavestuff.hotcobble.on_finish_collapse(...)
	end,

	-- Common stone does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},
})

minetest.register_node("cavestuff:glow_sapphire", {
  description = "Glowing Sapphire",
  tiles = {"caverealms_glow_crystal.png"},
  groups = utility.dig_groups("crystal"),
  sounds = default.node_sound_glass_defaults(),
  light_source = 13,
  paramtype = "light",
  use_texture_alpha = "blend",
  drawtype = "glasslike",
  sunlight_propagates = true,
})

stairs.register_stair_and_slab(
	"glow_sapphire",
	"cavestuff:glow_sapphire",
	utility.dig_groups("crystal"),
	{"caverealms_glow_crystal.png"},
	"Glowing Sapphire",
	default.node_sound_glass_defaults()
)
minetest.override_item("stairs:slab_glow_sapphire", {
	sunlight_propagates = true,
	light_source = 13,
})
minetest.override_item("stairs:stair_glow_sapphire", {
	sunlight_propagates = true,
	light_source = 13,
})

minetest.register_node("cavestuff:glow_emerald", {
  description = "Glowing Emerald",
  tiles = {"caverealms_glow_emerald.png"},
  groups = utility.dig_groups("crystal"),
  sounds = default.node_sound_glass_defaults(),
  light_source = 10,
  paramtype = "light",
  use_texture_alpha = "blend",
  drawtype = "glasslike",
  sunlight_propagates = true,
})

stairs.register_stair_and_slab(
	"glow_emerald",
	"cavestuff:glow_emerald",
	utility.dig_groups("crystal"),
	{"caverealms_glow_emerald.png"},
	"Glowing Emerald",
	default.node_sound_glass_defaults()
)
minetest.override_item("stairs:slab_glow_emerald", {
	sunlight_propagates = true,
	light_source = 10,
})
minetest.override_item("stairs:stair_glow_emerald", {
	sunlight_propagates = true,
	light_source = 10,
})



minetest.register_node("cavestuff:glow_white_crystal", {
  description = "White Crystal",
	tiles = {{
		name = "caverealms_glow_white_animated.png",
		animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 4.0},
	}},
  groups = utility.dig_groups("obsidian", {
		-- Can't be immovable, this interferes with dig-fragility!
    --immovable = 1,
  }),
  sounds = default.node_sound_glass_defaults(),
  light_source = minetest.LIGHT_MAX,
  paramtype = "light",
  use_texture_alpha = "blend",
  drawtype = "glasslike",
  sunlight_propagates = true,
  silverpick_drop = true,
	drop = {
		max_items = 1,
		items = {
			{items = {'default:mese_crystal'}, rarity = 24},
			{items = {'vessels:glass_fragments'}, rarity = 5},
			{items = {'default:glass'}}
		}
	},

	on_construct = function(...)
		return cavestuff.white_crystal.on_construct(...)
	end,

	after_dig_node = function(...)
		return cavestuff.white_crystal.after_dig_node(...)
	end,

	on_timer = function(...)
		return cavestuff.white_crystal.on_timer(...)
	end,
})

-- This formatting is so bad whoever sees it will spontaneously combust.
stairs.register_stair_and_slab(
	"glow_white_crystal",
	 "cavestuff:glow_white_crystal",
	  utility.dig_groups("crystal"),
	   {"caverealms_glow_white.png"},
	    "White Crystal",
	     default.node_sound_glass_defaults(),
	      {no_slopes=true, exclude_pillars=true}
)



minetest.register_node("cavestuff:glow_mese", {
  description = "Glowing Mese",
  tiles = {"caverealms_glow_mese.png"},
  groups = utility.dig_groups("crystal"),
  sounds = default.node_sound_glass_defaults(),
  light_source = 14,
  paramtype = "light",
  use_texture_alpha = "blend",
  drawtype = "glasslike",
  sunlight_propagates = true,
})

stairs.register_stair_and_slab(
	"glow_mese",
	"cavestuff:glow_mese",
	utility.dig_groups("crystal"),
	{"caverealms_glow_mese.png"},
	"Glowing Mese",
	default.node_sound_glass_defaults()
)
minetest.override_item("stairs:slab_glow_mese", {
	sunlight_propagates = true,
	light_source = 14,
})
minetest.override_item("stairs:stair_glow_mese", {
	sunlight_propagates = true,
	light_source = 14,
})

minetest.register_node("cavestuff:glow_ruby", {
  description = "Glowing Ruby",
  tiles = {"caverealms_glow_ruby.png"},
  groups = utility.dig_groups("crystal"),
  sounds = default.node_sound_glass_defaults(),
  light_source = 8,
  paramtype = "light",
  use_texture_alpha = "blend",
  drawtype = "glasslike",
  sunlight_propagates = true,
})

stairs.register_stair_and_slab(
	"glow_ruby",
	"cavestuff:glow_ruby",
	utility.dig_groups("crystal"),
	{"caverealms_glow_ruby.png"},
	"Glowing Ruby",
	default.node_sound_glass_defaults()
)
minetest.override_item("stairs:slab_glow_ruby", {
	sunlight_propagates = true,
	light_source = 8,
})
minetest.override_item("stairs:stair_glow_ruby", {
	sunlight_propagates = true,
	light_source = 8,
})

minetest.register_node("cavestuff:glow_amethyst", {
  description = "Glowing Amethyst",
  tiles = {"caverealms_glow_amethyst.png"},
  groups = utility.dig_groups("crystal"),
  sounds = default.node_sound_glass_defaults(),
  light_source = 7,
  paramtype = "light",
  use_texture_alpha = "blend",
  drawtype = "glasslike",
  sunlight_propagates = true,
})

stairs.register_stair_and_slab(
	"glow_amethyst",
	"cavestuff:glow_amethyst",
	utility.dig_groups("crystal"),
	{"caverealms_glow_amethyst.png"},
	"Glowing Amethyst",
	default.node_sound_glass_defaults()
)
minetest.override_item("stairs:slab_glow_amethyst", {
	sunlight_propagates = true,
	light_source = 7,
})
minetest.override_item("stairs:stair_glow_amethyst", {
	sunlight_propagates = true,
	light_source = 7,
})

minetest.register_node("cavestuff:glow_sapphire_ore", {
  description = "Embedded Glowing Sapphire",
  tiles = {"caverealms_glow_ore.png"},
  groups = utility.dig_groups("hardore"),
  sounds = default.node_sound_stone_defaults(),
  light_source = 8,
  paramtype = "light",
})

stairs.register_stair_and_slab(
	"glow_sapphire_ore",
	"cavestuff:glow_sapphire_ore",
	utility.dig_groups("hardore"),
	{"caverealms_glow_ore.png"},
	"Embedded Glowing Sapphire",
	default.node_sound_stone_defaults()
)
minetest.override_item("stairs:slab_glow_sapphire_ore", {
	light_source = 8,
})
minetest.override_item("stairs:stair_glow_sapphire_ore", {
	light_source = 8,
})

minetest.register_node("cavestuff:glow_emerald_ore", {
  description = "Embedded Glowing Emerald",
  tiles = {"caverealms_glow_emerald_ore.png"},
  groups = utility.dig_groups("hardore"),
  sounds = default.node_sound_stone_defaults(),
  light_source = 8,
  paramtype = "light",
})

stairs.register_stair_and_slab(
	"glow_emerald_ore",
	"cavestuff:glow_emerald_ore",
	utility.dig_groups("hardore"),
	{"caverealms_glow_emerald_ore.png"},
	"Embedded Glowing Emerald",
	default.node_sound_stone_defaults()
)
minetest.override_item("stairs:slab_glow_emerald_ore", {
	light_source = 8,
})
minetest.override_item("stairs:stair_glow_emerald_ore", {
	light_source = 8,
})

minetest.register_node("cavestuff:glow_ruby_ore", {
  description = "Embedded Glowing Ruby",
  tiles = {"caverealms_glow_ruby_ore.png"},
  groups = utility.dig_groups("hardore"),
  sounds = default.node_sound_stone_defaults(),
  light_source = 8,
  paramtype = "light",
})

stairs.register_stair_and_slab(
	"glow_ruby_ore",
	"cavestuff:glow_ruby_ore",
	utility.dig_groups("hardore"),
	{"caverealms_glow_ruby_ore.png"},
	"Embedded Glowing Ruby",
	default.node_sound_stone_defaults()
)
minetest.override_item("stairs:slab_glow_ruby_ore", {
	light_source = 8,
})
minetest.override_item("stairs:stair_glow_ruby_ore", {
	light_source = 8,
})

minetest.register_node("cavestuff:glow_amethyst_ore", {
  description = "Embedded Glowing Amethyst",
  tiles = {"caverealms_glow_amethyst_ore.png"},
  groups = utility.dig_groups("hardore"),
  sounds = default.node_sound_stone_defaults(),
  light_source = 8,
  paramtype = "light",
})

stairs.register_stair_and_slab(
	"glow_amethyst_ore",
	"cavestuff:glow_amethyst_ore",
	utility.dig_groups("hardore"),
	{"caverealms_glow_amethyst_ore.png"},
	"Embedded Glowing Amethyst",
	default.node_sound_stone_defaults()
)
minetest.override_item("stairs:slab_glow_amethyst_ore", {
	light_source = 8,
})
minetest.override_item("stairs:stair_glow_amethyst_ore", {
	light_source = 8,
})

minetest.register_node("cavestuff:glow_worm", {
  description = "Glow Worms",
  tiles = {"caverealms_glow_worm.png"},
  inventory_image = "caverealms_glow_worm.png",
  wield_image = "caverealms_glow_worm.png",
  groups = utility.dig_groups("plant", {
		hanging_node = 1, flammable = 3,
	}),
  light_source = 5,
  paramtype = "light",
  drawtype = "plantlike",
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
  walkable = false,
  climbable = true,

	drop = "",
	shears_drop = true,

  -- Selection box interferes with hanging node group?
  -- Making the selection box smaller seems to prevent the
  -- hanging node group from working properly.
  selection_box = {
    type = "fixed",
    fixed = {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3},
  },
})

minetest.register_node("cavestuff:glow_fungus", {
  description = "Glow Fungus",
  tiles = {"caverealms_glow_fungus.png"},
  inventory_image = "caverealms_glow_fungus.png",
  wield_image = "caverealms_glow_fungus.png",
  groups = utility.dig_groups("plant", {
		attached_node = 1, flammable = 3,
	}),
  light_source = 5,
  paramtype = "light",
  drawtype = "firelike",

  -- No slowdown for this.
	--movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

  walkable = false,
  buildable_to = true,

	drop = "",
	shears_drop = true,

  -- Selection box interferes with hanging node group?
  -- Making the selection box smaller seems to prevent the
  -- hanging node group from working properly.
  selection_box = {
    type = "fixed",
    fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
  },
})

minetest.register_node("cavestuff:glow_obsidian", {
  description = "Luminescent Obsidian",
  tiles = {"caverealms_glow_obsidian.png"},
  groups = utility.dig_groups("obsidian", {
    immovable = 1,
  }),
  light_source = 7,
  sounds = default.node_sound_stone_defaults(),

  -- Blast resistant.
  -- But note, this spawns as an ore in Xen (and maybe some other places),
  -- so it looks weird when they stay hanging in the air after a TNT blast.
  on_blast = utility.make_knockdown_on_blast({
		name = "cavestuff:glow_obsidian",
		count = 4, -- Min number of air needed to cause collapse.
		force_drop = true, -- Needed because otherwise obsidian is immovable.
	}),

	node_dig_prediction = "",

	after_destruct = function(pos)
		minetest.after(0, ambiance.recheck_nearby_sound_beacons, {x=pos.x, y=pos.y, z=pos.z}, 16)
	end,

	on_destruct = function(pos)
		obsidian_gateway.on_damage_gate(pos)
	end,

	_arrows_stick = false,
})

minetest.register_craft({
	output = "cavestuff:glow_obsidian",
	type = "shapeless",
	recipe = {"default:obsidian", "glowstone:glowing_dust"},
})

stairs.register_stair_and_slab("glow_obsidian", "cavestuff:glow_obsidian",
		utility.dig_groups("obsidian"),
		{"caverealms_glow_obsidian.png"},
		"Luminescent Obsidian",
		default.node_sound_stone_defaults())

minetest.register_node("cavestuff:glow_obsidian_brick", {
  description = "Luminescent Obsidian Brick",
  tiles = {"caverealms_glow_obsidian_brick.png"},
  groups = utility.dig_groups("brick", {
    immovable = 1,
  }),
  light_source = 7,
  sounds = default.node_sound_stone_defaults(),
	node_dig_prediction = "",
})

minetest.register_craft({
	output = "cavestuff:glow_obsidian_brick 4",
	recipe = {
		{"cavestuff:glow_obsidian", "cavestuff:glow_obsidian"},
		{"cavestuff:glow_obsidian", "cavestuff:glow_obsidian"},
	},
})

stairs.register_stair_and_slab(
	"glow_obsidian_brick",
	"cavestuff:glow_obsidian_brick",
	utility.dig_groups("brick"),
	{"caverealms_glow_obsidian_brick.png"},
	"Luminescent Obsidian Brick",
	default.node_sound_stone_defaults())

minetest.register_node("cavestuff:glow_obsidian_block", {
  description = "Luminescent Obsidian Block",
  tiles = {"caverealms_glow_obsidian_block.png"},
  groups = utility.dig_groups("block", {
    immovable = 1,
  }),
  light_source = 7,
  sounds = default.node_sound_stone_defaults(),
	node_dig_prediction = "",
})

minetest.register_craft({
	output = "cavestuff:glow_obsidian_block 9",
	recipe = {
		{"cavestuff:glow_obsidian", "cavestuff:glow_obsidian", "cavestuff:glow_obsidian"},
		{"cavestuff:glow_obsidian", "cavestuff:glow_obsidian", "cavestuff:glow_obsidian"},
		{"cavestuff:glow_obsidian", "cavestuff:glow_obsidian", "cavestuff:glow_obsidian"},
	},
})

stairs.register_stair_and_slab(
	"glow_obsidian_block",
	"cavestuff:glow_obsidian_block",
	utility.dig_groups("block"),
	{"caverealms_glow_obsidian_block.png"},
	"Luminescent Obsidian Block",
	default.node_sound_stone_defaults())

minetest.register_node("cavestuff:dark_obsidian", {
  description = "Dead Obsidian",
  tiles = {"technic_obsidian.png"},
  groups = utility.dig_groups("obsidian", {
    immovable = 1,
  }),
  sounds = default.node_sound_stone_defaults(),
	movement_speed_multiplier = default.ROAD_SPEED_CAVERN,
	node_dig_prediction = "",

	-- Note: adamant TNT mining depends on this.
  on_blast = utility.make_knockdown_on_blast({
		name = "cavestuff:dark_obsidian",
		count = 4, -- Min number of air needed to cause collapse.
		force_drop = true, -- Needed because otherwise obsidian is immovable.
	}),

	after_destruct = function(pos)
		minetest.after(0, ambiance.recheck_nearby_sound_beacons, {x=pos.x, y=pos.y, z=pos.z}, 16)
	end,

	on_destruct = function(pos)
		obsidian_gateway.on_damage_gate(pos)
	end,
	crushing_damage = 5000,
	_arrows_stick = false,
})

stairs.register_stair_and_slab(
	"dark_obsidian",
	"cavestuff:dark_obsidian",
	utility.dig_groups("obsidian"),
	{"technic_obsidian.png"},
	"Dead Obsidian",
	default.node_sound_stone_defaults())

minetest.register_node("cavestuff:dark_obsidian_brick", {
  description = "Dead Obsidian Brick",
  tiles = {"technic_obsidian_brick.png"},
  groups = utility.dig_groups("obsidian"),
  sounds = default.node_sound_stone_defaults(),
  on_blast = function(...) end, -- Blast resistant.
	crushing_damage = 5000,
	node_dig_prediction = "",
})

stairs.register_stair_and_slab(
	"dark_obsidian_brick",
	"cavestuff:dark_obsidian_brick",
	utility.dig_groups("obsidian"),
	{"technic_obsidian_brick.png"},
	"Dead Obsidian Brick",
	default.node_sound_stone_defaults())

minetest.register_node("cavestuff:dark_obsidian_block", {
  description = "Dead Obsidian Block",
  tiles = {"technic_obsidian_block.png"},
  groups = utility.dig_groups("obsidian"),
  sounds = default.node_sound_stone_defaults(),
  on_blast = function(...) end, -- Blast resistant.
	crushing_damage = 5000,
	node_dig_prediction = "",
})

stairs.register_stair_and_slab(
	"dark_obsidian_block",
	"cavestuff:dark_obsidian_block",
	utility.dig_groups("obsidian"),
	{"technic_obsidian_block.png"},
	"Dead Obsidian Block",
	default.node_sound_stone_defaults())

minetest.register_craft({
  output = "cavestuff:dark_obsidian_brick 4",
  recipe = {
    {"cavestuff:dark_obsidian", "cavestuff:dark_obsidian"},
    {"cavestuff:dark_obsidian", "cavestuff:dark_obsidian"},
  }
})

minetest.register_craft({
  output = "cavestuff:dark_obsidian_block 9",
  recipe = {
    {"cavestuff:dark_obsidian", "cavestuff:dark_obsidian", "cavestuff:dark_obsidian"},
    {"cavestuff:dark_obsidian", "cavestuff:dark_obsidian", "cavestuff:dark_obsidian"},
    {"cavestuff:dark_obsidian", "cavestuff:dark_obsidian", "cavestuff:dark_obsidian"},
  }
})

minetest.register_node("cavestuff:coal_dust", {
  description = "Black Sand",
  tiles = {"caverealms_coal_dust.png"},
  groups = utility.dig_groups("sand", {falling_node = 1}),
  sounds = default.node_sound_gravel_defaults(),
  --drop = "dusts:coal 9",
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_craft({
	output = "cavestuff:coal_dust",
	recipe = {
		{"dusts:coal", "dusts:coal", "dusts:coal"},
		{"dusts:coal", "default:sand", "dusts:coal"},
		{"dusts:coal", "dusts:coal", "dusts:coal"},
	},
})

minetest.register_node("cavestuff:salt_crystal", {
  description = "Salt Crystal",
  tiles = {"caverealms_salt_crystal.png"},
  groups = utility.dig_groups("crystal"),
  sounds = default.node_sound_gravel_defaults(),
  light_source = 1,
  paramtype = "light",
  use_texture_alpha = "blend",
  drawtype = "glasslike",
  sunlight_propagates = true,
})

local eat_mushroom = minetest.item_eat(1)
local function mushroom_poison(pname, step)
	local msg = "# Server: <" .. rename.gpn(pname) .. "> ate a mushroom. Desperate!"
	hb4.delayed_harm({name=pname, step=step, min=1*500, max=3*500, msg=msg, poison=true})
end

minetest.register_node("cavestuff:mycena", {
  description = "Mycena Mushroom",
  tiles = {"caverealms_mycena.png"},
  inventory_image = "caverealms_mycena.png",
  wield_image = "caverealms_mycena.png",
  groups = utility.dig_groups("plant", {attached_node = 1, flammable = 3}),
  light_source = 3,
  paramtype = "light",
  drawtype = "plantlike",
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
  walkable = false,
  buildable_to = true,
  visual_scale = 0.6,
  selection_box = {
    type = "fixed",
    fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
  },
  sounds = default.node_sound_leaves_defaults(),

	drop = "",
	shears_drop = true,
	flowerpot_drop = "cavestuff:mycena",
	_xdecor_soup_ingredient = true,

	on_use = function(itemstack, user, pointed_thing)
		if not user or not user:is_player() then return end
    minetest.after(1, mushroom_poison, user:get_player_name(), 3)
    return eat_mushroom(itemstack, user, pointed_thing)
  end,

	on_construct = function(...)
		return flowers.on_mushroom_construct(...)
	end,

	on_destruct = function(...)
		return flowers.on_mushroom_destruct(...)
	end,

	on_timer = function(...)
		return flowers.on_mushroom_timer(...)
	end,

	on_punch = function(...)
		return flowers.on_mushroom_punch(...)
	end,
})

minetest.register_node("cavestuff:fungus", {
  description = "Glowing Fungus",
  tiles = {"caverealms_fungi.png"},
  inventory_image = "caverealms_fungi.png",
  wield_image = "caverealms_fungi.png",
  groups = utility.dig_groups("plant", {attached_node = 1, flammable = 3}),
  light_source = 3,
  paramtype = "light",
  drawtype = "firelike",
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
  walkable = false,
  buildable_to = true,

  selection_box = {
    type = "fixed",
    fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
  },
  sounds = default.node_sound_leaves_defaults(),

	drop = "",
	shears_drop = true,
	flowerpot_drop = "cavestuff:fungus",

	on_use = function(itemstack, user, pointed_thing)
		if not user or not user:is_player() then return end
		-- Fewer steps than the mycena, to simulate being less poisonous.
    minetest.after(1, mushroom_poison, user:get_player_name(), 2)
    return eat_mushroom(itemstack, user, pointed_thing)
  end,

	on_construct = function(...)
		return flowers.on_mushroom_construct(...)
	end,

	on_destruct = function(...)
		return flowers.on_mushroom_destruct(...)
	end,

	on_timer = function(...)
		return flowers.on_mushroom_timer(...)
	end,

	on_punch = function(...)
		return flowers.on_mushroom_punch(...)
	end,
})

minetest.register_node("cavestuff:icicle_up", {
  description = "Icicle",
  tiles = {"caverealms_icicle_up.png"},
  inventory_image = "caverealms_icicle_up.png",
  wield_image = "caverealms_icicle_up.png",
  groups = utility.dig_groups("bigitem", {
		attached_node = 1,
		melts = 1,
	}),
  sounds = default.node_sound_glass_defaults(),
  paramtype = "light",
  drawtype = "plantlike",
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
  walkable = false,

  selection_box = {
    type = "fixed",
    fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
  },
  collision_box = {
    type = "fixed",
    fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
  },
})

minetest.register_node("cavestuff:icicle_up_glowing", {
  description = "Icicle With Glowing Minerals",
  tiles = {"caverealms_icicle_up.png"},
  inventory_image = "caverealms_icicle_up.png",
  wield_image = "caverealms_icicle_up.png",
  groups = utility.dig_groups("bigitem", {
		attached_node = 1,
		melts = 1,
	}),
  sounds = default.node_sound_glass_defaults(),
  paramtype = "light",
  drawtype = "plantlike",
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
  walkable = false,
  light_source = 7,

  selection_box = {
    type = "fixed",
    fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
  },
  collision_box = {
    type = "fixed",
    fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
  },
})

minetest.register_node("cavestuff:icicle_down", {
  description = "Icicle",
  tiles = {"caverealms_icicle_down.png"},
  inventory_image = "caverealms_icicle_down.png",
  wield_image = "caverealms_icicle_down.png",
  groups = utility.dig_groups("bigitem", {
		hanging_node = 1,
		melts = 1,
	}),
  sounds = default.node_sound_glass_defaults(),
  paramtype = "light",
  drawtype = "plantlike",
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
  walkable = false,

  selection_box = {
    type = "fixed",
    fixed = {-0.5, 5/16, -0.5, 0.5, 0.5, 0.5},
  },
  collision_box = {
    type = "fixed",
    fixed = {-0.5, 5/16, -0.5, 0.5, 0.5, 0.5},
  },
})

minetest.register_node("cavestuff:icicle_down_glowing", {
  description = "Icicle With Glowing Minerals",
  tiles = {"caverealms_icicle_down.png"},
  inventory_image = "caverealms_icicle_down.png",
  wield_image = "caverealms_icicle_down.png",
  groups = utility.dig_groups("bigitem", {
		hanging_node = 1,
		melts = 1,
	}),
  sounds = default.node_sound_glass_defaults(),
  paramtype = "light",
  drawtype = "plantlike",
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
  walkable = false,
  light_source = 7,

  selection_box = {
    type = "fixed",
    fixed = {-0.5, 5/16, -0.5, 0.5, 0.5, 0.5},
  },
  collision_box = {
    type = "fixed",
    fixed = {-0.5, 5/16, -0.5, 0.5, 0.5, 0.5},
  },
})



for i=1, 4, 1 do
  minetest.register_node("cavestuff:bluecrystal" .. i, {
    description = "Moon Gem",
    mesh = "mese_crystal_ore" .. i .. ".obj",
    tiles = {"caverealms_glow_crystal.png"},
    paramtype = "light",
		paramtype2 = "facedir",
    drawtype = "mesh",
    groups = utility.dig_groups("crystal", {
			attached_node = 1, fall_damage_add_percent = 100,
		}),
    use_texture_alpha = "blend",
    sounds = default.node_sound_glass_defaults(),
    light_source = 5,
    selection_box = {
      type = "fixed",
      fixed = {-0.3, -0.5, -0.3, 0.3, 0.35, 0.3}
    },
    visual_scale = 1.3,
		on_rotate = function(...)
			return screwdriver.rotate_simple(...)
		end,
		on_construct = function(pos)
			local node = minetest.get_node(pos)
			node.param2 = math_random(0, 3)
			minetest.swap_node(pos, node)
		end,
		on_player_walk_over = function(pos, player)
			utility.damage_player(player, "fleshy", (1*500), "ground")

			if player:get_hp() == 0 then
				minetest.chat_send_all("# Server: <" .. rename.gpn(player:get_player_name()) .. "> stepped on a moon spike.")
			end
		end,
  })
end

for i=1, 4, 1 do
  minetest.register_node("cavestuff:saltcrystal" .. i, {
    description = "Salt Crystal",
    mesh = "mese_crystal_ore" .. i .. ".obj",
    tiles = {"caverealms_salty.png"},
    paramtype = "light",
		paramtype2 = "facedir",
    drawtype = "mesh",
    groups = utility.dig_groups("crystal", {
			attached_node = 1,
			fall_damage_add_percent = 100,
		}),
    use_texture_alpha = "blend",
    sounds = default.node_sound_glass_defaults(),
    light_source = 5,
    selection_box = {
      type = "fixed",
      fixed = {-0.3, -0.5, -0.3, 0.3, 0.35, 0.3}
    },
		on_rotate = function(...)
			return screwdriver.rotate_simple(...)
		end,
		on_construct = function(pos)
			local node = minetest.get_node(pos)
			node.param2 = math_random(0, 3)
			minetest.swap_node(pos, node)
		end,
		on_player_walk_over = function(pos, player)
			utility.damage_player(player, "fleshy", 1*500, "ground")

			if player:get_hp() == 0 then
				minetest.chat_send_all("# Server: <" .. rename.gpn(player:get_player_name()) .. "> stepped on a salt spike.")
			end
		end,
  })
end

for i=1, 4, 1 do
  minetest.register_node("cavestuff:spike" .. i, {
    description = "Rock Spike",
    mesh = "mese_crystal_ore" .. i .. ".obj",
    tiles = {"default_stone.png"},
    drawtype = "mesh",
    paramtype = "light",
		paramtype2 = "facedir",
    groups = utility.dig_groups("crystal", {
			attached_node = 1, fall_damage_add_percent = 100,
		}),
    sounds = default.node_sound_stone_defaults(),
    selection_box = {
      type = "fixed",
      fixed = {-0.3, -0.5, -0.3, 0.3, 0.35, 0.3}
    },
		on_rotate = function(...)
			return screwdriver.rotate_simple(...)
		end,
		on_construct = function(pos)
			local node = minetest.get_node(pos)
			node.param2 = math_random(0, 3)
			minetest.swap_node(pos, node)
		end,
		on_player_walk_over = function(pos, player)
			utility.damage_player(player, "fleshy", 1*500, "ground")

			if player:get_hp() == 0 then
				minetest.chat_send_all("# Server: <" .. rename.gpn(player:get_player_name()) .. "> stepped on a rock spike.")
			end
		end,
  })
end

for i=1, 4, 1 do
  minetest.register_node("cavestuff:redspike" .. i, {
    description = "Redstone Spike",
    mesh = "mese_crystal_ore" .. i .. ".obj",
    tiles = {"default_desert_stone.png"},
    drawtype = "mesh",
    paramtype = "light",
		paramtype2 = "facedir",
    groups = utility.dig_groups("crystal", {
			attached_node = 1, fall_damage_add_percent = 100,
		}),
    sounds = default.node_sound_stone_defaults(),
    selection_box = {
      type = "fixed",
      fixed = {-0.3, -0.5, -0.3, 0.3, 0.35, 0.3}
    },
		on_rotate = function(...)
			return screwdriver.rotate_simple(...)
		end,
		on_construct = function(pos)
			local node = minetest.get_node(pos)
			node.param2 = math_random(0, 3)
			minetest.swap_node(pos, node)
		end,
		on_player_walk_over = function(pos, player)
			utility.damage_player(player, "fleshy", 1*500, "ground")

			if player:get_hp() == 0 then
				minetest.chat_send_all("# Server: <" .. rename.gpn(player:get_player_name()) .. "> stepped on a rock spike.")
			end
		end,
  })
end

for i=1, 4, 1 do
  minetest.register_node("cavestuff:whitespike" .. i, {
    description = "White Crystal Spike",
    mesh = "mese_crystal_ore" .. i .. ".obj",
    tiles = {"caverealms_glow_white.png"},
    drawtype = "mesh",
    paramtype = "light",
		paramtype2 = "facedir",
    groups = utility.dig_groups("crystal", {
			attached_node = 1, fall_damage_add_percent = 100,
		}),
    sounds = default.node_sound_glass_defaults(),
    light_source = (4 + i),
    selection_box = {
      type = "fixed",
      fixed = {-0.3, -0.5, -0.3, 0.3, 0.35, 0.3}
    },
		on_rotate = function(...)
			return screwdriver.rotate_simple(...)
		end,
		on_construct = function(pos)
			local node = minetest.get_node(pos)
			node.param2 = math_random(0, 3)
			minetest.swap_node(pos, node)
		end,
		on_player_walk_over = function(pos, player)
			utility.damage_player(player, "fleshy", 1*500, "ground")

			if player:get_hp() == 0 then
				minetest.chat_send_all("# Server: <" .. rename.gpn(player:get_player_name()) .. "> stepped on a crystal spike.")
			end
		end,
  })
end

-- Special cobble type which mimics default cobble. Needed for cavegen.
-- The player should not be able to obtain this nodetype directly.
minetest.register_node("cavestuff:cobble", {
  description = "Cobblestone",
  tiles = {"default_cobble.png"},
  is_ground_content = true, -- Important!
  groups = utility.dig_groups("cobble", {
		melts = 1, cobble_type = 1,
	}),
	_melts_to = "cavestuff:cobble_with_rockmelt",
  drop = "default:cobble", -- Mimic default cobble.
  _is_bulk_mapgen_stone = true,
  sounds = default.node_sound_stone_defaults(),

	-- Common stone does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},

	on_finish_collapse = function(pos)
		minetest.swap_node(pos, {name="default:cobble"})
	end,

	on_collapse_to_entity = function(pos)
		return {ItemStack("default:cobble")}
	end,

	-- Intersection point can be nil, and 'above' can be same as 'pos'.
	on_arrow_impact = function(pos, above, entity, intersection_point)
		local ent = entity:get_luaentity()

		if ent.name == "throwing:arrow_shell_entity" then
			if minetest.test_protection(pos, "") then
				return
			end

			minetest.swap_node(pos, {name="default:cobble"})
			core.spawn_falling_node(pos)
		end
	end,
})

