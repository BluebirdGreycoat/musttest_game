--LIGHTS+ 
--updated 12/11/2013
--Mod adding simple on/off lights by qwrwed.

-- License is WTFPL, textures are by VanessaE and paramat, code for flat lights
-- is by LionsDen.

-- Mod updated and made compatible with MustTest, by MustTest.

--Node Definitions and Functions
local lights = {
	{"lightsplus:light", "lightsplus:light_on", "Light", "lightsplus_light.png", "", "", "facedir", ""},
	{"lightsplus:gold_light", "lightsplus:gold_light_on", "Gold Light", "lightsplus_gold_light.png", "", "facedir", "", ""},
	{"lightsplus:slab_light", "lightsplus:slab_light_on", "Slab Light", "lightsplus_light.png", "light", "facedir", "nodebox", {type = "fixed", fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},},},
	{"lightsplus:gold_slab_light", "lightsplus:gold_slab_light_on", "Gold Slab Light", "lightsplus_gold_light.png", "light", "facedir", "nodebox", {type = "fixed", fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},},},
	{"lightsplus:flat_light", "lightsplus:flat_light_on", "Flat Light", "lightsplus_light.png", "light", "facedir", "nodebox", {type = "fixed", fixed = {-0.5, -0.5, -0.5, 0.5, -7/16, 0.5},},},
	{"lightsplus:gold_flat_light", "lightsplus:gold_flat_light_on", "Gold Flat Light", "lightsplus_gold_light.png", "light", "facedir", "nodebox", {type = "fixed", fixed = {-0.5, -0.5, -0.5, 0.5, -7/16, 0.5},},},
}


for _, row in ipairs(lights) do
	local off = row[1]
	local on = row[2]
	local desc = row[3]
	local tiles = row[4]
	local paramtype = row[5]
	local paramtype2 = row[6]
	local drawtype = row[7]
	local nodebox = row[8]

	local dig_group = "glass"
	if off:find("flat") then
		dig_group = "bigitem"
	end

	local light_source = 14

	if off:find("slab") then
		light_source = 12
	elseif off:find("flat") then
		light_source = 8
	end

	minetest.register_node(off, {
		description = desc,
		tiles = { tiles },
		groups = utility.dig_groups(dig_group),
		paramtype = paramtype,
		paramtype2 = paramtype2,
		drawtype = drawtype,
		node_box = nodebox,
		selection_box = nodebox,
		on_punch = function(pos, node, puncher)
			minetest.swap_node(pos, {name=on, param2=node.param2})
		end,
		on_place = minetest.rotate_and_place
	})

	minetest.register_node(on, {
		description = desc .. " (Active)",
		drop = off,
		tiles = { tiles },
		light_source = light_source,
		groups = utility.dig_groups(dig_group, {not_in_creative_inventory=1}),
		paramtype = paramtype,
		paramtype2 = paramtype2,
		drawtype = drawtype,
		node_box = nodebox,
		selection_box = nodebox,
		on_punch = function(pos, node, puncher)
			minetest.swap_node(pos, {name=off, param2=node.param2})
		end,
		on_place = minetest.rotate_and_place
	})
end


--	CRAFTING
--Light
minetest.register_craft({
	output = "lightsplus:light",
	recipe = {
		{'plastic:plastic_sheeting', 'plastic:plastic_sheeting', 'plastic:plastic_sheeting'},
		{'plastic:plastic_sheeting', 'moreblocks:super_glow_glass', 'plastic:plastic_sheeting'},
		{'plastic:plastic_sheeting', 'plastic:plastic_sheeting', 'plastic:plastic_sheeting'},
	}
})

--Gold Light
minetest.register_craft({
	type = "shapeless",
	output = "lightsplus:gold_light",
	recipe = {'lightsplus:light', 'default:gold_ingot'},
})

--Gold Slab Light
minetest.register_craft({
	output = '"lightsplus:gold_slab_light" 6',
	recipe = {
		{'lightsplus:gold_light', 'lightsplus:gold_light', 'lightsplus:gold_light'},
	}
})

--Gold Light from Slabs
minetest.register_craft({
	output = '"lightsplus:gold_light"',
	recipe = {
		{'lightsplus:gold_slab_light'},
		{'lightsplus:gold_slab_light'},
	}
})

--Slab Light
minetest.register_craft({
	output = '"lightsplus:slab_light" 6',
	recipe = {
		{'lightsplus:light', 'lightsplus:light', 'lightsplus:light'},
	}
})

--Light from Slabs
minetest.register_craft({
	output = '"lightsplus:light"',
	recipe = {
		{'lightsplus:slab_light'},
		{'lightsplus:slab_light'},
	}
})

--Flat Light
minetest.register_craft({
	output = '"lightsplus:flat_light" 16',
	recipe = {
		{'lightsplus:light'},
	}
})

--Slab Light from Flat Light
minetest.register_craft({
	type = "shapeless",
	output = "lightsplus:slab_light",
	recipe = {
		'lightsplus:flat_light',
		'lightsplus:flat_light',
		'lightsplus:flat_light',
		'lightsplus:flat_light',
		'lightsplus:flat_light',
		'lightsplus:flat_light',
		'lightsplus:flat_light',
		'lightsplus:flat_light'
	},
})

--Gold Flat Light
minetest.register_craft({
	output = '"lightsplus:gold_flat_light" 16',
	recipe = {
		{'lightsplus:gold_light'},
	}
})

--Gold Slab from Gold Flat Lights
minetest.register_craft({
	type = "shapeless",
	output = "lightsplus:gold_slab_light",
	recipe = {
		'lightsplus:gold_flat_light',
		'lightsplus:gold_flat_light',
		'lightsplus:gold_flat_light',
		'lightsplus:gold_flat_light',
		'lightsplus:gold_flat_light',
		'lightsplus:gold_flat_light',
		'lightsplus:gold_flat_light',
		'lightsplus:gold_flat_light'
	},
})

minetest.register_alias("newlights:light", "lightsplus:light")
minetest.register_alias("newlights:light_on", "lightsplus:light_on")
minetest.register_alias("newlights:slab_light", "lightsplus:flat_light")
minetest.register_alias("newlights:slab_light_on", "lightsplus:flat_light_on")
minetest.register_alias("lightsplus:slab_light_wall", "lightsplus:slab_light")
minetest.register_alias("lightsplus:slab_light_wall_on", "lightsplus:slab_light_on")
minetest.register_alias("lightsplus:slab_light_inv", "lightsplus:slab_light")
minetest.register_alias("lightsplus:slab_light_inv_on", "lightsplus:slab_light_on")
minetest.register_alias("lightsplus:light_gold", "lightsplus:gold_light")
minetest.register_alias("lightsplus:light_on_gold", "lightsplus:gold_light_on")
minetest.register_alias("lightsplus:slab_light_gold", "lightsplus:gold_slab_light")
minetest.register_alias("lightsplus:slab_light_on_gold", "lightsplus:gold_slab_light_on")
minetest.register_alias("lightsplus:slab_light_wall_gold", "lightsplus:gold_slab_light")
minetest.register_alias("lightsplus:slab_light_wall_on_gold", "lightsplus:gold_slab_light_on")
minetest.register_alias("lightsplus:slab_light_inv_gold", "lightsplus:gold_slab_light")
minetest.register_alias("lightsplus:slab_light_inv_on_gold", "lightsplus:gold_slab_light_on")
minetest.register_alias("lightsplus:light_flat", "lightsplus:flat_light")
minetest.register_alias("lightsplus:light_flat_on", "lightsplus:flat_light_on")
minetest.register_alias("lightsplus:light_flat_gold", "lightsplus:gold_flat_light")
minetest.register_alias("lightsplus:light_flat_on_gold", "lightsplus:gold_flat_light_on")
