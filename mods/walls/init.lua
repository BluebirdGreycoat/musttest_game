
walls = {}



walls.register = function(
		wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	local register_node = function(name, def)
		local ndef = table.copy(def)
		stairs.setup_nodedef_callbacks(name, ndef)
		minetest.register_node(name, ndef)
	end

	circular_saw.register_node(wall_mat, wall_name)

	-- inventory node, and pole-type wall start item
	register_node(":walls:" .. wall_name, {
		description = wall_desc .. " Wall",
		drawtype = "nodebox",
		node_box = {
			type = "connected",
			fixed = {{-1/4, -1/2, -1/4, 1/4, 1/2, 1/4}},
			-- connect_bottom =
			connect_front = {{-3/16, -1/2, -1/2,  3/16, 3/8, -1/4}},
			connect_left = {{-1/2, -1/2, -3/16, -1/4, 3/8,  3/16}},
			connect_back = {{-3/16, -1/2,  1/4,  3/16, 3/8,  1/2}},
			connect_right = {{ 1/4, -1/2, -3/16,  1/2, 3/8,  3/16}},
		},
		-- Connect to pillars too -- lets players screwdriver a pillar sideways and use it as a wall post, or something.
		connects_to = { "group:wall", "group:stone", "group:brick", "group:rackstone", "group:pillar" },
		paramtype = "light",
		is_ground_content = false,
		tiles = { wall_texture },
		walkable = true,
		-- Must be in group:wall otherwise walls will not connect.
		groups = utility.dig_groups("wall", {wall = 1}),
		sounds = wall_sounds,
		_stairs_parent_material = wall_mat,
	})

	register_node(":walls:" .. wall_name .. "_noconnect", {
		description = wall_desc .. " Pillar",
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {{-1/4, -1/2, -1/4, 1/4, 1/2, 1/4}},
		},
		paramtype = "light",
		paramtype2 = "facedir",
		--is_ground_content = false,
		tiles = { wall_texture },
		walkable = true,
		groups = utility.dig_groups("wall"),
		sounds = wall_sounds,
		_stairs_parent_material = wall_mat,
	})

	register_node(":walls:" .. wall_name .. "_noconnect_wide", {
		description = wall_desc .. " Wide Pillar",
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {{-0.5, -0.5, -0.25, 0.5, 0.5, 0.25}},
		},
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		tiles = { wall_texture },
		walkable = true,
		groups = utility.dig_groups("wall"),
		sounds = wall_sounds,
		_stairs_parent_material = wall_mat,
	})

	register_node(":walls:" .. wall_name .. "_half", {
		drawtype = "nodebox",
		description = wall_desc .. " Half Wall",
		tiles = { wall_texture },
		groups = utility.dig_groups("wall"),
		sounds = wall_sounds,
		paramtype = "light",
		paramtype2 = "facedir",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.25, -0.5, 0.25, 0.25, 0.5, 0.5},
			},
		},
		_stairs_parent_material = wall_mat,
	})

	-- crafting recipe for standard walls.
	minetest.register_craft({
		output = "walls:" .. wall_name .. " 6",
		recipe = {
			{ wall_mat, wall_mat, wall_mat},
			{ wall_mat, wall_mat, wall_mat},
		}
	})

	-- pillars
	register_node(":pillars:" .. wall_name .. "_bottom", {
		drawtype = "nodebox",
		description = wall_desc .. " Pillar Base",
		tiles = { wall_texture },
		groups = utility.dig_groups("wall", {pillar = 1}),
		sounds = wall_sounds,
		paramtype = "light",
		paramtype2 = "facedir",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.5,-0.5,0.5,-0.375,0.5},
				{-0.375,-0.375,-0.375,0.375,-0.125,0.375},
				{-0.25,-0.125,-0.25,0.25,0.5,0.25}, 
			},
		},
		_stairs_parent_material = wall_mat,
	})

	register_node(":pillars:" .. wall_name .. "_bottom_half", {
		drawtype = "nodebox",
		description = wall_desc .. " Half Pillar Base",
		tiles = { wall_texture },
		groups = utility.dig_groups("wall"),
		sounds = wall_sounds,
		paramtype = "light",
		paramtype2 = "facedir",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, 0, 0.5, -0.375, 0.5},
				{-0.375, -0.375, 0.125, 0.375, -0.125, 0.5},
				{-0.25, -0.125, 0.25, 0.25, 0.5, 0.5},
			},
		},
		_stairs_parent_material = wall_mat,
	})
	
	register_node(":pillars:" .. wall_name .. "_top", {
		drawtype = "nodebox",
		description = wall_desc .. " Pillar Top",
		tiles = { wall_texture },
		groups = utility.dig_groups("wall", {pillar = 1}),
		sounds = wall_sounds,
		paramtype = "light",
		paramtype2 = "facedir",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5,0.3125,-0.5,0.5,0.5,0.5}, 
				{-0.375,0.0625,-0.375,0.375,0.3125,0.375}, 
				{-0.25,-0.5,-0.25,0.25,0.0625,0.25},
			},
		},
		_stairs_parent_material = wall_mat,
	})

	register_node(":pillars:" .. wall_name .. "_top_half", {
		drawtype = "nodebox",
		description = wall_desc .. " Half Pillar Top",
		tiles = { wall_texture },
		groups = utility.dig_groups("wall"),
		sounds = wall_sounds,
		paramtype = "light",
		paramtype2 = "facedir",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, 0.3125, 0, 0.5, 0.5, 0.5},
				{-0.375, 0.0625, 0.125, 0.375, 0.3125, 0.5},
				{-0.25, -0.5, 0.25, 0.25, 0.0625, 0.5},
			},
		},
		_stairs_parent_material = wall_mat,
	})

	register_node(":pillars:" .. wall_name .. "_bottom_full", {
		drawtype = "nodebox",
		description = wall_desc .. " Wide Pillar Base #1",
		tiles = { wall_texture },
		groups = utility.dig_groups("wall"),
		sounds = wall_sounds,
		paramtype = "light",
		paramtype2 = "facedir",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, -0.375, 0.5},
				{-0.375, -0.375, -0.5, 0.375, -0.125, 0.5},
				{-0.25, -0.125, -0.5, 0.25, 0.5, 0.5},
			},
		},
		_stairs_parent_material = wall_mat,
	})

	register_node(":pillars:" .. wall_name .. "_bottom_back", {
		drawtype = "nodebox",
		description = wall_desc .. " Wide Pillar Base #2",
		tiles = { wall_texture },
		groups = utility.dig_groups("wall"),
		sounds = wall_sounds,
		paramtype = "light",
		paramtype2 = "facedir",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, -0.375, 0.5}, -- NodeBox4
				{-0.5, -0.375, -0.375, 0.5, -0.125, 0.5}, -- NodeBox5
				{-0.5, -0.125, -0.25, 0.5, 0.5, 0.5}, -- NodeBox6
			},
		},
		_stairs_parent_material = wall_mat,
	})

	register_node(":pillars:" .. wall_name .. "_top_full", {
		drawtype = "nodebox",
		description = wall_desc .. " Wide Pillar Top #1",
		tiles = { wall_texture },
		groups = utility.dig_groups("wall"),
		sounds = wall_sounds,
		paramtype = "light",
		paramtype2 = "facedir",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, 0.375, -0.5, 0.5, 0.5, 0.5},
				{-0.5, 0.125, -0.375, 0.5, 0.375, 0.375},
				{-0.5, -0.5, -0.25, 0.5, 0.5, 0.25},
			},
		},
		_stairs_parent_material = wall_mat,
	})

	register_node(":pillars:" .. wall_name .. "_top_back", {
		drawtype = "nodebox",
		description = wall_desc .. " Wide Pillar Top #2",
		tiles = { wall_texture },
		groups = utility.dig_groups("wall"),
		sounds = wall_sounds,
		paramtype = "light",
		paramtype2 = "facedir",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, 0.375, -0.5, 0.5, 0.5, 0.5}, -- NodeBox1
				{-0.5, 0.125, -0.375, 0.5, 0.375, 0.5}, -- NodeBox2
				{-0.5, -0.5, -0.25, 0.5, 0.125, 0.5}, -- NodeBox3
			},
		},
		_stairs_parent_material = wall_mat,
	})

	--circular_saw.register_node(wall_mat, wall_name)

	register_node(":murderhole:" .. wall_name, {
		drawtype = "nodebox",
		description = wall_desc .. " Murderhole",
		tiles = { wall_texture },
		groups = utility.dig_groups("wall"),
		sounds = wall_sounds,
		paramtype = "light",
		paramtype2 = "facedir",
		node_box = {
			type = "fixed",
			fixed = {
				{-8/16,-8/16,-8/16,-4/16,8/16,8/16},
				{4/16,-8/16,-8/16,8/16,8/16,8/16},
				{-4/16,-8/16,-8/16,4/16,8/16,-4/16},
				{-4/16,-8/16,8/16,4/16,8/16,4/16},
			},
		},
		_stairs_parent_material = wall_mat,
	})
	
	--circular_saw.register_node(wall_mat, wall_name)

	register_node(":machicolation:" .. wall_name, {
		drawtype = "nodebox",
		description = wall_desc .. " Machicolation",
		tiles = { wall_texture },
		groups = utility.dig_groups("wall"),
		sounds = wall_sounds,
		paramtype = "light",
		paramtype2 = "facedir",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, 0, -0.5, 0.5, 0.5, 0},
				{-0.5, -0.5, 0, -0.25, 0.5, 0.5},
				{0.25, -0.5, 0, 0.5, 0.5, 0.5},
			},
		},
		_stairs_parent_material = wall_mat,
	})

	--circular_saw.register_node(wall_mat, wall_name)

	-- arrow slits
	register_node(":arrowslit:"..wall_name, {
		drawtype = "nodebox",
		description = wall_desc .. " Arrowslit",
		tiles = { wall_texture },
		groups = utility.dig_groups("wall"),
		sounds = wall_sounds,
		paramtype = "light",
		paramtype2 = "facedir",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.375, 0.5, -0.0625, 0.375, 0.3125},
				{0.0625, -0.375, 0.5, 0.5, 0.375, 0.3125},
				{-0.5, 0.375, 0.5, 0.5, 0.5, 0.3125}, 
				{-0.5, -0.5, 0.5, 0.5, -0.375, 0.3125}, 
				{0.25, -0.5, 0.3125, 0.5, 0.5, 0.125},
				{-0.5, -0.5, 0.3125, -0.25, 0.5, 0.125},
			},
		},
		_stairs_parent_material = wall_mat,
	})

	register_node(":arrowslit:"..wall_name.."_cross", {
		drawtype = "nodebox",
		description = wall_desc .. " Arrowslit With Cross",
		tiles = { wall_texture },
		groups = utility.dig_groups("wall"),
		sounds = wall_sounds,
		paramtype = "light",
		paramtype2 = "facedir",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.125, 0.5, -0.0625, 0.375, 0.3125},
				{0.0625, -0.125, 0.5, 0.5, 0.375, 0.3125},
				{-0.5, 0.375, 0.5, 0.5, 0.5, 0.3125},
				{-0.5, -0.5, 0.5, 0.5, -0.375, 0.3125},
				{0.0625, -0.375, 0.5, 0.5, -0.25, 0.3125},
				{-0.5, -0.375, 0.5, -0.0625, -0.25, 0.3125},
				{-0.5, -0.25, 0.5, -0.1875, -0.125, 0.3125},
				{0.1875, -0.25, 0.5, 0.5, -0.125, 0.3125},
				{0.25, -0.5, 0.3125, 0.5, 0.5, 0.125},
				{-0.5, -0.5, 0.3125, -0.25, 0.5, 0.125},
			},
		},
		_stairs_parent_material = wall_mat,
	})

	register_node(":arrowslit:"..wall_name.."_hole", {
		drawtype = "nodebox",
		description = wall_desc .. " Arrowslit With Hole",
		tiles = { wall_texture },
		groups = utility.dig_groups("wall"),
		sounds = wall_sounds,
		paramtype = "light",
		paramtype2 = "facedir",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.375, 0.5, -0.125, 0.375, 0.3125},
				{0.125, -0.375, 0.5, 0.5, 0.375, 0.3125},
				{-0.5, -0.5, 0.5, 0.5, -0.375, 0.3125},
				{0.0625, -0.125, 0.5, 0.125, 0.375, 0.3125},
				{-0.125, -0.125, 0.5, -0.0625, 0.375, 0.3125},
				{-0.5, 0.375, 0.5, 0.5, 0.5, 0.3125},
				{0.25, -0.5, 0.3125, 0.5, 0.5, 0.125},
				{-0.5, -0.5, 0.3125, -0.25, 0.5, 0.125},
			},
		},
		_stairs_parent_material = wall_mat,
	})

	register_node(":arrowslit:"..wall_name.."_embrasure", {
		drawtype = "nodebox",
		description = wall_desc .. " Embrasure",
		tiles = { wall_texture },
		groups = utility.dig_groups("wall"),
		sounds = wall_sounds,
		paramtype = "light",
		paramtype2 = "facedir",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.25, -0.5, 0.375, -0.125, 0.5, 0.5},
				{0.125, -0.5, 0.375, 0.25, 0.5, 0.5},
				{0.25, -0.5, 0.25, 0.5, 0.5, 0.5},
				{0.375, -0.5, 0.125, 0.5, 0.5, 0.25},
				{-0.5, -0.5, 0.25, -0.25, 0.5, 0.5},
				{-0.5, -0.5, 0.125, -0.375, 0.5, 0.25},
			},
		},
		_stairs_parent_material = wall_mat,
	})

	--circular_saw.register_node(wall_mat, wall_name)
end

walls.register("cobble", "Cobblestone", "default_cobble.png",
		"default:cobble", default.node_sound_stone_defaults())

walls.register("copper", "Copper Block", "default_copper_block.png",
		"default:copperblock", default.node_sound_metal_defaults())

walls.register("steel", "Steel Block", "default_steel_block.png",
		"default:steelblock", default.node_sound_metal_defaults())

walls.register("gold", "Gold Block", "default_gold_block.png",
		"default:goldblock", default.node_sound_metal_defaults())

walls.register("bronze", "Bronze Block", "default_bronze_block.png",
		"default:bronzeblock", default.node_sound_metal_defaults())

walls.register("tin", "Tin Block", "moreores_tin_block.png",
		"moreores:tin_block", default.node_sound_metal_defaults())

walls.register("stone", "Stone", "default_stone.png",
		"default:stone", default.node_sound_stone_defaults())

walls.register("stonebrick", "Stone Brick", "default_stone_brick.png",
		"default:stonebrick", default.node_sound_stone_defaults())

walls.register("desert_stone", "Redstone", "default_desert_stone.png",
		"default:desert_stone", default.node_sound_stone_defaults())

walls.register("sandstonebrick", "Sandstone Brick", "default_sandstone_brick.png",
		"default:sandstonebrick", default.node_sound_stone_defaults())

walls.register("desert_stonebrick", "Redstone Brick", "default_desert_stone_brick.png",
		"default:desert_stonebrick", default.node_sound_stone_defaults())

walls.register("sandstone", "Sandstone", "default_sandstone.png",
		"default:sandstone", default.node_sound_stone_defaults())

walls.register("desert_sandstone", "Desert Sandstone", "default_desert_sandstone.png",
		"default:desert_sandstone", default.node_sound_stone_defaults())

walls.register("silver_sandstone", "Silver Sandstone", "default_silver_sandstone.png",
		"default:silver_sandstone", default.node_sound_stone_defaults())

walls.register("mossycobble", "Mossy Cobblestone", "default_mossycobble.png",
		"default:mossycobble", default.node_sound_stone_defaults())

walls.register("desertcobble", "Chalked Cobble Redstone", "default_desert_cobble.png",
		"default:desert_cobble", default.node_sound_stone_defaults())

walls.register("desertcobble2", "Cobble Redstone", "default_desert_cobble2.png",
		"default:desert_cobble2", default.node_sound_stone_defaults())

walls.register("redrack", "Netherack", "rackstone_redrack.png",
		"rackstone:redrack", default.node_sound_stone_defaults())

walls.register("redrack_cobble", "Cobbled Netherack", "rackstone_redrack_cobble.png",
		"rackstone:redrack_cobble", default.node_sound_stone_defaults())

walls.register("redrack_brick", "Netherack Brick", "rackstone_brick.png",
		"rackstone:brick", default.node_sound_stone_defaults())

walls.register("blackrack", "Blackrack", "rackstone_blackrack.png",
		"rackstone:blackrack", default.node_sound_stone_defaults())

walls.register("bluerack", "Bluerack", "rackstone_bluerack.png",
		"rackstone:bluerack", default.node_sound_stone_defaults())

walls.register("bluerack_brick", "Blue Rackstone Brick", "rackstone_bluerack_brick.png",
		"rackstone:bluerack_brick", default.node_sound_stone_defaults())

walls.register("blackrack_brick", "Black Rackstone Brick", "rackstone_brick_black.png",
		"rackstone:brick_black", default.node_sound_stone_defaults())

walls.register("rackstone_brick", "Rackstone Brick", "rackstone_rackstone_brick.png",
		"rackstone:rackstone_brick2", default.node_sound_stone_defaults())

walls.register("rackstone", "Rackstone", "rackstone_rackstone.png",
		"rackstone:rackstone", default.node_sound_stone_defaults())

walls.register("whitestone_brick", "Bleached Brick", "whitestone_brick.png",
		"whitestone:brick", default.node_sound_stone_defaults())

walls.register("ice", "Ice", "default_ice.png",
		"default:ice", default.node_sound_glass_defaults())

walls.register("snow_brick", "Snow Brick", "snow_bricks_snow_brick.png",
		"snow_bricks:snow_brick", default.node_sound_glass_defaults())

walls.register("ice_brick", "Ice Brick", "snow_bricks_ice_brick.png",
		"snow_bricks:ice_brick", default.node_sound_glass_defaults())

walls.register("lapis_cobble", "Cobbled Lapis", "lapis_cobble.png",
		"lapis:lapis_cobble", default.node_sound_stone_defaults())

walls.register("obsidian", "Obsidian", "default_obsidian.png",
		"default:obsidian", default.node_sound_stone_defaults())

walls.register("obsidian_brick", "Obsidian Brick", "default_obsidian_brick.png",
		"default:obsidianbrick", default.node_sound_stone_defaults())

walls.register("rackstone_cobble", "Rackstone Cobble", "rackstone_rackstone_cobble.png",
		"rackstone:cobble", default.node_sound_stone_defaults())

