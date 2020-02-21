
function hud.player_event(player, event)
	-- Track player by name. Avoid crash.
	local pname = player:get_player_name()

	-- Needed for first update called by on_join
	minetest.after(0.1, function()
		local plr = minetest.get_player_by_name(pname)
		if not plr then return end

		if event == "health_changed" then
			for _,v in pairs(hud.damage_events) do
				if v.func then
					v.func(plr)
				end
			end
		end

		if event == "breath_changed" then
			for _,v in pairs(hud.breath_events) do
				if v.func then
					v.func(plr)
				end
			end
		end

		if event == "hud_changed" then --called when flags changed
		end
	end)
end

core.register_playerevent(hud.player_event)
