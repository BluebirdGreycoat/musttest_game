
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

ambiance.register_sound_beacon("ambiance:furnace_active", {
	check_time = 1,
	play_time = 8,
	play_immediate = true,

	on_check_environment = function(self, pos)
		local node = minetest.get_node(pos)
		for k, v in ipairs(furnace_types) do
			if node.name == v then
				return true
			end
		end
	end,

	on_play_sound = function(self, pos, time_since_last_play)
		local hnd = minetest.sound_play("default_furnace_active",
			{pos=pos, range=20, gain=0.25}, false)

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
