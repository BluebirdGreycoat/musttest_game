
-- This file is reloadable.

if not minetest.global_exists("ambiance") then ambiance = {} end
ambiance.players = ambiance.players or {}
ambiance.environment_cache = ambiance.environment_cache or {}
ambiance.modpath = minetest.get_modpath("ambiance")

-- Localize for performance.
local math_random = math.random
local vround = vector.round
local min = math.min
local max = math.max



dofile(ambiance.modpath .. "/data.lua")
dofile(ambiance.modpath .. "/utility.lua")
dofile(ambiance.modpath .. "/scuba.lua")
dofile(ambiance.modpath .. "/particles.lua")
dofile(ambiance.modpath .. "/beacon.lua")
dofile(ambiance.modpath .. "/treesounds.lua")
dofile(ambiance.modpath .. "/gate.lua")
dofile(ambiance.modpath .. "/default_beacons.lua")



-- Modifiable parameters.
ambiance.server_step = 1



local step_timer = 0
local step_total = ambiance.server_step
ambiance.globalstep = function(dtime)
	step_timer = step_timer + dtime
	if step_timer < step_total then
		return
	end
	step_timer = 0

	-- Get current time of day.
	local curtime = minetest.get_timeofday()
	local rand = math_random
    
	-- For all sounds, check if anyone can hear them. If yes, play sound to players that can hear.
	local allsounds = ambiance.allsounds
	for k, v in ipairs(allsounds) do
		v.timer = v.timer - step_total
		if v.timer <= 0 then
			-- Timer has expired, fire sound (if possible).
			-- Also reset the timer so the sound can fire again.
			v.timer = rand(v.mintime, v.maxtime)

			-- Can this sound play at the current time of day?
      if ambiance.check_time(v.time, curtime) then
				-- Scan through all players. The following checks must be done per-player.
				for name, pdata in pairs(ambiance.players) do
					local player = minetest.get_player_by_name(name)
					if player and player:is_player() then
						local pos = utility.get_foot_pos(player:get_pos())
						-- Is player in this sounds's Y layer?
						local miny = v.miny
						local maxy = v.maxy

						if v.ground_offset then
							local g
							if type(v.ground_offset) == "function" then
								g = v.ground_offset(vround(pos))
							else
								g = v.ground_offset
							end
							miny = g + miny
							maxy = g + maxy

							miny = max(miny, v.absminy)
							maxy = min(maxy, v.absmaxy)
						end

						if pos.y >= miny and pos.y <= maxy then

							-- Don't play sound if player is underwater (muted sounds).
							-- Note: player's underwater status is modified by the scuba code.
							local underwater = ambiance.players[name].underwater
							if underwater == nil then
								local spawnsound = true

								-- If have perlin object, then check if sound can spawn in this location.
								if v.perlin and v.noise_threshold then
									local noise = v.perlin:get_3d(pos)
									if v.absvalue then
										noise = math.abs(noise)
									end
									if noise < v.noise_threshold then
										spawnsound = false
									end
								end

								-- If we have a noise function, use that (allows arbitrary
								-- complexity in calculating where ambiance is allowed to play).
								-- Should be used by custom Lua mapgens + realms.
								if v.noise_function then
									if not v.noise_function(vround(pos)) then
										spawnsound = false
									end
								end

								-- If sound may only play in a particular realm ...
								if v.realm and rc.current_realm_at_pos(pos) ~= v.realm then
									spawnsound = false
								end

								if spawnsound then
									-- Only play sound if sound can be played indoors or out-of-doors.
									-- If sound doesn't care whether indoors or out-of-doors, then play it.

									local indoors
									if v.indoors ~= nil then
										-- Randomize position a bit in case player is just standing under an overhang.
										pos.x = rand(pos.x - 1, pos.x + 1)
										pos.y = rand(pos.y - 1, pos.y + 1)
										pos.z = rand(pos.z - 1, pos.z + 1)
										indoors = ambiance.check_indoors(name, pos)
									end

									if v.indoors == indoors then
										-- Play sound to current player!
										-- If multiple players can hear, the sound will be played at the same time to all of them.
										local gain = rand(v.mingain*100.0, v.maxgain*100.0)/100.0
										-- Clamp gain!
										if gain < 0.0 then gain = 0.0 end
										if gain > 2.0 then gain = 2.0 end
										minetest.sound_play(v.name, {to_player=name, gain=gain})
									end
								end
							end
						end
					end
				end
			end
		end
	end
end



-- Register our handlers only once.
if not ambiance.registered then
	-- Store data per-player.
  minetest.register_on_joinplayer(function(player)
		local pname = player:get_player_name()
    ambiance.players[pname] = {}
  end)
  minetest.register_on_leaveplayer(function(player)
    ambiance.players[player:get_player_name()] = nil
  end)
  
  minetest.register_globalstep(function(...) return ambiance.globalstep(...) end)
  minetest.register_globalstep(function(...) return ambiance.globalstep_scuba(...) end)
  ambiance.registered = true
end



-- Register everything as reloadable.
if minetest.get_modpath("reload") then
  local c = "ambiance:core"
  local f = ambiance.modpath .. "/init.lua"
  if not reload.file_registered(c) then
    reload.register_file(c, f, false)
  end
end

