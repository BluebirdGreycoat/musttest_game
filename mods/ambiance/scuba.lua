
-- This file is reloadable.



local done_scuba = function(name)
    if ambiance.players[name] ~= nil then
        ambiance.players[name].scuba = nil
    end
end

local done_splash = function(name)
    if ambiance.players[name] ~= nil then
        ambiance.players[name].hsplash = nil
    end
end



local scuba_timer = 0
local scuba_step = 1
ambiance.globalstep_scuba = function(dtime)
    scuba_timer = scuba_timer + dtime
    if scuba_timer < scuba_step then return end
    scuba_timer = 0
    
    local players = minetest.get_connected_players()
    for k, v in ipairs(players) do
        local pos = v:getpos()
        local name = v:get_player_name()
        local entry = ambiance.players[name]
        
        if entry ~= nil and not gdac.player_is_admin(name) then
            local under = ambiance.check_underwater(pos)
            if under == 2 then
                entry.underwater = true
                if entry.scuba == nil then
                    entry.scuba = minetest.sound_play("scuba", {to_player=name, gain=1.0})
                    minetest.after(8, done_scuba, name)
                end
								ambiance.particles_underwater(pos)
								ambiance.particles_underwater({x=pos.x, y=pos.y+1, z=pos.z})

								sprint.add_stamina(v, -3)
            else
                entry.underwater = nil
                if entry.scuba ~= nil then
                    minetest.sound_stop(entry.scuba)
                    ambiance.sound_play("drowning_gasp", pos, 1.0, 30)
                    entry.scuba = nil
                end
            end
            
            if under == 1 then
                if entry.psplash == nil then entry.psplash = pos end
                
                if vector.distance(entry.psplash, pos) > 0.5 and entry.hsplash == nil then
                    ambiance.sound_play("splashing", pos, 1.0, 30)
                    entry.hsplash = true
                    entry.psplash = pos
                    minetest.after(3, done_splash, name)
                end
								ambiance.particles_underwater(pos)
								ambiance.particles_swimming({x=pos.x, y=pos.y+1, z=pos.z})
								
								sprint.add_stamina(v, -1)
            end
        end
    end
end

