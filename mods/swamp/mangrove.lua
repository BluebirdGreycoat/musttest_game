
minetest.register_node("swamp:mangrove_tree", {
	description = "Mangrove Trunk",
	tiles = {"swamp_mangrove_tree_top.png", "swamp_mangrove_tree_top.png",
		"swamp_mangrove_tree.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {tree = 1, choppy = 3, oddly_breakable_by_hand = 1, flammable = 3},
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node
})

minetest.register_node("swamp:mangrove_leaves", {
	description = "Mangrove Leaves",
	drawtype = "allfaces_optional",
	tiles = {"swamp_mangrove_leaves.png"},
	waving = 1,
	paramtype = "light",
	is_ground_content = false,
	groups = {snappy = 3, leafdecay = 3, flammable = 2, leaves = 1},
	drop = {
		max_items = 1,
		items = {
			{items = {"swamp:mangrove_sapling"}, rarity = 20},
			{items = {"swamp:mangrove_leaves"}}
		}
	},
	sounds = default.node_sound_leaves_defaults(),
	after_place_node = default.after_place_leaves,
})

function swamp.grow_new_mangrove_sapling(pos)
	if not default.can_grow(pos) then
		-- try a bit later again
		minetest.get_node_timer(pos):start(math.random(150, 300))
		return
	end
	minetest.remove_node(pos)
	minetest.place_schematic({x = pos.x-2, y = pos.y, z = pos.z-3},
		MODPATH .. "/schematics/mangrove_tree_1.mts",
		"random", nil, false)
end

minetest.register_node("swamp:mangrove_sapling", {
	description = "Mangrove Sapling",
	drawtype = "plantlike",
	tiles = {"swamp_mangrove_sapling.png"},
	inventory_image = "swamp_mangrove_sapling.png",
	wield_image = "swamp_mangrove_sapling.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	on_timer = swamp.grow_new_mangrove_sapling,
	selection_box = {
		type = "fixed",
		fixed = {-4 / 16, -0.5, -4 / 16, 4 / 16, 7 / 16, 4 / 16}
	},
	groups = {snappy = 2, dig_immediate = 3, flammable = 2,
		attached_node = 1, sapling = 1},
	sounds = default.node_sound_leaves_defaults(),

	on_construct = function(pos)
		minetest.get_node_timer(pos):start(math.random(300, 1500))
	end,

	on_place = function(itemstack, placer, pointed_thing)
		itemstack = default.sapling_on_place(itemstack, placer, pointed_thing,
			"swamp:mangrove_sapling",
			-- minp, maxp to be checked, relative to sapling pos
			-- minp_relative.y = 1 because sapling pos has been checked
			{x = -4, y = 1, z = -4},
			{x = 4, y = 7, z = 4},
			-- maximum interval of interior volume check
			4)

		return itemstack
	end,
})
