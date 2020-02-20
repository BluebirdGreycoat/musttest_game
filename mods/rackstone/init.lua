
rackstone = rackstone or {}
rackstone.modpath = minetest.get_modpath("rackstone")
-- group:rackstone is being used to check if a node should be considered naturally occuring for ambiance purposes.



rackstone.rackstone_sounds = 
function()
    local table = {
        dig = {name="rackstone_dugstonemetal", gain=1.0},
        dug = {name="rackstone_digstonemetal", gain=1.0},
        --place = {name="rackstone_placestonemetal", gain=1.0},
    }
    return default.node_sound_stone_defaults(table)
end

rackstone.cobble_sounds =
function()
    local table = {
			footstep = {name="default_gravel_footstep", gain=0.5},
    }
    return default.node_sound_stone_defaults(table)
end

rackstone.destabilize_dauthsand =
function(pos)
  local minp = {x=pos.x-1, y=pos.y, z=pos.z-1}
  local maxp = {x=pos.x+1, y=pos.y, z=pos.z+1}
  local nodes = minetest.find_nodes_in_area(minp, maxp, "rackstone:dauthsand_stable")
  for k, v in ipairs(nodes) do
    minetest.add_node(v, {name="rackstone:dauthsand"})
    minetest.check_for_falling(v)
  end
end



minetest.register_node("rackstone:rackstone", {
	description = "Rackstone",
	tiles = {"rackstone_rackstone.png"},
	groups = utility.dig_groups("stone", {rackstone=1, stabilize_dauthsand=1, netherack=1}),
	sounds = default.node_sound_stone_defaults(),
  after_destruct = rackstone.destabilize_dauthsand,
	movement_speed_multiplier = default.ROAD_SPEED_NETHER,

	-- Common stone does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},

	drop = "rackstone:cobble",
})

minetest.register_node("rackstone:cobble", {
	description = "Rackstone Cobble",
	tiles = {"rackstone_rackstone_cobble.png"},
	groups = utility.dig_groups("cobble", {rackstone=1, stabilize_dauthsand=1, netherack=1}),
	sounds = rackstone.cobble_sounds(),
  after_destruct = rackstone.destabilize_dauthsand,
	movement_speed_multiplier = default.ROAD_SPEED_NETHER,

	-- Common stone does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},
	_no_auto_pop = true,
})

minetest.register_node("rackstone:rackstone_brick2", {
	description = "Rackstone Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"rackstone_rackstone_brick.png"},
	groups = utility.dig_groups("brick", {rackstone=1, brick=1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("rackstone:rackstone_block", {
	description = "Rackstone Block",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"rackstone_rackstone_block.png"},
	groups = utility.dig_groups("block", {rackstone=1}),
	sounds = default.node_sound_stone_defaults(),
})



local after_redrack_remove = function(pos)
  -- Remove netherflame above.
  local flamepos = {x=pos.x, y=pos.y+1, z=pos.z}
  if minetest.get_node(flamepos).name == "fire:nether_flame" then
    minetest.remove_node(flamepos)
  end

  -- Tricks!
  if math.random(1, 500) == 1 then
    local which = math.random(1, 4)
    ambiance.sound_play("tnt_gunpowder_burning", pos, 2, 20)
    
    if which == 1 then
      minetest.add_node(pos, {name='rackstone:evilrack'})
      core.check_for_falling(pos)
    elseif which == 2 then
      minetest.add_node(pos, {name="fire:nether_flame"})
    elseif which == 3 then
      minetest.add_node(pos, {name="default:lava_source"})
    else
			--ambiance.sound_play("tnt_gunpowder_burning", pos, 2, 20)
			-- Delay after TNT gunpowder burning sound to give warning.
			minetest.after(1.5, function()
				local def = {
					radius = 3,
					damage_radius = 2,
					ignore_protection = false,
					disable_drops = true,
					ignore_on_blast = false,
				}
				tnt.boom(pos, def)
			end)
    end
  end
end
rackstone.after_redrack_remove = after_redrack_remove

local on_redrack_place = function(pos)
  if math.random(1, 6) == 1 then
    local posabove = {x=pos.x, y=pos.y+1, z=pos.z}
    local light = minetest.get_node_light(posabove)
    if light then
      if light >= 15 then
        -- Copy position table, just in case.
        local npos = {x=pos.x, y=pos.y, z=pos.z}
        ambiance.sound_play("default_gravel_footstep", npos, 1, 20)
        minetest.after(math.random(1, 6), function()
          minetest.remove_node(npos)
          local def = {
            radius = 2,
            damage_radius = 2,
            ignore_protection = false,
            disable_drops = true,
            ignore_on_blast = false,
          }
          tnt.boom(npos, def)
        end)
      end
    end
  end
end
rackstone.on_redrack_place = on_redrack_place

minetest.register_node("rackstone:redrack", {
	description = "Netherack",
	tiles = {"rackstone_redrack.png"},
	groups = utility.dig_groups("netherack", {rackstone=1, stabilize_dauthsand=1, netherack=1}),
	sounds = rackstone.rackstone_sounds(),
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,
	drop = "rackstone:redrack_cobble",

	-- Common stone does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},
  
  after_destruct = function(...)
    after_redrack_remove(...)
    rackstone.destabilize_dauthsand(...)
  end,
  
  on_construct = function(...)
    on_redrack_place(...)
  end,

	on_player_walk_over = function(pos, player)
		if math.random(1, 2000) == 1 then
			minetest.after(math.random(1, 4), function()
				if not minetest.test_protection(pos, "") then
					tnt.boom(pos, {
						radius = 2,
						ignore_protection = false,
						ignore_on_blast = false,
						damage_radius = 3,
						disable_drops = true,
					})
				end
			end)
		end
	end,
})



minetest.register_node("rackstone:redrack_cobble", {
	description = "Cobbled Netherack",
	tiles = {"rackstone_redrack_cobble.png"},
	groups = utility.dig_groups("netherack", {rackstone=1, stabilize_dauthsand=1, netherack=1}),
	sounds = rackstone.rackstone_sounds(),
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,

	-- Common stone does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},
	_no_auto_pop = true,

  after_destruct = function(...)
    after_redrack_remove(...)
    rackstone.destabilize_dauthsand(...)
  end,

  on_construct = function(...)
    on_redrack_place(...)
  end,

	on_player_walk_over = function(pos, player)
		if math.random(1, 2000) == 1 then
			minetest.after(math.random(1, 4), function()
				if not minetest.test_protection(pos, "") then
					tnt.boom(pos, {
						radius = 2,
						ignore_protection = false,
						ignore_on_blast = false,
						damage_radius = 3,
						disable_drops = true,
					})
				end
			end)
		end
	end,
})



minetest.register_node("rackstone:nether_grit", {
  description = "Nether Grit",
  tiles = {"rackstone_redrack2.png"},
  groups = utility.dig_groups("racksand", {falling_node=1}),
  sounds = rackstone.rackstone_sounds(),
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,
	liquid_viscosity = 8,
  liquidtype = "source",
  liquid_alternative_flowing = "rackstone:nether_grit",
  liquid_alternative_source = "rackstone:nether_grit",
  liquid_renewable = false,
  liquid_range = 0,
  walkable = false,
	drawtype = "glasslike",
  paramtype = "light",
	post_effect_color = {a = 200, r = 30, g = 0, b = 0},
	damage_per_second = 1,

	drop = {
		max_items = 1,
		items = {
			{items = {'default:flint'}, rarity = 16},
			{items = {'rackstone:nether_grit'}}
		}
	},
})

minetest.register_node("rackstone:void", {
  description = "Nether Void Gap (You Hacker!)",
  tiles = {"rackstone_redrack.png"},
  groups = utility.dig_groups("cobble"),
  sounds = rackstone.rackstone_sounds(),
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,
  walkable = false,
	drawtype = "glasslike",
  paramtype = "light",
	post_effect_color = {a = 200, r = 30, g = 0, b = 0},
	damage_per_second = 1,
	drop = "",
})

minetest.register_node("rackstone:redrack_with_iron", {
  description = "Netherack With Iron",
  tiles = {"rackstone_redrack.png^default_mineral_iron.png"},
  groups = utility.dig_groups("mineral", {rackstone=1, netherack=1, ore = 1}),
  sounds = rackstone.rackstone_sounds(),
  drop = "default:iron_lump",
	silverpick_drop = true,
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,
  
  after_destruct = function(...)
    after_redrack_remove(...)
  end,
})

minetest.register_node("rackstone:redrack_with_copper", {
  description = "Netherack With Copper",
  tiles = {"rackstone_redrack.png^default_mineral_copper.png"},
  groups = utility.dig_groups("mineral", {rackstone=1, netherack=1, ore=1}),
  sounds = rackstone.rackstone_sounds(),
  drop = "default:copper_lump",
	silverpick_drop = true,
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,
  
  after_destruct = function(...)
    after_redrack_remove(...)
  end,
})

minetest.register_node("rackstone:redrack_with_coal", {
  description = "Netherack With Coal",
  tiles = {"rackstone_redrack.png^default_mineral_coal.png"},
  groups = utility.dig_groups("mineral", {rackstone=1, netherack=1}),
  sounds = rackstone.rackstone_sounds(),
  drop = "default:coal_lump",
	silverpick_drop = true,
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,
  
  after_destruct = function(...)
    after_redrack_remove(...)
  end,
})

minetest.register_node("rackstone:redrack_with_tin", {
  description = "Netherack With Tin",
  tiles = {"rackstone_redrack.png^moreores_mineral_tin.png"},
  groups = utility.dig_groups("mineral", {rackstone=1, netherack=1, ore=1}),
  sounds = rackstone.rackstone_sounds(),
  drop = "moreores:tin_lump",
	silverpick_drop = true,
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,

  after_destruct = function(...)
    after_redrack_remove(...)
  end,
})



minetest.register_node("rackstone:tile", {
	description = "Nether Grit Tile",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"rackstone_redtile.png"},
	groups = utility.dig_groups("brick", {brick=1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("rackstone:brick", {
	description = "Netherack Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"rackstone_brick.png"},
	groups = utility.dig_groups("brick", {brick=1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("rackstone:redrack_block", {
	description = "Netherack Block",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"rackstone_redrack_block.png"},
	groups = utility.dig_groups("block"),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("rackstone:brick_black", {
	description = "Black Rackstone Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"rackstone_brick_black.png"},
	groups = utility.dig_groups("brick", {brick=1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("rackstone:blackrack_block", {
	description = "Black Rackstone Block",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"rackstone_blackrack_block.png"},
	groups = utility.dig_groups("block"),
	sounds = default.node_sound_stone_defaults(),
})



minetest.register_node("rackstone:bluerack", {
	description = "Blue Rackstone",
	tiles = {"rackstone_bluerack.png"},
	groups = utility.dig_groups("hardstone", {rackstone=1, netherack=1}),
	sounds = rackstone.rackstone_sounds(),
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,
})

minetest.register_node("rackstone:bluerack_brick", {
	description = "Blue Rackstone Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"rackstone_bluerack_brick.png"},
	groups = utility.dig_groups("brick", {rackstone=1, brick=1}),
	sounds = rackstone.rackstone_sounds(),
})

minetest.register_node("rackstone:bluerack_block", {
	description = "Blue Rackstone Block",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"rackstone_bluerack_block.png"},
	groups = utility.dig_groups("block", {rackstone=1}),
	sounds = rackstone.rackstone_sounds(),
})



minetest.register_node("rackstone:blackrack", {
  description = "Black Rackstone",
  tiles = {"rackstone_blackrack.png"},
  groups = utility.dig_groups("cobble", {rackstone=1, native_stone=1, stabilize_dauthsand=1, netherack=1}),
  sounds = rackstone.rackstone_sounds(),
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,
  
  paramtype2 = "none",
  after_destruct = rackstone.destabilize_dauthsand,
  
  -- Nodes placed shall not produce starpearls when dug.
  after_place_node = function(pos, placer, itemstack, pointed_thing)
    if placer then
      local node = minetest.get_node(pos)
      node.param2 = 1
      minetest.swap_node(pos, node)
    end
  end,
  
  -- Digging nodes placed by mapgen shall sometimes produce starpearls.
  after_dig_node = function(pos, oldnode, oldmetadata, digger)
    if digger and oldnode.param2 == 0 then
      -- Only drop them rarely.
      -- Only drop if blackrack was placed by mapgen.
      -- This prevents place-harvest-place-harvest exploit.
      local chance = 80
      local tool = digger:get_wielded_item():get_name()

      if tool:find("pick") and tool:find("silver") then
        chance = 20
      end

      if math.random(1, chance) == 1 then
        local inv = digger:get_inventory()
        local leftover = inv:add_item("main", ItemStack('starpearl:pearl'))
        minetest.add_item(pos, leftover)
      end
    end
  end,
})



minetest.register_node("rackstone:evilrack", {
	description = "Witchrack",
	tiles = {"rackstone_evilstone.png"},
	groups = utility.dig_groups("netherack", {falling_node=1, rackstone=1, netherack=1}),
	sounds = rackstone.rackstone_sounds(),
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,
})



minetest.register_node("rackstone:dauthsand", {
  description = "Dauthsand",
  tiles = {"rackstone_dauthsand.png"},
  groups = utility.dig_groups("racksand", {falling_node=1, racksand=1, nether_soil=1}),
    --damage_per_second = 4,
    post_effect_color = {a=255, r=0, g=0, b=0},
  sounds = default.node_sound_gravel_defaults(),
  drop = {
    items = {
      {items = {'bluegrass:seed'}, rarity = 32},
      {items = {'rackstone:dauthsand'}},
      {items = {'default:flint'}, rarity = 16}
    }
  },
	movement_speed_multiplier = default.SLOW_SPEED,
  -- Stabilize dauth sand if held by rackstone.
  on_construct = function(pos)
    local x1 = minetest.get_node({x=pos.x+1, y=pos.y, z=pos.z}).name
    local x2 = minetest.get_node({x=pos.x-1, y=pos.y, z=pos.z}).name
    local z1 = minetest.get_node({x=pos.x, y=pos.y, z=pos.z+1}).name
    local z2 = minetest.get_node({x=pos.x, y=pos.y, z=pos.z-1}).name
    
    if minetest.get_item_group(x1, "stabilize_dauthsand") > 0 and
       minetest.get_item_group(x2, "stabilize_dauthsand") > 0 then
      minetest.swap_node(pos, {name="rackstone:dauthsand_stable"})
    elseif minetest.get_item_group(z1, "stabilize_dauthsand") > 0 and
           minetest.get_item_group(z2, "stabilize_dauthsand") > 0 then
      minetest.swap_node(pos, {name="rackstone:dauthsand_stable"})
    end
  end,
})

-- Special sand type that doesn't fall.
minetest.register_node("rackstone:dauthsand_stable", {
  description = "Dauthsand",
  tiles = {"rackstone_dauthsand.png"},
  groups = utility.dig_groups("gravel", {racksand=1, nether_soil=1}),
    --damage_per_second = 4,
    post_effect_color = {a=255, r=0, g=0, b=0},
  sounds = default.node_sound_gravel_defaults(),
  drop = 'rackstone:dauthsand',
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_craft({
  type = "cooking",
  output = "default:glass",
  recipe = "rackstone:dauthsand",
})

-- Netherack Crafts
minetest.register_craft({
    output = "rackstone:brick 4",
    recipe = {
        {"rackstone:redrack", "rackstone:redrack"},
        {"rackstone:redrack", "rackstone:redrack"},
    }
})

minetest.register_craft({
    output = "rackstone:redrack_block 9",
    recipe = {
        {"rackstone:redrack", "rackstone:redrack", "rackstone:redrack"},
        {"rackstone:redrack", "rackstone:redrack", "rackstone:redrack"},
        {"rackstone:redrack", "rackstone:redrack", "rackstone:redrack"},
    }
})

-- Blue Rackstone Crafts
minetest.register_craft({
    output = "rackstone:bluerack_brick 4",
    recipe = {
        {"rackstone:bluerack", "rackstone:bluerack"},
        {"rackstone:bluerack", "rackstone:bluerack"},
    }
})

minetest.register_craft({
    output = "rackstone:bluerack_block 9",
    recipe = {
        {"rackstone:bluerack", "rackstone:bluerack", "rackstone:bluerack"},
        {"rackstone:bluerack", "rackstone:bluerack", "rackstone:bluerack"},
        {"rackstone:bluerack", "rackstone:bluerack", "rackstone:bluerack"},
    }
})

-- Black Rackstone Crafts
minetest.register_craft({
    output = "rackstone:brick_black 4",
    recipe = {
        {"rackstone:blackrack", "rackstone:blackrack"},
        {"rackstone:blackrack", "rackstone:blackrack"},
    }
})

minetest.register_craft({
    output = "rackstone:blackrack_block 9",
    recipe = {
        {"rackstone:blackrack", "rackstone:blackrack", "rackstone:blackrack"},
        {"rackstone:blackrack", "rackstone:blackrack", "rackstone:blackrack"},
        {"rackstone:blackrack", "rackstone:blackrack", "rackstone:blackrack"},
    }
})

-- Rackstone Crafts
minetest.register_craft({
    output = "rackstone:rackstone_brick2 4",
    recipe = {
        {"rackstone:rackstone", "rackstone:rackstone"},
        {"rackstone:rackstone", "rackstone:rackstone"},
    }
})

minetest.register_craft({
    output = "rackstone:rackstone_block 9",
    recipe = {
        {"rackstone:rackstone", "rackstone:rackstone", "rackstone:rackstone"},
        {"rackstone:rackstone", "rackstone:rackstone", "rackstone:rackstone"},
        {"rackstone:rackstone", "rackstone:rackstone", "rackstone:rackstone"},
    }
})

minetest.register_craft({
	type = "cooking",
	output = 'rackstone:tile',
	recipe = 'rackstone:nether_grit',
	cooktime = 20,
})

minetest.register_craft({
	type = "cooking",
	output = 'rackstone:rackstone',
	recipe = 'rackstone:cobble',
	cooktime = 6,
})

minetest.register_craft({
	type = "cooking",
	output = 'rackstone:redrack',
	recipe = 'rackstone:redrack_cobble',
	cooktime = 3,
})

minetest.register_craft({
	type = "grinding",
	output = 'rackstone:dauthsand',
	recipe = 'rackstone:redrack',
	time = 20,
})

minetest.register_craft({
	type = "crushing",
	output = 'rackstone:nether_grit',
	recipe = 'rackstone:redrack',
	time = 60*1.0,
})

minetest.register_craft({
	type = "crushing",
	output = 'rackstone:dauthsand',
	recipe = 'rackstone:nether_grit',
	time = 60*1.0,
})

-- Rackstone
stairs.register_stair_and_slab(
	"rackstone",
	"rackstone:rackstone",
	{cracky=1},
	{"rackstone_rackstone.png"},
	"Rackstone",
	default.node_sound_stone_defaults()
)

stairs.register_stair_and_slab(
	"rackstone_cobble",
	"rackstone:cobble",
	{cracky=2},
	{"rackstone_rackstone_cobble.png"},
	"Rackstone Cobble",
	default.node_sound_stone_defaults()
)

-- Rackstone Block
stairs.register_stair_and_slab(
	"rackstone_block",
	"rackstone:rackstone_block",
	{cracky=1},
	{"rackstone_rackstone_block.png"},
	"Rackstone Block",
	default.node_sound_stone_defaults()
)

-- Rackstone Brick
stairs.register_stair_and_slab(
	"rackstone_brick2",
	"rackstone:rackstone_brick2",
	{cracky=1},
	{"rackstone_rackstone_brick.png"},
	"Rackstone Brick",
	default.node_sound_stone_defaults()
)

-- Netherack
stairs.register_stair_and_slab(
	"redrack",
	"rackstone:redrack",
	{cracky=3},
	{"rackstone_redrack.png"},
	"Netherack",
	rackstone.rackstone_sounds()
)

stairs.register_stair_and_slab(
	"redrack_cobble",
	"rackstone:redrack_cobble",
	{cracky=3},
	{"rackstone_redrack_cobble.png"},
	"Cobbled Netherack",
	rackstone.rackstone_sounds()
)

-- Netherack Block
stairs.register_stair_and_slab(
	"redrack_block",
	"rackstone:redrack_block",
	{cracky=3},
	{"rackstone_redrack_block.png"},
	"Netherack Block",
	default.node_sound_stone_defaults()
)

-- Netherack Brick
stairs.register_stair_and_slab(
	"rackstone_brick",
	"rackstone:brick",
	{cracky=2},
	{"rackstone_brick.png"},
	"Rackstone Brick",
	default.node_sound_stone_defaults()
)

-- Blue Rackstone
stairs.register_stair_and_slab(
	"bluerack",
	"rackstone:bluerack",
	{cracky=2},
	{"rackstone_bluerack.png"},
	"Blue Rackstone",
	rackstone.rackstone_sounds()
)

-- Blue Rackstone Block
stairs.register_stair_and_slab(
	"bluerack_block",
	"rackstone:bluerack_block",
	{cracky=2},
	{"rackstone_bluerack.png"},
	"Blue Rackstone Block",
	default.node_sound_stone_defaults()
)

-- Blue Rackstone Brick
stairs.register_stair_and_slab(
	"bluerack_brick",
	"rackstone:bluerack_brick",
	{cracky=2},
	{"rackstone_bluerack_brick.png"},
	"Blue Rackstone Brick",
	default.node_sound_stone_defaults()
)

-- Blackrack
stairs.register_stair_and_slab(
	"blackrack",
	"rackstone:blackrack",
	{cracky=2},
	{"rackstone_blackrack.png"},
	"Black Rackstone",
	rackstone.rackstone_sounds()
)

-- Black Rackstone Block
stairs.register_stair_and_slab(
	"blackrack_block",
	"rackstone:blackrack_block",
	{cracky=2},
	{"rackstone_blackrack_block.png"},
	"Black Rackstone Block",
	default.node_sound_stone_defaults()
)

-- Black Rackstone Brick
stairs.register_stair_and_slab(
	"rackstone_brick_black",
	"rackstone:brick_black",
	{cracky=2},
	{"rackstone_brick_black.png"},
	"Black Rackstone Brick",
	default.node_sound_stone_defaults()
)




-- These nodes appear only in the Outback.
-- They have enhanced drops in order to help new players.
minetest.register_node("rackstone:rackstone_with_coal", {
  description = "Rackstone With Coal",
  tiles = {"rackstone_rackstone.png^default_mineral_coal.png"},
  groups = utility.dig_groups("mineral", {rackstone=1, netherack=1}),
  sounds = default.node_sound_stone_defaults(),
  drop = "default:coal_lump 3",
	silverpick_drop = true,
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,
})

minetest.register_node("rackstone:rackstone_with_iron", {
  description = "Rackstone With Iron",
  tiles = {"rackstone_rackstone.png^default_mineral_iron.png"},
  groups = utility.dig_groups("mineral", {rackstone=1, netherack=1}),
  sounds = default.node_sound_stone_defaults(),
  drop = "default:iron_lump 3",
	silverpick_drop = true,
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,
})

minetest.register_node("rackstone:rackstone_with_copper", {
  description = "Rackstone With Copper",
  tiles = {"rackstone_rackstone.png^default_mineral_copper.png"},
  groups = utility.dig_groups("mineral", {rackstone=1, netherack=1}),
  sounds = default.node_sound_stone_defaults(),
  drop = "default:copper_lump 2",
	silverpick_drop = true,
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,
})

minetest.register_node("rackstone:rackstone_with_gold", {
  description = "Rackstone With Gold",
  tiles = {"rackstone_rackstone.png^default_mineral_gold.png"},
  groups = utility.dig_groups("mineral", {rackstone=1, netherack=1}),
  sounds = default.node_sound_stone_defaults(),
  drop = "default:gold_lump 2",
	silverpick_drop = true,
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,
})

minetest.register_node("rackstone:rackstone_with_diamond", {
  description = "Rackstone With Diamond",
  tiles = {"rackstone_rackstone.png^default_mineral_diamond.png"},
  groups = utility.dig_groups("mineral", {rackstone=1, netherack=1}),
  sounds = default.node_sound_stone_defaults(),
  drop = "default:diamond 2",
	silverpick_drop = true,
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,
})

minetest.register_node("rackstone:rackstone_with_mese", {
  description = "Rackstone With Mese",
  tiles = {"rackstone_rackstone.png^default_mineral_mese.png"},
  groups = utility.dig_groups("mineral", {rackstone=1, netherack=1}),
  sounds = default.node_sound_stone_defaults(),
  drop = "default:mese_crystal 2",
	silverpick_drop = true,
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,
})

minetest.register_node("rackstone:rackstone_with_meat", {
  description = "Rackstone With Unidentified Meat",
  tiles = {"rackstone_rackstone.png^rackstone_meat.png"},
  groups = utility.dig_groups("netherack", {rackstone=1, netherack=1}),
  sounds = default.node_sound_stone_defaults(),
  drop = "mobs:meat_raw 4",
	silverpick_drop = true,
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,
})
