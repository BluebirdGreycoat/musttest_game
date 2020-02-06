
ambiance.tree_sounds = {
	{name="craw",           gain=1.0, miny=-20,    maxy=500,   time="day"  ,   indoors=false, mintime=120, maxtime=360, },
	{name="hornedowl",      gain=1.0, miny=-20,    maxy=500,   time="night",   indoors=false, mintime=120, maxtime=360, },

	-- More animal sounds. These should play with less frequency.
	{name="cricket",        gain=1.0, miny=-20,    maxy=500,   time="night",   indoors=false, },
	{name="jungle_night_1", gain=1.0, miny=-20,    maxy=500,   time="night",   indoors=false, },
	{name="cardinal",       gain=1.0, miny=-20,    maxy=500,   time="liminal", indoors=false, mintime=20, maxtime=60, },
	{name="crestedlark",    gain=1.0, miny=-20,    maxy=500,   time="liminal", indoors=false, mintime=20, maxtime=60, },
	{name="deer",           gain=1.0, miny=-20,    maxy=500,   time="night",   indoors=false, mintime=20, maxtime=120, },
	{name="frog",           gain=0.7, miny=-20,    maxy=500,   time="liminal", indoors=false, },
	{name="robin",          gain=1.0, miny=-20,    maxy=500,   time="liminal", indoors=false, },
	{name="bluejay",        gain=1.0, miny=-20,    maxy=500,   time="liminal", indoors=false, },
	{name="gull",           gain=1.0, miny=-20,    maxy=500,   time="liminal", indoors=false, },
	{name="peacock",        gain=1.0, miny=-20,    maxy=500,   time="liminal", indoors=false, },
	{name="canadianloon1",  gain=1.0, miny=-20,    maxy=500,   time="night",   indoors=false, mintime=120, maxtime=360, },
}



-- Initialize extra table parameters.
for k, v in ipairs(ambiance.tree_sounds) do
	-- Mintime & maxtime are the min and max seconds a sound can play again after it has played.
	-- The timer is reset to a new random value between min and max every time the sound plays.
	v.mintime = v.mintime or 30
	v.maxtime = v.maxtime or 120
	if v.mintime < 0 then v.mintime = 0 end
	if v.maxtime < v.mintime then v.maxtime = v.mintime end

	-- If minimum or maximum gain are not specified, calculate min and max gain.
	v.mingain = v.mingain or (v.gain - 0.5)
	v.maxgain = v.maxgain or (v.gain + 0.1)
	if v.mingain < 0 then v.mingain = 0 end
	if v.maxgain < v.mingain then v.maxgain = v.mingain end

	-- Initialize timer to a random value between min and max time.
	-- This ensures all sounds start with random times on first run.
	v.timer = math.random(v.mintime, v.maxtime)

	v.range = v.range or 30
end



if not ambiance.tree_sounds_registered then
	ambiance.register_sound_beacon(":soundbeacon:trees", {
		-- Minimum and maximum times between environment checks.
		check_time_min = 60,
		check_time_max = 60*60,

		-- Minimum and maximum times between sounds playing.
		play_time_min = 5,
		play_time_max = 30,

		-- Shall check the beacon's nearby environment, and return 'true' if beacon
		-- can remain, 'false' or 'nil' if it should be removed. Data can be stored in
		-- `data`. `pos` is always a rounded position.
		on_check_environment = function(data, pos)
			local p1 = vector.add(pos, {x=-3, y=-3, z=-3})
			local p2 = vector.add(pos, {x=3, y=3, z=3})
			local nodes = {"group:leaves", "group:tree"}
			local positions = minetest.find_nodes_in_area(p1, p2, nodes)
			if #positions > 10 then
				return true
			end
			--minetest.chat_send_all("removed!")
		end,

		-- Shall play sound to nearby players (or check whether sound can be played at
		-- this time). Data can be stored in `data`. `pos` is
		-- always a rounded position. `dtime` is seconds since last call to func.
		on_play_sound = function(data, pos, dtime)
			if not data.sounds then
				data.sounds = table.copy(ambiance.tree_sounds)
			end

			-- For all sounds, check if anyone can hear them. If yes, play sound to players that can hear.
			local allsounds = data.sounds or {}
			--minetest.chat_send_all("num: " .. #allsounds)

			-- Get current time of day.
			local curtime = minetest.get_timeofday()
			local rand = math.random

			for k, v in ipairs(allsounds) do
				v.timer = v.timer - dtime
				if v.timer <= 0 then
					-- Timer has expired, fire sound (if possible).
					-- Also reset the timer so the sound can fire again.
					v.timer = rand(v.mintime, v.maxtime)

					-- Can this sound play at the current time of day?
					if ambiance.check_time(v.time, curtime) then
						-- Scan through all players. The following checks must be done per-player.
						local players = minetest.get_connected_players()
						for _, pref in ipairs(players) do
								local pname = pref:get_player_name()
								local ppos = utility.get_foot_pos(pref:get_pos())
								--minetest.chat_send_all("found player")

								-- Is player in this sounds's Y layer?
								if ppos.y >= v.miny and ppos.y <= v.maxy then
									local pdist = vector.distance(pos, ppos)
									if pdist < v.range then
										-- Don't play sound if player is underwater (muted sounds).
										-- Note: player's underwater status is modified by the scuba code.
										local underwater = ambiance.players[pname].underwater
										if underwater == nil then
											-- Only play sound if sound can be played indoors or out-of-doors.
											-- If sound doesn't care whether indoors or out-of-doors, then play it.
											-- Randomize position a bit in case player is just standing under an overhang.
											ppos.x = rand(ppos.x - 1, ppos.x + 1)
											ppos.y = rand(ppos.y - 1, ppos.y + 1)
											ppos.z = rand(ppos.z - 1, ppos.z + 1)
											local indoors
											if v.indoors ~= nil then
												indoors = ambiance.check_indoors(pname, ppos)
											end
											if v.indoors == indoors then
												-- Play sound to current player!
												-- If multiple players can hear, the sound will be played at the same time to all of them.
												local gain = rand(v.mingain*100.0, v.maxgain*100.0)/100.0
												-- Clamp gain!
												if gain < 0.0 then gain = 0.0 end
												if gain > 2.0 then gain = 2.0 end
												local md = ambiance.compute_gain(pdist, v.range)
												minetest.sound_play(v.name, {to_player=pname, gain=gain*md})
											end
										end
									end
								end

						end
					end
				end
			end
		end,
	})

	ambiance.tree_sounds_registered = true
end
