
-- Localize for performance.
local vector_round = vector.round
local math_floor = math.floor
local math_min = math.min



-- Return the player's current HP regen boost (as a multiplier)
function hunger.get_hpgen_boost(pname)
	local tab = hunger.players[pname]
	if tab and tab.effect_data_hpgen_boost then
		-- Calc sum of all active modifiers.
		local total = 0
		for k, v in pairs(tab) do
			if k:find("^effect_data_hpgen_boost_") then
				total = total + v.regen
			end
		end
		return total
	end
	return 1
end



-- Apply a health boost to player.
-- 'data' = {regen=2, time=60}
function hunger.apply_hpgen_boost(pname, key, data)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local tab = hunger.players[pname]
	if not tab then
		return
	end

	local keyname = "effect_time_hpgen_boost_" .. key
	local datname = "effect_data_hpgen_boost_" .. key

	local already_boosted = false
	if tab[keyname] then
		already_boosted = true
	end

	-- Boost HP-regen for several health-regain-timer ticks, time-additive.
	tab[keyname] = (tab[keyname] or 0) + data.time
	tab[datname] = tab[datname] or data.regen

	-- Don't stack 'minetest.after' chains.
	-- Also don't stack 'hp_max'.
	if already_boosted then
		return
	end

	tab[datname].hud = pref:hud_add({
    hud_elem_type = "image",
    scale = {x = -100, y = -100},
    alignment = {x = 1, y = 1},
    text = "hp_boost_effect.png",
    z_index = -350,
	})
	minetest.chat_send_player(pname, "# Server: Health regen rate boosted for " .. tab[keyname] .. " seconds.")

	hunger.time_hpgen_boost(pname, key)
end



-- Private function!
function hunger.time_hpgen_boost(pname, key)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local tab = hunger.players[pname]
	if not tab then
		return
	end

	local keyname = "effect_time_hpgen_boost_" .. key
	local datname = "effect_data_hpgen_boost_" .. key

	if tab[keyname] <= 0 then
    if pref:get_hp() > 0 then
      minetest.chat_send_player(pname, "# Server: HP regen boost expired.")
    end

    pref:hud_remove(tabtab[datname].hud)
		tab[keyname] = nil
		tab[datname] = nil
		return
	end

	-- Check again soon.
	tab[keyname] = tab[keyname] - 1
	minetest.after(1, hunger.time_hpgen_boost, pname, key)
end
