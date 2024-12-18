
if not minetest.global_exists("stoneworld") then stoneworld = {} end
stoneworld.modpath = minetest.get_modpath("stoneworld")

-- These match values in the realm-control mod.
-- Note: duplicated in the mapgen script, they MUST match!
stoneworld.REALM_START = 5150
stoneworld.REALM_END = 8150



function stoneworld.on_generated(minp, maxp, blockseed)
	local mapgen = minetest.get_mapgen_object("gennotify")
	local data = (mapgen.custom and mapgen.custom["stoneworld:fortress_spawn_location"])
	if not data then return end

	minetest.after(0, function()
		--minetest.chat_send_all('generating fortress at ' .. minetest.pos_to_string(data.pos))
		fortress.generate(data.pos, "default")
	end)
end



function stoneworld.get_ground_y(pos3d)
	return 6500
end



--------------------------------------------------------------------------------
if not stoneworld.registered then
	dofile(stoneworld.modpath .. "/nodes.lua")
	dofile(stoneworld.modpath .. "/ores.lua")
	dofile(stoneworld.modpath .. "/items.lua")

	minetest.set_gen_notify("custom", nil, {"stoneworld:fortress_spawn_location"})
	minetest.register_on_generated(function() stoneworld.on_generated() end)

	minetest.register_mapgen_script(stoneworld.modpath .. "/mapgen.lua")

	local c = "stoneworld:core"
	local f = stoneworld.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	stoneworld.registered = true
end
