
-- Localize for performance.
local vector_round = vector.round
local math_floor = math.floor
local math_min = math.min



-- Return the player's current HP regen boost (as a multiplier)
function hunger.get_stamina_boost(pname)
	local tab = hunger.players[pname]
	if tab and tab.stamina_boost then
		return tab.stamina_boost
	end
	return 1
end



-- Apply a health boost to player.
function hunger.apply_stamina_boost(pname)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local tab = hunger.players[pname]
	if not tab then
		return
	end

	local already_boosted = false
	if tab.stamina_boost_time then
		already_boosted = true
	end

	-- Boost HP-regen for several health-regain-timer ticks, time-additive.
	tab.stamina_boost = 3
	tab.stamina_boost_time = (tab.stamina_boost_time or 0) + 120

	-- Don't stack 'minetest.after' chains.
	-- Also don't stack 'hp_max'.
	if already_boosted then
		return
	end

	tab.stamina_boost_hud = pref:hud_add({
    hud_elem_type = "image",
    scale = {x = -100, y = -100},
    alignment = {x = 1, y = 1},
    text = "sta_boost_effect.png",
    z_index = -350,
	})
	minetest.chat_send_player(pname, "# Server: Strength regen rate boosted for " .. tab.stamina_boost_time .. " seconds.")
	hunger.time_stamina_boost(pname)
end



function hunger.time_stamina_boost(pname)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local tab = hunger.players[pname]
	if not tab then
		return
	end

	tab.stamina_boost_time = tab.stamina_boost_time - 1

	if tab.stamina_boost_time <= 0 then
    minetest.chat_send_player(pname, "# Server: Strength regen boost expired.")

    pref:hud_remove(tab.stamina_boost_hud)
    tab.stamina_boost_hud = nil
		tab.stamina_boost_time = nil
		tab.stamina_boost = nil
		return
	end

	-- Check again soon.
	minetest.after(1, hunger.time_stamina_boost, pname)
end
