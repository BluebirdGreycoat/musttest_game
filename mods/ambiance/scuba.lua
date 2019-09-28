
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



function ambiance.check_water_pressure(pos, player)
	local y = pos.y
	local c = 45
	local w = 0

	local n = minetest.get_node(pos)
	local d = minetest.registered_nodes[n.name] or {}
	local g = d.groups or {}

	-- Count water nodes above player, starting with position.
	while c > 0 and g.water and g.water > 0 do
		w = w + 1
		c = c - 1
		pos.y = pos.y + 1
		n = minetest.get_node(pos)
		d = minetest.registered_nodes[n.name] or {}
		g = d.groups or {}
	end

	pos.y = y

	local damage = 0
	if y < -50 then
		if w >= 45 then
			damage = 3
		elseif w >= 30 then
			damage = 2
		elseif w >= 15 then
			damage = 1
		end
	end

	if damage > 0 then
		if player:get_hp() > 0 then
			player:set_hp(player:get_hp() - damage)
			if player:get_hp() <= 0 then
				minetest.chat_send_all("# Server: <" .. rename.gpn(player:get_player_name()) .. "> was wrecked by water pressure.")
			end
		end
	end

	-- Return water column count.
	return w
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

								-- Water-shaft makers will H8TE this!
								ambiance.check_water_pressure(vector.round(pos), v)

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

