
if not minetest.global_exists("ab") then ab = {} end
ab.modpath = minetest.get_modpath("ab")
ab.worldpath = minetest.get_worldpath()

dofile(ab.modpath .. "/ore.lua")



function ab.on_generated(minp, maxp, blockseed)
	local mapgen = minetest.get_mapgen_object("gennotify")
	local data = (mapgen.custom and mapgen.custom["ab:mapgen_info"])
	if not data then return end

	-- This ugly hack is currently the best way I know of to make light correct
	-- after chunk generation.
	if data.need_mapfix then
		minetest.after(math.random(1, 100) / 50, function()
			local emin = vector.add(data.minp, {x=-16, y=-16, z=-16})
			local emax = vector.add(data.maxp, {x=16, y=16, z=16})
			mapfix.work(emin, emax)
		end)
	end
end



if not ab.registered then
	minetest.set_gen_notify("custom", nil, {"ab:mapgen_info"})
	minetest.register_on_generated(function(...)
		ab.on_generated(...)
	end)

	-- Register the mapgen.
	minetest.register_mapgen_script(ab.modpath .. "/mapgen.lua")

	local c = "ab:core"
	local f = ab.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	ab.registered = true
end
