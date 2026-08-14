
if not minetest.global_exists("scaffolding") then scaffolding = {} end
scaffolding.modpath = minetest.get_modpath("scaffolding")
reload.install_simple_signals(scaffolding)

dofile(scaffolding.modpath .. "/sort.lua")

if not scaffolding.run_once then
	dofile(scaffolding.modpath .. "/functions.lua")
	dofile(scaffolding.modpath .. "/nodes.lua")
	dofile(scaffolding.modpath .. "/crafts.lua")

	minetest.register_craftitem("scaffolding:scaffolding_wrench", {
		description = "Scaffolding Reinforcement & Chest Sorting Wrench",
		inventory_image = "scaffolding_wrench.png",
		stack_max = 1,

		on_use = function(...)
			return scaffolding.wrench_on_use(...)
		end,
	})

	local c = "scaffolding:core"
	local f = scaffolding.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	scaffolding.run_once = true
end


