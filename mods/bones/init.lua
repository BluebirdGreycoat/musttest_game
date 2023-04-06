-- Minetest 0.4 mod: bones
-- See README.txt for licensing and other information.

if not minetest.global_exists("bones") then bones = {} end



local modpath = minetest.get_modpath("bones")
reload.register_file("bones:msg", modpath .. "/message.lua")
reload.register_file("bones:functions", modpath .. "/functions.lua")
reload.register_file("bones:hack", modpath .. "/nohack.lua")



minetest.register_node("bones:bones_type2", {
	description = "Bones (Filthy)",
	tiles = {
		"bones_top.png^[transform2",
		"bones_bottom.png",
		"bones_side.png",
		"bones_side.png",
		"bones_rear.png",
		"bones_front.png"
	},
	paramtype2 = "facedir",

	groups = utility.dig_groups("bigitem", {
    bones = 1,
    falling_node = 1,

		-- Enables mob bones to burn up in lava eventually.
		flammable = 1,
  }),
    --damage_per_second = 2,

	sounds = default.node_sound_gravel_defaults(),
})



minetest.register_node("bones:bones", {
	description = "Bones (Filthy)",
	tiles = {
		"bones_top.png^[transform2",
		"bones_bottom.png",
		"bones_side.png",
		"bones_side.png",
		"bones_rear.png",
		"bones_front.png"
	},
	paramtype2 = "facedir",
    drop = "bones:bones_type2",

	groups = utility.dig_groups("bigitem", {immovable = 1}),

	sounds = default.node_sound_gravel_defaults(),

	can_dig = function(...) return bones.can_dig(...) end,
	allow_metadata_inventory_move = function(...) return bones.allow_metadata_inventory_move(...) end,
	allow_metadata_inventory_put = function(...) return bones.allow_metadata_inventory_put(...) end,
	allow_metadata_inventory_take = function(...) return bones.allow_metadata_inventory_take(...) end,
	on_metadata_inventory_take = function(...) return bones.on_metadata_inventory_take(...) end,
	on_punch = function(...) return bones.on_punch(...) end,
	on_timer = function(...) return bones.on_timer(...) end,
	on_blast = function(...) return bones.on_blast(...) end,
	on_destruct = function(...) return bones.on_destruct(...) end,
	on_rightclick = function(...) return bones.on_rightclick(...) end,
})



minetest.register_on_dieplayer(function(...) return bones.on_dieplayer(...) end)
minetest.register_on_dieplayer(function(...) return bones.nohack.on_dieplayer(...) end)
minetest.register_on_respawnplayer(function(...) return bones.nohack.on_respawnplayer(...) end)
minetest.register_on_leaveplayer(function(...) return bones.kill_bully_on_leaveplayer(...) end)




