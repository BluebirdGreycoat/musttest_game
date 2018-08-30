
anticurse = {}
anticurse.logpath = minetest.get_worldpath() .. "/cursing.txt"



anticurse.logfile = io.open(anticurse.logpath, "a+")
minetest.register_on_shutdown(function()
	if anticurse.logfile then
		anticurse.logfile:flush()
        anticurse.logfile:close()
	end
end)



-- Make these live-reloadable.
if minetest.get_modpath("reload") then
    local path = minetest.get_modpath("anticurse")
    reload.register_file("anticurse:kick_msg", path .. "/kick_msg.lua")
    reload.register_file("anticurse:foul_db", path .. "/bad-language.lua")
    reload.register_file("anticurse:curse_db", path .. "/other-language.lua")
    reload.register_file("anticurse:core", path .. "/check-string.lua")
    reload.register_file("anticurse:api", path .. "/api.lua")
else
    local path = minetest.get_modpath("anticurse")
    dofile(path .. "/kick_msg.lua")
    dofile(path .. "/bad-language.lua")
    dofile(path .. "/other-language.lua")
    dofile(path .. "/check-string.lua")
    dofile(path .. "/api.lua")
end



minetest.register_privilege("anticurse_bypass", {
    description = "Player's chat will not be scanned for cursing.",
    give_to_singleplayer = true,
})

minetest.register_on_prejoinplayer(function(pname, ip)
	if rename.name_currently_allocated(pname) then
		return "That name is currently allocated by someone else!"
	end
	return anticurse.on_prejoinplayer(pname, ip)
end)


