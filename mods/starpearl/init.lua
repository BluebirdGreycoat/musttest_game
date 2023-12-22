
if not minetest.global_exists("starpearl") then starpearl = {} end
starpearl.modpath = minetest.get_modpath("starpearl")



if not starpearl.run_once then
	minetest.register_craftitem("starpearl:pearl", {
		description = "Star Pearl",
		inventory_image = "starpearl_pearl.png",
	})

  local c = "starpearl:core"
  local f = starpearl.modpath .. "/init.lua"
  reload.register_file(c, f, false)

  starpearl.run_once = true
end

