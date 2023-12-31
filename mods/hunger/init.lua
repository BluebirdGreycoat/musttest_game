
if not minetest.global_exists("hunger") then hunger = {} end
hunger.modpath = minetest.get_modpath("hunger")
hunger.players = hunger.players or {}
hunger.food = hunger.food or {}



HUNGER_TICK = 60         -- time in seconds after that 1 hunger point is taken
HUNGER_HEALTH_TICK = 10  -- time in seconds after player gets healed/damaged
HUNGER_MOVE_TICK = 2     -- time in seconds after the movement is checked

HUNGER_EXHAUST_DIG = 5   -- exhaustion increased this value after digged node
HUNGER_EXHAUST_PLACE = 4 -- exhaustion increased this value after placed
HUNGER_EXHAUST_MOVE = 0.5 -- exhaustion increased this value if player movement detected
HUNGER_EXHAUST_LVL = 150 -- at what exhaustion player saturation gets lowered

HUNGER_HEAL = 0.05       -- percentage of HP player gets healed after HUNGER_HEALTH_TICK
HUNGER_HEAL_LVL = 15     -- lower level of saturation needed to get healed
HUNGER_STARVE = 0.05     -- percentage of HP player gets damaged by hunger after HUNGER_HEALTH_TICK
HUNGER_STARVE_LVL = 4    -- level of staturation that causes starving

HUNGER_MAX = 30          -- maximum level of saturation



dofile(hunger.modpath .. "/functions.lua")
dofile(hunger.modpath .. "/hp_boost.lua")
dofile(hunger.modpath .. "/hp_regen_boost.lua")
dofile(hunger.modpath .. "/sta_regen_boost.lua")
dofile(hunger.modpath .. "/resistance.lua")
dofile(hunger.modpath .. "/hot.lua")
dofile(hunger.modpath .. "/diet.lua")

-- Putting this inside minetest.after() avoids having to declare dependencies.
minetest.after(0, function()
	dofile(hunger.modpath .. "/food.lua")
end)



if not hunger.run_once then
	hunger.run_once = true

	core.do_item_eat = function(...) return hunger.do_item_eat(...) end

	-- Public API function, to be used in place of 'minetest.item_eat' where needed.
	function hunger.item_eat(...) return hunger.item_eat2(...) end

	minetest.register_on_joinplayer(function(...) return hunger.on_joinplayer(...) end)
	minetest.register_on_respawnplayer(function(...) return hunger.on_respawnplayer(...) end)
	minetest.register_on_leaveplayer(function(...) return hunger.on_leaveplayer(...) end)
	minetest.register_on_placenode(function(...) return hunger.on_placenode(...) end)
	minetest.register_on_dignode(function(...) return hunger.on_dignode(...) end)
	minetest.register_globalstep(function(...) return hunger.on_globalstep(...) end)
	minetest.register_on_dieplayer(function(...) return hunger.on_dieplayer(...) end)

	local c = "hunger:core"
	local f = hunger.modpath .. "/init.lua"
	reload.register_file(c, f, false)
end
