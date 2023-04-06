
if not minetest.global_exists("starpearl") then starpearl = {} end
starpearl.modpath = minetest.get_modpath("starpearl")



minetest.register_craftitem("starpearl:pearl", {
	description = "Star Pearl",
	inventory_image = "starpearl_pearl.png",
})
