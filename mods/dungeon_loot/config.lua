-- "Dungeon Loot" [dungeon_loot]
-- Original by BlockMen, this entire file by Amoeba
--
-- config.lua
--
-- Note: All positive heights (above water level) are treated as depth 0.
-- Also, no comma after the item of a list.

-- Minimum number of rooms a dungeon should have for a chest to be generated
dungeon_loot.min_num_of_rooms = 4
-- Items on basic lists have three depth ranges for their listed amount 
-- maximums; they get max/2 before first increase point (minimum of 1 if 
-- amount is >0), the given max between the 1st and 2nd increase point, 
-- and max*2 after the 2nd.
dungeon_loot.depth_first_basic_increase = 200
dungeon_loot.depth_second_basic_increase = 2000

-- Nodes dungeons are made out of.
dungeon_loot.DUNGEON_NODES = {
	"default:stone",
	"default:cobble",
	"default:mossycobble",
	"default:desert_stone",
	"rackstone:brick",
	"rackstone:mg_redrack",
	"rackstone:redrack",
	"rackstone:rackstone",
	"rackstone:mg_rackstone",
}

dungeon_loot.CHEST_NODES = {
	"chests:chest_public_closed",
	"morechests:woodchest_public_closed",
	"morechests:ironchest_public_closed",
}

-- The master list of loot types
-- Note that tools and weapons should always have max_amount = 1.
-- Chance is a probability between 0 (practically never) and 1 (always),
-- so change a chance to 0 if you don't want a type (eg. weapons) included 
-- in your game (or -0.001 if you want to be REALLY sure). 
dungeon_loot.loot_types = { 
	{name="treasure", max_amount = 10, chance = 0.7, type = "depth_cutoff"},
	{name="tools", max_amount = 1, chance = 0.5, type = "depth_cutoff"},
	{name="weapons", max_amount = 1, chance = 0.1, type = "depth_cutoff"},
	{name="bows", max_amount = 1, chance = 0.1, type = "depth_cutoff"},
	{name="consumables", max_amount = 80, chance = 0.9, type = "basic_list"},
	{name="seedlings", max_amount = 5, chance = 0.3, type = "basic_list"},
	{name="metals", max_amount = 20, chance = 0.3, type = "basic_list"},
	{name="supplies", max_amount = 20, chance = 0.3, type = "basic_list"},
}

-- Loot type lists; these names MUST be exactly of the format:
-- "dungeon_loot.name_list" where "name" is in the above list

-- Depth cutoff lists
-- These must be in order of increasing depth (but can include the same item
-- more than once).  Method: a random number between 1 and chest depth is 
-- chosen, and the item in that range is added to the loot.  Then, there's 
-- a chance additional items of the same type are added to stack; if the 
-- random number is much greater than the item's min_depth, the amount 
-- can grow pretty big.
dungeon_loot.treasure_list = {
	{name="default:steel_ingot", min_depth = 0},
	{name="default:bronze_ingot", min_depth = 20},
	{name="default:gold_ingot", min_depth = 45},
	{name="default:mese_crystal", min_depth = 50},
	{name="default:diamond", min_depth = 150},
	{name="default:goldblock", min_depth = 777},
	{name="default:mese", min_depth = 800},
	{name="default:diamondblock", min_depth = 1800},
	{name="default:mese", min_depth = 2000},
}

dungeon_loot.tools_list = {
	{name="default:pick_steel", min_depth = 0},
	{name="default:shovel_diamond", min_depth = 38},
	{name="default:pick_bronze", min_depth = 40},
	{name="default:axe_diamond", min_depth = 95},
	{name="default:pick_diamond", min_depth = 100},
	{name="bucket:bucket_water", min_depth = 100},
}

dungeon_loot.weapons_list = {
	{name="default:sword_steel", min_depth = 0},
	{name="default:sword_bronze", min_depth = 50},
	{name="default:sword_mese", min_depth = 150},
	{name="default:sword_diamond", min_depth = 250}
}

dungeon_loot.bows_list = {
	{name="throwing:bow_wood", min_depth = 0},
	{name="throwing:longbow", min_depth = 50},
	{name="throwing:bow_composite", min_depth = 150},
	{name="throwing:bow_steel", min_depth = 250},
	{name="throwing:crossbow", min_depth = 500},
	{name="throwing:arbalest", min_depth = 1500},
	{name="throwing:bow_royal", min_depth = 25000},
}


-- Basic lists
-- These can be of two types, either with combined chance and amount, 
-- or with the two variables separated.  "chance" means each item has a 
-- N/M chance of being chosen, where N is it's own chance and M is the 
-- total sum of chances on the list.  "amount" is the maximum amount of
-- items given at the middle depth range.
dungeon_loot.consumables_list = {
	{name="basictrees:tree_apple", chance_and_amount = 20},
	{name="default:torch", chance_and_amount = 30},
	{name="default:stick", chance_and_amount = 10},
	{name="mobs:meat_raw", chance_and_amount = 10},
	{name="mobs:meat_raw_mutton", chance_and_amount = 10},
}

dungeon_loot.seedlings_list = {
	{name="basictrees:tree_sapling", chance = 5, amount = 2},
	{name="basictrees:pine_sapling", chance = 10, amount = 2},
	{name="basictrees:jungletree_sapling", chance = 15, amount = 2},
	{name="basictrees:acacia_sapling", chance = 15, amount = 2}
}

dungeon_loot.metals_list = {
	{name="default:steel_ingot", chance = 10, amount = 10},
	{name="zinc:ingot", chance = 5, amount = 10},
	{name="chromium:ingot", chance = 5, amount = 10},
	{name="default:copper_ingot", chance = 5, amount = 10},
	{name="titanium:crystal", chance = 5, amount = 10},
}

dungeon_loot.supplies_list = {
	{name="mobs:leather", chance = 5, amount = 10},
	{name="mobs:leather_padding", chance = 5, amount = 3},
	{name="farming:string", chance = 5, amount = 10},
	{name="mobs:flame_bolt", chance = 5, amount = 10},
	{name="tnt:gunpowder", chance = 5, amount = 10},
}

-- Add items from other mods here inside the appropriate 
-- "if ... then ... end" test
-- For basic lists, just using insert without a value works fine.
-- For depth cutoff lists, you can use insert with a table index, eg.
--   table.insert(dungeon_loot.treasure_list, 5, {name="your_mod:platinum_ingot", min_depth = 120}
-- The above would add a new item to the treasure list as the 5th item,
-- moving diamond and all below it one down in the list.  Just make sure 
-- that the increasing min_depth order is kept.  
-- Tips: With multiple insertions in a depth cutoff list, start from the 
-- last item and work towards the beginning, then you don't have to calculate
-- your number of additions.  Also, trying to make sure too many different 
-- mods work together in a single list will probably give you a headache;
-- just create a new list (or two) for mods with lots of additions. 

if minetest.get_modpath("farming") then
 	table.insert(dungeon_loot.consumables_list, {name="farming:bread", chance_and_amount = 10})
 	table.insert(dungeon_loot.seedlings_list, {name="farming:seed_wheat", chance = 1, amount = 10})
 	table.insert(dungeon_loot.seedlings_list, {name="farming:seed_cotton", chance = 20, amount = 5})
end
