
teleports = {}
teleports.modpath = minetest.get_modpath("teleports")



-- Support for live reloading.
if minetest.get_modpath("reload") then
    local c = "teleports:core"
    local f = teleports.modpath .. "/functions.lua"
    reload.register_file(c, f)
else
    local f = teleports.modpath .. "/functions.lua"
    dofile(f)
end



dofile(teleports.modpath .. "/nodes.lua")
teleports.load()

