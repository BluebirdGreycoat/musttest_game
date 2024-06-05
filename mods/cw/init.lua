
-- A Channelwood-like realm. Endless, shallow water in all directions, with
-- trees growing out of the ocean. Trees are huge and extremely tall. Water is
-- dangerious, filled with flesh-eating fish! Trees do not burn (too wet).

if not minetest.global_exists("cw") then cw = {} end
cw.modpath = minetest.get_modpath("cw")
cw.worldpath = minetest.get_worldpath()

-- Tree schems.
if not cw.jungletree_registered then
	dofile(cw.modpath .. "/schems.lua")
	cw.jungletree_registered = true
end

-- Register deadly water.
if not cw.registered then
	dofile(cw.modpath .. "/water.lua")
end



if not cw.registered then
	-- Register the mapgen.
	minetest.register_mapgen_script(cw.modpath .. "/mapgen.lua")

	local c = "cw:core"
	local f = cw.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	cw.registered = true
end
