
-- Localize for performance.
local vector_round = vector.round
local math_floor = math.floor
local math_min = math.min



-- Return the player's current HP regen boost (as a multiplier)
function hunger.get_hpgen_boost(pname)
	local tab = hunger.players[pname]
	if tab and tab.effect_data_hpgen_boost then
		return tab.effect_data_hpgen_boost
	end
	return 1
end



-- Apply a health boost to player.
function hunger.apply_hpgen_boost(pname)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local tab = hunger.players[pname]
	if not tab then
		return
	end

	local already_boosted = false
	if tab.effect_time_hpgen_boost then
		already_boosted = true
	end

	-- Boost HP-regen for several health-regain-timer ticks, time-additive.
	tab.effect_data_hpgen_boost = 3
	tab.effect_time_hpgen_boost = (tab.effect_time_hpgen_boost or 0) + (HUNGER_HEALTH_TICK * 10)

	-- Don't stack 'minetest.after' chains.
	-- Also don't stack 'hp_max'.
	if already_boosted then
		return
	end

	tab.effect_data_hpgen_boost_hud = pref:hud_add({
    hud_elem_type = "image",
    scale = {x = -100, y = -100},
    alignment = {x = 1, y = 1},
    text = "hp_boost_effect.png",
    z_index = -350,
	})
	minetest.chat_send_player(pname, "# Server: Health regen rate boosted for " .. tab.effect_time_hpgen_boost .. " seconds.")
	hunger.time_hpgen_boost(pname)
end



-- Private function!
function hunger.time_hpgen_boost(pname)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local tab = hunger.players[pname]
	if not tab then
		return
	end

	if tab.effect_time_hpgen_boost <= 0 then
    if pref:get_hp() > 0 then
      minetest.chat_send_player(pname, "# Server: HP regen boost expired.")
    end

    pref:hud_remove(tab.effect_data_hpgen_boost_hud)
    tab.effect_data_hpgen_boost_hud = nil
		tab.effect_time_hpgen_boost = nil
		tab.effect_data_hpgen_boost = nil
		return
	end

	-- Check again soon.
	tab.effect_time_hpgen_boost = tab.effect_time_hpgen_boost - 1
	minetest.after(1, hunger.time_hpgen_boost, pname)
end
