
redshroom = redshroom or {}
redshroom.modpath = minetest.get_modpath("redshroom")



local SHROOM_SCHEMATICS = {
    "redshroom_shroom1.mts",
    "redshroom_shroom2.mts",
    "redshroom_shroom3.mts",
    "redshroom_shroom4.mts",
    "redshroom_shroom5.mts",
    "redshroom_shroom6.mts",
}



minetest.register_node("redshroom:head", {
	description = "Red Shroom Head",
	tiles = {"redshroom_headtop.png", "redshroom_headtop.png", "redshroom_headside1.png^redshroom_headside2.png"},
	paramtype2 = "facedir",
	groups = {level=1, snappy=3, choppy=3, oddly_breakable_by_hand=1, flammable=2},
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node
})



minetest.register_node("redshroom:head2", {
	description = "Red Shroom Head",
	tiles = {"redshroom_headtop.png", "redshroom_headtop.png", "redshroom_headside1.png"},
	paramtype2 = "facedir",
	groups = {level=1, snappy=3, choppy=3, oddly_breakable_by_hand=1, flammable=2},
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node
})



minetest.register_node("redshroom:stem", {
	description = "Red Shroom Stem",
	tiles = {"redshroom_stemtop.png", "redshroom_stemtop.png", "redshroom_stemside.png"},
	paramtype2 = "facedir",
	groups = {level=1, snappy=1, choppy=2, flammable=2},
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node
})

minetest.register_craft({
  type = "shapeless",
  output = "default:stick 16",
  recipe = {"redshroom:stem"},
})



minetest.register_node("redshroom:stemwhite", {
	description = "White Shroom Stem",
	tiles = {"redshroom_stemtop_white.png", "redshroom_stemtop_white.png", "redshroom_stemside_white.png"},
	paramtype2 = "facedir",
	groups = {level=1, snappy=1, choppy=2, flammable=2},
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node
})

minetest.register_craft({
  type = "shapeless",
  output = "default:stick 16",
  recipe = {"redshroom:stemwhite"},
})



minetest.register_node("redshroom:gills", {
	description = "Shroom Gills",
	drawtype = "plantlike",
	tiles = {"redshroom_gills.png"},
	paramtype = "light",
	groups = {level=1, snappy=3, choppy=3, dig_immediate=2, flammable=2, hanging_node=1},
	drop = "", -- Gills are destroyed when dug.
    walkable = false,
    buildable_to = true,
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-0.5, 5/16, -0.5, 0.5, 0.5, 0.5},
	},
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
})



redshroom.create_shroom_on_vmanip = function(vm, pos)
    local schempath = redshroom.modpath .. "/schematics/"
    local path = schempath .. SHROOM_SCHEMATICS[math.random(#SHROOM_SCHEMATICS)]
    minetest.place_schematic_on_vmanip(vm, vector.add(pos, {x=-2, y=0, z=-2}), path, "random", nil, false)
end



redshroom.create_shroom = function(pos)
    local schempath = redshroom.modpath .. "/schematics/"
    local path = schempath .. SHROOM_SCHEMATICS[math.random(#SHROOM_SCHEMATICS)]
    minetest.place_schematic(vector.add(pos, {x=-2, y=0, z=-2}), path, "random", nil, false)
end
