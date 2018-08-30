
-- This file is reloadable.

ambiance = ambiance or {}
ambiance.players = ambiance.players or {}
ambiance.environment_cache = ambiance.environment_cache or {}
ambiance.modpath = minetest.get_modpath("ambiance")

dofile(ambiance.modpath .. "/data.lua")
dofile(ambiance.modpath .. "/utility.lua")
dofile(ambiance.modpath .. "/scuba.lua")
dofile(ambiance.modpath .. "/particles.lua")



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
    
	-- For all sounds, check if anyone can hear them. If yes, play sound to players that can hear.
	local allsounds = ambiance.allsounds
	for k, v in ipairs(allsounds) do
		v.timer = v.timer - step_total
		if v.timer <= 0 then
			-- Timer has expired, fire sound (if possible).
			-- Also reset the timer so the sound can fire again.
			v.timer = math.random(v.mintime, v.maxtime)

			-- Can this sound play at the current time of day?
      if ambiance.check_time(v.time, curtime) then
				-- Scan through all players. The following checks must be done per-player.
				for name, pdata in pairs(ambiance.players) do
					local player = minetest.get_player_by_name(name)
					if player and player:is_player() then
						local pos = utility.get_foot_pos(player:get_pos())
						-- Is player in this sounds's Y layer?
						if pos.y >= v.miny and pos.y <= v.maxy then
							-- Don't play sound if player is underwater (muted sounds).
							-- Note: player's underwater status is modified by the scuba code.
							local underwater = ambiance.players[name].underwater
							if underwater == nil then
								-- Only play sound if sound can be played indoors or out-of-doors.
			          -- If sound doesn't care whether indoors or out-of-doors, then play it.
								local indoors = ambiance.check_indoors(name, pos)
      			    if v.indoors == nil or v.indoors == indoors then
									-- Play sound to current player!
									-- If multiple players can hear, the sound will be played at the same time to all of them.
									local gain = math.random(v.mingain*100.0, v.maxgain*100.0)/100.0
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

