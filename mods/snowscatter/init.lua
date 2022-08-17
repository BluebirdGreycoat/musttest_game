
snowscatter = snowscatter or {}
snowscatter.modpath = minetest.get_modpath("snowscatter")

-- Localize for performance.
local vector_round = vector.round
local math_random = math.random



local find_floor = function(x, ybot, ytop, z)
    for y = ytop, ybot, -1 do
        local p1 = {x=x, y=y, z=z}
        local p2 = {x=x, y=y-1, z=z}
        
        local n1 = minetest.get_node(p1).name
        local n2 = minetest.get_node(p2).name
        
        if n1 == "air" and n2 ~= "air" and n2 ~= "ignore" then
            local node = minetest.reg_ns_nodes[n2]
						if not node then break end
            if not node.walkable then break end -- Don't dump snow on non-walkable things.
            
            local good = false
            local dt = node.drawtype
            if dt == "normal" then good = true end
            if dt == "allfaces" then good = true end
            if dt == "allfaces_optional" then good = true end
            if dt == "glasslike" then good = true end
            if dt == "glasslike_framed" then good = true end
            if dt == "glasslike_framed_optional" then good = true end
            if dt == "airlike" then good = true end
            if good == false then break end
            
            return p1, p2
        elseif n1 == "ignore" or n1 ~= "air" then
            break
        end
    end
end



-- API function which dumps snow dust in an area.
snowscatter.dump_snowdust = function(minp_, maxp_, chance, avoidXZ)
    local minp, maxp = utility.sort_positions(minp_, maxp_)
    local random = math_random
    for x = minp.x, maxp.x, 1 do
        for z = minp.z, maxp.z, 1 do
						-- If avoidance column is specificed, do not place snow in that column.
						local cando = true
						if avoidXZ then
							if x == avoidXZ.x and z == avoidXZ.z then
								cando = false
							end
						end

            if random(1, chance) == 1 and cando == true then
                local p1, p2 = find_floor(x, minp.y, maxp.y, z)
                if p1 then
									if not rc.ice_melts_at_pos(p1) then
                    minetest.set_node(p1, {name="snow:tree"})
                    core.check_for_falling(p1)
									end
                end
            end
        end
    end
end



-- This API is designed to be called by tree mods.
snowscatter.dump_snowdust_on_tree = function(pos, minp, maxp)
    local sminp = {x=pos.x+minp.x, y=pos.y+minp.y, z=pos.z+minp.z}
    local smaxp = {x=pos.x+maxp.x, y=pos.y+maxp.y+1, z=pos.z+maxp.z}
    snowscatter.dump_snowdust(sminp, smaxp, math_random(5, 20), {x=pos.x, z=pos.z})
end



snowscatter.execute_chatcommand = function(name, param)
    local p = vector_round(minetest.get_player_by_name(name):get_pos())
    local r = 10
    snowscatter.dump_snowdust({x=p.x-r, y=p.y-r, z=p.z-r}, {x=p.x+r, y=p.y+r, z=p.z+r}, 5, nil)
    minetest.chat_send_player(name, "# Server: Scattered snow!")
    return true
end



if not snowscatter.registered then
    minetest.register_privilege("snowscatter", {
        "Player can scatter snow in area around self.",
        give_to_singleplayer = false,
    })
    
    minetest.register_chatcommand("snowscatter", {
        params = "",
        description = "Scatter snow around self.",
        privs = {snowscatter=true},
        func = function(...) return snowscatter.execute_chatcommand(...) end,
    })
    
    reload.register_file("snowscatter:core", snowscatter.modpath .. "/init.lua", false)
    snowscatter.registered = true
end



