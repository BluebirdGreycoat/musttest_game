
if not minetest.global_exists("pd") then pd = {} end
pd.modpath = minetest.get_modpath("pd")
pd.worldpath = minetest.get_worldpath()



function pd.on_generated(minp, maxp, blockseed)
	local mapgen = minetest.get_mapgen_object("gennotify")
	local data = (mapgen.custom and mapgen.custom["pd:mapgen_info"])
	if not data then return end

	-- This ugly hack is currently the best way I know of to make light correct
	-- after chunk generation.
	minetest.after(math.random(1, 100) / 50, function()
		local emin = vector.add(data.minp, {x=-16, y=-16, z=-16})
		local emax = vector.add(data.maxp, {x=16, y=16, z=16})
		mapfix.work(emin, emax)
	end)
end



if not pd.registered then
	minetest.set_gen_notify("custom", nil, {"pd:mapgen_info"})
	minetest.register_on_generated(function(...)
		pd.on_generated(...)
	end)

	-- Register the mapgen.
	minetest.register_mapgen_script(pd.modpath .. "/mapgen.lua")

	local c = "pd:core"
	local f = pd.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	pd.registered = true
end
