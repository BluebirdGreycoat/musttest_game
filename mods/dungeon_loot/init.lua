-- "Dungeon Loot" [dungeon_loot]
-- Copyright (c) 2015 BlockMen <blockmen2015@gmail.com>
--
-- init.lua
--
-- This software is provided 'as-is', without any express or implied warranty. In no
-- event will the authors be held liable for any damages arising from the use of
-- this software.
--
-- Permission is granted to anyone to use this software for any purpose, including
-- commercial applications, and to alter it and redistribute it freely, subject to the
-- following restrictions:
--
-- 1. The origin of this software must not be misrepresented; you must not
-- claim that you wrote the original software. If you use this software in a
-- product, an acknowledgment in the product documentation is required.
-- 2. Altered source versions must be plainly marked as such, and must not
-- be misrepresented as being the original software.
-- 3. This notice may not be removed or altered from any source distribution.
--


-- Following Code (everything before fill_chest) by Amoeba <amoeba@iki.fi>
dungeon_loot = {}
dungeon_loot.version = 1.2

-- Load other file(s)
local modpath = minetest.get_modpath("dungeon_loot")

dofile(modpath .. "/config.lua") 		-- All the constants for simple tuning
dofile(modpath .. "/oerkki.lua")
dofile(modpath .. "/loot.lua")

minetest.set_gen_notify("dungeon")

minetest.register_on_generated(function(minp, maxp, blockseed)
	local ntf = minetest.get_mapgen_object("gennotify")
	if ntf and ntf.dungeon and #ntf.dungeon >= dungeon_loot.min_num_of_rooms then
		-- Have to copy the table, because 'place_spawner' modifies it.
		minetest.after(3, dungeon_loot.place_loot_chest, table.copy(ntf.dungeon))
		minetest.after(3, dungeon_loot.place_oerkki_stones, table.copy(ntf.dungeon))
	end
end)
