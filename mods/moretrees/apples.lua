
if not minetest.global_exists("moretrees") then moretrees = {} end

minetest.register_node("moretrees:apple_tree_blossoms", {
	description = "Apple Tree Blossoms",
	drawtype = "allfaces_optional",

	tiles = {"moretrees_apple_tree_leaves.png^moretrees_apple_tree_blossoms.png"},
	paramtype = "light",
	waving = 1,
	is_ground_content = false,
	groups = utility.dig_groups("leaves", {leafdecay = 3, flammable = 2, leaves = 1}),
	drop = moretrees.get_leafdrop_table(7, "moretrees:apple_tree_sapling", "moretrees:apple_tree_leaves"),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,

  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="moretrees:apple_tree_tree"}),
})
