
-- Localize for performance.
local vector_round = vector.round
local math_floor = math.floor
local math_min = math.min



-- Return the player's current damage resistance (as a multiplier).
function hunger.get_damage_resistance(pname)
	local tab = hunger.players[pname]
	if tab and tab.effect_data_damage_resistance then
		return tab.effect_data_damage_resistance
	end
	return 1
end



-- Apply damage resistance to player.
function hunger.apply_damage_resistance(pname)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local tab = hunger.players[pname]
	if not tab then
		return
	end

	local already_boosted = false
	if tab.effect_time_damage_resistance then
		already_boosted = true
	end

	-- Boost damage resistance, time-additive.
	-- This is a multiplier to regular punch/arrow damage.
	tab.effect_data_damage_resistance = 0.7
	tab.effect_time_damage_resistance = (tab.effect_time_damage_resistance or 0) + 30

	-- Don't stack 'minetest.after' chains.
	-- Also don't stack 'hp_max'.
	if already_boosted then
		return
	end

	tab.effect_data_damage_resistance_hud = pref:hud_add({
    hud_elem_type = "image",
    scale = {x = -100, y = -100},
    alignment = {x = 1, y = 1},
    text = "dmg_boost_effect.png",
    z_index = -350,
	})
	minetest.chat_send_player(pname, "# Server: Damage resistance increased for " .. tab.effect_time_damage_resistance .. " seconds.")
	hunger.time_damage_resistance(pname)
end



-- Private function!
function hunger.time_damage_resistance(pname)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local tab = hunger.players[pname]
	if not tab then
		return
	end

	if tab.effect_time_damage_resistance <= 0 then
    if pref:get_hp() > 0 then
      minetest.chat_send_player(pname, "# Server: Damage resistance expired.")
    end

    pref:hud_remove(tab.effect_data_damage_resistance_hud)
    tab.effect_data_damage_resistance_hud = nil
		tab.effect_time_damage_resistance = nil
		tab.effect_data_damage_resistance = nil
		return
	end

	-- Check again soon.
	tab.effect_time_damage_resistance = tab.effect_time_damage_resistance - 1
	minetest.after(1, hunger.time_damage_resistance, pname)
end
