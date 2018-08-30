
minetest.register_craftitem("silicon:wafer", {
  description = "Silicon Wafer",
  inventory_image = "technic_silicon_wafer.png",
})

minetest.register_craftitem("silicon:doped_wafer", {
  description = "Doped Silicon Wafer",
  inventory_image = "technic_doped_silicon_wafer.png",
})

dofile(minetest.get_modpath("silicon") .. "/chainsaw.lua")
dofile(minetest.get_modpath("silicon") .. "/rockdrill.lua")
dofile(minetest.get_modpath("silicon") .. "/screwdriver.lua")
dofile(minetest.get_modpath("silicon") .. "/prospector.lua")

