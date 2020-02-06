
if not ambiance.gate_registered then
	ambiance.register_sound_beacon(":soundbeacon:gate", {
		-- Minimum and maximum times between environment checks.
		check_time_min = 60,
		check_time_max = 60*15,

		-- Minimum and maximum times between sounds playing.
		play_time_min = 5,
		play_time_max = 6,

		-- Shall check the beacon's nearby environment, and return 'true' if beacon
		-- can remain, 'false' or 'nil' if it should be removed. Data can be stored in
		-- `data`. `pos` is always a rounded position.
		on_check_environment = function(data, pos)
			if obsidian_gateway.find_gate(pos) then
				return true
			end
		end,

		-- Shall play sound to nearby players (or check whether sound can be played at
		-- this time). Data can be stored in `data`. `pos` is
		-- always a rounded position. `dtime` is seconds since last call to func.
		on_play_sound = function(data, pos, dtime)
			ambiance.sound_play("obsidian_gate_rumble", pos, 1.0, 32)
		end,
	})

	ambiance.gate_registered = true
end
