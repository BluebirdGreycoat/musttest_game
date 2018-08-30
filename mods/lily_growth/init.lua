
lily_growth = lily_growth or {}
lily_growth.modpath = minetest.get_modpath("lily_growth")




-- Grow water plants.
-- This is no longer needed. Lilies are grow via callbacks+nodetimer.

--minetest.register_abm({
--	nodenames = {'default:water_source'},
--	neighbors = {'air'},
--	interval = 60 * default.ABM_TIMER_MULTIPLIER,
--	chance = 300 * default.ABM_CHANCE_MULTIPLIER,
--	catch_up = false,
--	action = function(pos, node)
--		if minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z}).name == 'air' then
--			local torch = minetest.find_node_near(pos, 2, 'group:torch')
--			if torch then
--				minetest.set_node({x=pos.x, y=pos.y+1, z=pos.z}, {name='flowers:waterlily'})
--			end
--		end
--	end,
--})

