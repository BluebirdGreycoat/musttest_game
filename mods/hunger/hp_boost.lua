
-- Localize for performance.
local vector_round = vector.round
local math_floor = math.floor
local math_min = math.min



-- Return the player's current HP boost.
-- Needed for compatibility with XP code, since that also changes player's max HP.
function hunger.get_health_boost(pname)
	local tab = hunger.players[pname]
	if tab and tab.health_boost then
		return tab.health_boost
	end
	return 0
end



-- Apply a health boost to player.
function hunger.apply_health_boost(pname)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local tab = hunger.players[pname]
	if not tab then
		return
	end

	local already_boosted = false
	if tab.health_boost_time then
		already_boosted = true
	end

	-- Boost max HP by 15000 points for 30 seconds, time-additive.
	-- Note that this is just 500 short of the highest we can go; HP capped by
	-- engine at 65535.
	tab.health_boost = (30 * 500)
	tab.health_boost_time = (tab.health_boost_time or 0) + 30

	-- Don't stack 'minetest.after' chains.
	-- Also don't stack 'hp_max'.
	if already_boosted then
		return
	end

	local hp = pref:get_hp()
	local hp_max = pref:get_properties().hp_max
	local perc = (hp / hp_max)

	hp_max = hp_max + tab.health_boost
	hp = hp_max * perc

	pref:set_properties({hp_max=hp_max})
	pref:set_hp(hp)

	minetest.chat_send_player(pname, "# Server: Max health boosted for " .. tab.health_boost_time .. " seconds.")
	hud.change_item(pref, "health", {text="hud_heart_fg_boost.png"})
	armor:update_inventory(pref)
	hunger.time_health_boost(pname)
end



function hunger.time_health_boost(pname)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local tab = hunger.players[pname]
	if not tab then
		return
	end

	tab.health_boost_time = tab.health_boost_time - 1

	if tab.health_boost_time <= 0 then
    if pref:get_hp() > 0 then
      minetest.chat_send_player(pname, "# Server: Max health boost expired.")
    end

		hud.change_item(pref, "health", {text="hud_heart_fg.png"})
		tab.health_boost_time = nil
		tab.health_boost = nil

		local hp = pref:get_hp()
		local hp_max = pref:get_properties().hp_max
		local perc = (hp / hp_max)

		-- Restore baseline HP level.
		local nmax = xp.get_hp_max(pname)
		local nhp = perc * nmax
		pref:set_properties({hp_max = nmax})
		pref:set_hp(nhp)

		armor:update_inventory(pref)
		return
	end

	-- Check again soon.
	minetest.after(1, hunger.time_health_boost, pname)
end
