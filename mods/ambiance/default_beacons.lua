
-- Note: it is not enough simply to register a sound beacon here.
-- The nodes must also spawn the sound beacon (usually in on_timer or similar).
-- Otherwise, the sound beacon is registered, but no sound is played!
--
-- Note on sound files: files MUST BE MONO-TRACK! Otherwise fade-with-distance
-- WILL NOT WORK.
local function register_node_sound(name, nodes, sound)
	ambiance.register_sound_beacon(name, {
		check_time = 1,
		play_time = 8,
		play_immediate = true,

		on_check_environment = function(self, pos)
			local node = minetest.get_node(pos)
			for k, v in ipairs(nodes) do
				if node.name == v then
					return true
				end
			end
		end,

		on_play_sound = function(self, pos, time_since_last_play)
			local hnd = minetest.sound_play(sound,
				{pos=pos, max_hear_distance=20}, false)

			if self.hnd then
				minetest.sound_fade(self.hnd, 3, 0)
				self.hnd = nil
			end

			if hnd then
				self.hnd = hnd
			end
		end,

		on_stop_sound = function(self)
			if self.hnd then
				minetest.sound_fade(self.hnd, 1, 0)
				self.hnd = nil
			end
		end,
	})
end



local furnace_types = {
	"cobble_furnace:active",
	"redstone_furnace:active",
	"coal_alloy_furnace:active",
	"alloyf2:mv_active",
	"ecfurn2:lv_active",
	"ecfurn2:mv_active",
	"ecfurn2:hv_active",
	"gen2:lv_active",
	"gen2:mv_active",
	"gen2:hv_active",
}

register_node_sound("ambiance:furnace_active", furnace_types,
	{name="default_furnace_active", gain=0.25})



local grinder_types = {
	"grind2:lv_active",
	"grind2:mv_active",
	"crusher:active",
}

register_node_sound("ambiance:grinder_active", grinder_types,
	{name="grinder_grinding", gain=1.00})
