
dumpnodes = dumpnodes or {}
dumpnodes.modpath = minetest.get_modpath("dumpnodes")



local function nd_get_tiles(nd)
	if nd.tiles then
		return nd.tiles
	elseif nd.tile_images then
		return nd.tile_images
	end
	return nil
end



local function pairs_s(dict)
	local keys = {}
	for k in pairs(dict) do
		table.insert(keys, k)
	end
	table.sort(keys)
	return ipairs(keys)
end



dumpnodes.execute = function(plname, param)
    minetest.chat_send_player(plname, "# Server: Preparing to dump nodes.")
    
    local n = 0
    local ntbl = {}
    
    for _, nn in pairs_s(minetest.registered_nodes) do
        local nd = minetest.registered_nodes[nn]
        local prefix, name = nn:match('(.*):(.*)')
        if prefix == nil or name == nil or prefix == '' or name == '' then
            print("ignored(1): " .. nn)
        else
            if ntbl[prefix] == nil then
                ntbl[prefix] = {}
            end
            ntbl[prefix][name] = nd
        end
    end
    
    local out = io.open(minetest.get_worldpath() .. '/dumpnodes.txt', 'wb')
    if not out then
        minetest.chat_send_player(plname, "# Server: Could not open dumpnodes file.")
				easyvend.sound_error(plname)
        return true
    end
    
    for _, prefix in pairs_s(ntbl) do
        local nodes = ntbl[prefix]
        out:write('# ' .. prefix .. '\n')
        for _, name in pairs_s(nodes) do
            local nd = nodes[name]
            if nd.drawtype ~= 'airlike' and nd_get_tiles(nd) ~= nil then
                local tl = nd_get_tiles(nd)[1]
                if type(tl) == 'table' then
                    tl = tl.name
                end
                tl = (tl .. '^'):match('(.-)^')
                out:write(prefix .. ':' .. name .. ' ' .. tl .. '\n')
                n = n + 1
            else
                print("ignored(2): " .. prefix .. ':' .. name)
            end
        end
        out:write('\n')
    end
    
    out:close()
    minetest.chat_send_player(plname, "# Server: " .. n .. " nodes dumped.")
    return true
end



if not dumpnodes.run_once then
    minetest.register_chatcommand("dumpnodes", {
        params = "",
        description = "",
        privs = {server=true},
        func = function(...) return dumpnodes.execute(...) end,
    })
    
    local name = "dumpnodes:core"
    local file = dumpnodes.modpath .. "/init.lua"
    reload.register_file(name, file, false)
    
    dumpnodes.run_once = true
end




