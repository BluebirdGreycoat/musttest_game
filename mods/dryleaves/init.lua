
dryleaves = dryleaves or {}
dryleaves.modpath = minetest.get_modpath("dryleaves")



minetest.register_node("dryleaves:leaves", {
	description = "Dried Leaves",
	drawtype = "allfaces_optional",
	waving = 1,

	tiles = {"dryleaves_leaves.png"},
	paramtype = "light",
	groups = utility.dig_groups("leaves", {leafdecay = 3, flammable = 3, leaves = 1, dry_leaves = 1}),
	sounds = default.node_sound_leaves_defaults(),
  
  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({}),
})



minetest.register_node("dryleaves:jungleleaves", {
	description = "Damp Old Leaves",
	drawtype = "allfaces_optional",
	waving = 1,

	tiles = {"dryleaves_jungleleaves.png"},
	paramtype = "light",
	groups = utility.dig_groups("leaves", {leafdecay = 3, flammable = 3, leaves = 1, dry_leaves = 1}),
	sounds = default.node_sound_leaves_defaults(),
  
  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({}),
})



minetest.register_node("dryleaves:dry_leaves", {
	description = "Dry Jungle Leaves",
	tiles = {"darkage_dry_leaves.png"},
	paramtype = "light",
	groups = utility.dig_groups("leaves", {leafdecay = 3, flammable = 3, leaves = 1, dry_leaves = 1}),
	sounds = default.node_sound_leaves_defaults(),

	on_construct = enhanced_leafdecay.make_leaf_constructor({}),
	on_timer = enhanced_leafdecay.make_leaf_nodetimer({}),
})



minetest.register_craft({
	output = "dryleaves:jungleleaves",
	type = "shapeless",
	recipe = {"default:snow", "group:green_leaves"},
})



minetest.register_craft({
	type = "cooking",
	output = "dryleaves:leaves",
	recipe = "basictrees:tree_leaves",
	cooktime = 1,
})



minetest.register_craft({
	type = "cooking",
	output = "dryleaves:dry_leaves",
	recipe = "basictrees:jungletree_leaves",
	cooktime = 1,
})





