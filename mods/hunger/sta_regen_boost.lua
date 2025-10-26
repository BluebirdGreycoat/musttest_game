
-- Localize for performance.
local vector_round = vector.round
local math_floor = math.floor
local math_min = math.min



-- Return the player's current HP regen boost (as a multiplier)
function hunger.get_stamina_boost(pname)
	local tab = hunger.players[pname]
	if tab then
		-- Calc sum of all active modifiers.
		local total = 1
		for k, v in pairs(tab) do
			if k:find("^effect_data_stamina_boost_") then
				total = total * v.regen
			end
		end
		return total
	end
	return 1
end



-- Apply a stamina boost to player.
-- 'data' = {regen=2, time=60}
-- 'regen' is a multiplier. 1 is 100%, no change.
function hunger.apply_stamina_boost(pname, key, data)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local tab = hunger.players[pname]
	if not tab then
		return
	end

	local keyname = "effect_time_stamina_boost_" .. key
	local datname = "effect_data_stamina_boost_" .. key

	local already_boosted = false
	if tab[keyname] then
		already_boosted = true
	end

	-- Boost stamina-regen for a time, time-additive.
	tab[keyname] = (tab[keyname] or 0) + 120
	tab[datname] = tab[datname] or data

	-- Don't stack 'minetest.after' chains.
	-- Also don't stack 'hp_max'.
	if already_boosted then
		return
	end

	tab[datname].hud = pref:hud_add({
    type = "image",
    scale = {x = -100, y = -100},
    alignment = {x = 1, y = 1},
    text = "sta_boost_effect.png",
    z_index = -350,
	})
	minetest.chat_send_player(pname, "# Server: Strength regen rate boosted for " .. tab[keyname] .. " seconds.")
	hunger.time_stamina_boost(pname, key)
end



-- Private function!
function hunger.time_stamina_boost(pname, key)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local tab = hunger.players[pname]
	if not tab then
		return
	end

	local keyname = "effect_time_stamina_boost_" .. key
	local datname = "effect_data_stamina_boost_" .. key

	if tab[keyname] <= 0 then
    if pref:get_hp() > 0 then
      minetest.chat_send_player(pname, "# Server: Strength regen boost expired.")
    end

    pref:hud_remove(tab[datname].hud)
		tab[keyname] = nil
		tab[datname] = nil
		return
	end

	-- Check again soon.
	tab[keyname] = tab[keyname] - 1
	minetest.after(1, hunger.time_stamina_boost, pname, key)
end
