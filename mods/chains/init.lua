local chains_sbox = {
	type = "fixed",
	fixed = { -0.1, -0.625, -0.1, 0.1, 0.5, 0.1 }
}

local topchains_sbox = {
	type = "fixed",
	fixed = {
		{ -0.25, 0.35, -0.25, 0.25, 0.5, 0.25 },
		{ -0.1, -0.625, -0.1, 0.1, 0.4, 0.1 }
	}
}

minetest.register_node("chains:iron_chain", {
	description = "Wrought Iron Chain",
	drawtype = "mesh",
	mesh = "chains.obj",
	tiles = {"chains_iron.png"},
	walkable = false,
	climbable = true,
	sunlight_propagates = true,
	paramtype = "light",
	groups = {level=1, cracky=3, hanging_node=1},
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3}
	},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("chains:bronze_chain", {
	description = "Bronze Chain",
	drawtype = "mesh",
	mesh = "chains.obj",
	tiles = {"chains_bronze.png"},
	walkable = false,
	climbable = true,
	sunlight_propagates = true,
	paramtype = "light",
	groups = {level=1, cracky=3, hanging_node=1},
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3}
	},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("chains:iron_chain_top", {
	description = "Wrought Iron Chain Ceiling Mount",
	drawtype = "mesh",
	mesh = "top_chains.obj",
	tiles = {"chains_iron.png"},
	walkable = false,
	climbable = true,
	sunlight_propagates = true,
	paramtype = "light",
	groups = {level=1, cracky=3, hanging_node=1},
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3}
	},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("chains:bronze_chain_top", {
	description = "Bronze Chain Ceiling Mount",
	drawtype = "mesh",
	mesh = "top_chains.obj",
	tiles = {"chains_bronze.png"},
	walkable = false,
	climbable = true,
	sunlight_propagates = true,
	paramtype = "light",
	groups = {level=1, cracky=3, hanging_node=1},
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3}
	},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("chains:iron_chandelier", {
	description = "Wrought Iron Chandelier",
	paramtype = "light",
	light_source = default.LIGHT_MAX-3,
	walkable = false,
	climbable = true,
	sunlight_propagates = true,
	paramtype = "light",
	tiles = {
		"chains_iron.png",
		"chains_candle.png",
		{
			name="chains_flame.png",
			animation={
				type="vertical_frames",
				aspect_w=16,
				aspect_h=16,
				length=3.0
			}
		}
	},
	drawtype = "mesh",
	mesh = "chains_chandelier.obj",
	groups = {level=1, cracky=3, hanging_node=1},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("chains:bronze_chandelier", {
	description = "Bronze Chandelier",
	paramtype = "light",
	light_source = default.LIGHT_MAX-3,
	walkable = false,
	climbable = true,
	sunlight_propagates = true,
	paramtype = "light",
	tiles = {
		"chains_bronze.png",
		"chains_candle.png",
		{
			name="chains_flame.png",
			animation={
				type="vertical_frames",
				aspect_w=16,
				aspect_h=16,
				length=3.0
			}
		}
	},
	drawtype = "mesh",
	mesh = "chains_chandelier.obj",
	groups = {level=1, cracky=3, hanging_node=1},
	sounds = default.node_sound_metal_defaults(),
})

-- crafts

minetest.register_craft({
	output = 'chains:iron_chain 3',
	recipe = {
		{'default:steel_ingot'},
		{'default:steel_ingot'},
		{'default:steel_ingot'},
	}
})

minetest.register_craft({
	output = 'chains:iron_chain_top',
	recipe = {
		{'default:steel_ingot'},
		{'chains:iron_chain'},
	},
})

minetest.register_craft({
	output = 'chains:iron_chandelier',
	recipe = {
		{'', 'chains:iron_chain', ''},
		{'group:torch_craftitem', 'chains:iron_chain', 'group:torch_craftitem'},
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
	}
})

minetest.register_craft({
	output = 'chains:bronze_chain 3',
	recipe = {
		{'default:bronze_ingot'},
		{'default:bronze_ingot'},
		{'default:bronze_ingot'},
	}
})

minetest.register_craft({
	output = 'chains:bronze_chain_top',
	recipe = {
		{'default:bronze_ingot'},
		{'chains:bronze_chain'},
	},
})

minetest.register_craft({
	output = 'chains:bronze_chandelier',
	recipe = {
		{'', 'chains:bronze_chain', ''},
		{'group:torch_craftitem', 'chains:bronze_chain', 'group:torch_craftitem'},
		{'default:bronze_ingot', 'default:bronze_ingot', 'default:bronze_ingot'},
	}
})
