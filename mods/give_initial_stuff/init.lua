
if not minetest.global_exists("give_initial_stuff") then give_initial_stuff = {} end
give_initial_stuff.modpath = minetest.get_modpath("give_initial_stuff")
give_initial_stuff.items = give_initial_stuff.items or {}

-- Start items are hardcoded intentionally. The Outback (where new players
-- start on first join) depends on this.
--
-- Purpose of items:
--   1) wood pick: signals that you're a noob.
--   2) mutton: signals that this isn't a vegan server.
--   3) torches: signals that you're expected to go mining where it's dark.
--   4) tinderbox: signals that you're gonna need to scavenge lights.
--   5) calendar: signals this server has seasons.
--   6) flint/steel: your purpose in life is to light trees on fire. Also, your trash. And your pet.
--   7) compass: signals an element of adventure/exploration.
--   8) sapling: for the times when chaos has wrecked everything.
--
-- Update: sadly the flint had to be removed (replaced with apples).
-- Seems some trolls took the purpose of their life a little too seriously.
local stuff_string =
	"default:pick_wood,mobs:meat_mutton 10,default:apple 10,torches:torch_floor 10," ..
	"tinderbox:tinderbox,clock:calendar,default:compass,default:sapling"

-- This is also called when a Survival Challenge is started.
function give_initial_stuff.give(player)
	local inv = player:get_inventory()
	for _, stack in ipairs(give_initial_stuff.items) do
		inv:add_item("main", stack)
	end
end

function give_initial_stuff.add(stack)
	give_initial_stuff.items[#give_initial_stuff.items + 1] = ItemStack(stack)
end

function give_initial_stuff.clear()
	give_initial_stuff.items = {}
end

function give_initial_stuff.add_from_csv(str)
	local items = str:split(",")
	for _, itemname in ipairs(items) do
		give_initial_stuff.add(itemname)
	end
end

function give_initial_stuff.set_list(list)
	give_initial_stuff.items = list
end

function give_initial_stuff.get_list()
	return give_initial_stuff.items
end

if not give_initial_stuff.registered then
	give_initial_stuff.add_from_csv(stuff_string)

	-- Initial stuff is always given to a new player regardless of server configuration.
	minetest.register_on_newplayer(function(...)
		give_initial_stuff.give(...)
	end)

	local c = "give_initial_stuff:core"
	local f = give_initial_stuff.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	give_initial_stuff.registered = true
end
