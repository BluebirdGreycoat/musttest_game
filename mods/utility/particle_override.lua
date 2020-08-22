
-- We need to override the Minetest particle API in order to
-- control which clients receive particles.

local players = {}
local modmeta = minetest.get_mod_storage()
local maxdist = 50

-- Save original functions.
local add_particlespawner = minetest.add_particlespawner
local add_particle = minetest.add_particle

utility.original_add_particlespawner = add_particlespawner
utility.original_add_particle = add_particle


function default.particles_enabled_for(pname)
	local key = "particles:" .. pname
	if modmeta:get_int(key) == 1 then
		return false
	end
	return true
end



-- Called from the control panel GUI.
function default.enable_particles_for(pname, enable)
	local key = "particles:" .. pname
	if enable == true then
		modmeta:set_int(key, 0)
		if minetest.get_player_by_name(pname) then
			players[pname] = true
		end
	else
		modmeta:set_int(key, 1)
		players[pname] = nil
	end
end



function minetest.add_particlespawner_single(data)
	local id
	local pname = data.playername or ""
	if players[pname] then
		local player = minetest.get_player_by_name(pname)
		if player then
			if vector.distance(player:get_pos(), data.minpos) <= maxdist then
				id = add_particlespawner(data)
			end
		end
	end
	return id
end

function minetest.add_particlespawner(data)
	for k, v in pairs(players) do
		local player = minetest.get_player_by_name(k)
		if player then
			if vector.distance(player:get_pos(), data.minpos) <= maxdist then
				data.playername = k
				add_particlespawner(data)
			end
		end
	end
end

function minetest.add_particle(data)
	for k, v in pairs(players) do
		local player = minetest.get_player_by_name(k)
		if player then
			if vector.distance(player:get_pos(), data.pos) <= maxdist then
				data.playername = k
				add_particle(data)
			end
		end
	end
end



minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()
	local key = "particles:" .. pname
	if modmeta:get_int(key) == 0 then
		players[pname] = true
	else
		players[pname] = nil
	end
end)

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	players[pname] = nil
end)


