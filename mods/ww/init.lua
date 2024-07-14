
if not minetest.global_exists("ww") then ww = {} end
ww.modpath = minetest.get_modpath("ww")
ww.worldpath = minetest.get_worldpath()



function ww.on_generated(minp, maxp, blockseed)
	local mapgen = minetest.get_mapgen_object("gennotify")
	local data = (mapgen.custom and mapgen.custom["ww:mapgen_info"])
	if not data then return end

	-- This ugly hack is currently the best way I know of to make light correct
	-- after chunk generation.
	minetest.after(math.random(1, 100) / 50, function()
		local emin = vector.add(data.minp, {x=-16, y=-16, z=-16})
		local emax = vector.add(data.maxp, {x=16, y=16, z=16})
		mapfix.work(emin, emax)
	end)
end



if not ww.registered then
	minetest.set_gen_notify("custom", nil, {"ww:mapgen_info"})
	minetest.register_on_generated(function(...)
		ww.on_generated(...)
	end)

	-- Register the mapgen.
	minetest.register_mapgen_script(ww.modpath .. "/mapgen.lua")

	local c = "ww:core"
	local f = ww.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	ww.registered = true
end
