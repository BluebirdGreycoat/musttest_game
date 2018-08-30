
mossgrowth = mossgrowth or {}
mossgrowth.modpath = minetest.get_modpath("mossgrowth")



-- Moss growth on cobble near water.
-- This ABM is now PERMANENTLY disabled.
-- Profiling showed it to take too much CPU time.
--[[
minetest.register_abm({
	nodenames = {
    "default:cobble",
    "stairs:slab_cobble",
    "stairs:stair_cobble",
    "walls:cobble",
  },
	neighbors = {"group:water"},
	interval = 40 * default.ABM_TIMER_MULTIPLIER,
	chance = 200 * default.ABM_CHANCE_MULTIPLIER,
	catch_up = false,
	action = function(pos, node)
		-- Require a nearby air node and a torch node (MustTest).
		local torch = minetest.find_node_near(pos, 3, 'group:torch')
		local air = minetest.find_node_near(pos, 2, 'air')
		if not (air and torch) then return end

		if node.name == "default:cobble" then
			minetest.set_node(pos, {name = "default:mossycobble"})
		elseif node.name == "stairs:slab_cobble" then
			minetest.set_node(pos, {name = "stairs:slab_mossycobble", param2 = node.param2})
		elseif node.name == "stairs:stair_cobble" then
			minetest.set_node(pos, {name = "stairs:stair_mossycobble", param2 = node.param2})
    elseif node.name == "walls:cobble" then
			minetest.set_node(pos, {name = "walls:mossycobble", param2 = node.param2})
		end
	end
})
--]]


