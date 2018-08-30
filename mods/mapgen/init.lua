
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
        mapgen.generate_dry_shrubs	(minp, maxp, seed)
        mapgen.generate_papyrus	(minp, maxp, seed)
        mapgen.generate_grass		(minp, maxp, seed)
    end)

    if minetest.get_modpath("flowers") then
        minetest.register_on_generated(function(minp, maxp, seed)
            mapgen.generate_flowers	(minp, maxp, seed)
            mapgen.generate_mushrooms	(minp, maxp, seed)
        end)
    end

    mapgen.files_registered = true
end


