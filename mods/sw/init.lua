
if not minetest.global_exists("sw") then sw = {} end
sw.modpath = minetest.get_modpath("sw")
sw.worldpath = minetest.get_worldpath()



function sw.on_generated(minp, maxp, blockseed)
	local mapgen = minetest.get_mapgen_object("gennotify")
	local data = (mapgen.custom and mapgen.custom["sw:mapgen_info"])
	if not data then return end

	-- This ugly hack is currently the best way I know of to make light correct
	-- after chunk generation.
	minetest.after(math.random(1, 100) / 50, function()
		local emin = vector.add(data.minp, {x=-16, y=-16, z=-16})
		local emax = vector.add(data.maxp, {x=16, y=16, z=16})
		mapfix.work(emin, emax)
	end)
end



if not sw.registered then
	minetest.set_gen_notify("custom", nil, {"sw:mapgen_info"})
	minetest.register_on_generated(function(...)
		sw.on_generated(...)
	end)

	-- Register the mapgen.
	minetest.register_mapgen_script(sw.modpath .. "/mapgen.lua")

	local c = "sw:core"
	local f = sw.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	sw.registered = true
end
