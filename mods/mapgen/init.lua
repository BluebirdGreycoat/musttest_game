
-- Start fresh.
-- Any mods wishing to register additional ores must run after this one.
minetest.clear_registered_ores()
minetest.clear_registered_biomes()
minetest.clear_registered_decorations()

mapgen = mapgen or {}
mapgen.modpath = minetest.get_modpath("mapgen")

local reload_or_dofile = function(name, path)
	if minetest.get_modpath("reload") then
		reload.register_file(name, path)
	else
		dofile(path)
	end
end

if not minetest.is_singleplayer() then
	if not mapgen.chat_registered then
		-- Set up vars.
		mapgen.report_time = mapgen.report_time or 0
		mapgen.report_chunks = mapgen.report_chunks or 0

		local function notify_chat(minp, maxp, seed)
			local time = os.time() -- Time since epoc in seconds.
			if (time - mapgen.report_time) > 60 and mapgen.report_chunks > 0 then
				minetest.chat_send_all(
					"# Server: Mapgen working, expect lag. (Chunks: " ..
					mapgen.report_chunks .. ".)")

				mapgen.report_time = time
				mapgen.report_chunks = 0
			end
			mapgen.report_chunks = mapgen.report_chunks + 1
		end

		-- Inform players periodically.
		minetest.register_on_generated(notify_chat)

		mapgen.chat_registered = true
	end
end

if not mapgen.files_registered then
	local mp = mapgen.modpath

	-- These files are reloadable. Their functions can be changed at runtime.
	reload_or_dofile("mapgen:shrubs",	    mp .. "/shrubs.lua")
	reload_or_dofile("mapgen:papyrus",		mp .. "/papyrus.lua")
	reload_or_dofile("mapgen:grass",		mp .. "/grass.lua")

	if minetest.get_modpath("flowers") then
			reload_or_dofile("mapgen:flowers",		mp .. "/flowers.lua")
			reload_or_dofile("mapgen:mushrooms",	mp .. "/mushrooms.lua")
	end

	-- Ore and biome registration.
	dofile(mp .. "/mg_alias.lua")
	dofile(mp .. "/mapgen.lua")
	dofile(mp .. "/biome.lua")

	minetest.register_on_generated(function(minp, maxp, seed)
		mapgen.generate_dry_shrubs(minp, maxp, seed)
		mapgen.generate_papyrus(minp, maxp, seed)
		mapgen.generate_grass(minp, maxp, seed)
	end)

	if minetest.get_modpath("flowers") then
		minetest.register_on_generated(function(minp, maxp, seed)
			mapgen.generate_flowers(minp, maxp, seed)
			mapgen.generate_mushrooms(minp, maxp, seed)
		end)
	end

	mapgen.files_registered = true
end


