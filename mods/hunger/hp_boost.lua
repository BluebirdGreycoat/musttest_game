
-- Max HP boost.
-- Note: HP boost does not admit multiplier modifiers; HP boost always uses
-- fixed values!

-- Localize for performance.
local vector_round = vector.round
local math_floor = math.floor
local math_min = math.min



-- Return the player's current HP boost.
-- Needed for compatibility with XP code, since that also changes player's max HP.
function hunger.get_health_boost(pname)
	local tab = hunger.players[pname]
	if tab then
		-- Calc sum of all active HP boosts.
		local total = 0
		for k, v in pairs(tab) do
			if k:find("^effect_data_health_boost_") then
				total = total + v.health
			end
		end
		-- Clamp to prevent overflow in engine.
		total = math_min(total, 30*500)
		return total
	end
	return 0
end



-- Apply a health boost to player.
-- 'data' = {health=10000, time=60}
-- 'health' is additive. Must not exceed 30*500.
function hunger.apply_health_boost(pname, key, data)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local tab = hunger.players[pname]
	if not tab then
		return
	end

	local keyname = "effect_time_health_boost_" .. key
	local datname = "effect_data_health_boost_" .. key

	local already_boosted = false
	if tab[keyname] then
		already_boosted = true
	end

	local oldboost = hunger.get_health_boost(pname)

	-- Boost max HP, time-additive.
	tab[keyname] = (tab[keyname] or 0) + data.time
	tab[datname] = tab[datname] or data

	-- Don't stack 'minetest.after' chains.
	-- Also don't stack 'hp_max'.
	if already_boosted then
		return
	end

	local hp = pref:get_hp()
	local hp_max = pova.get_active_modifier(pref, "properties").hp_max
	local perc = (hp / hp_max)
	if perc > 1 then perc = 1 end

	local new_hp_max = hp_max + data.health
	local new_hp = new_hp_max * perc

	-- Note: must manually notify HP change reason here.
	armor.notify_set_hp_reason({reason="hp_boost_start"})
	pova.set_modifier(pref, "properties", {hp_max=data.health}, "hp_boost_" .. key, "add")
	pref:set_hp(new_hp)

	if oldboost == 0 then
		minetest.chat_send_player(pname, "# Server: Max health boosted for " .. tab[keyname] .. " seconds.")
		hud.change_item(pref, "health", {text="hud_heart_fg_boost.png"})
	end

	armor:update_inventory(pref)
	hunger.time_health_boost(pname, key)
end



-- Private function!
function hunger.time_health_boost(pname, key)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local tab = hunger.players[pname]
	if not tab then
		return
	end

	local keyname = "effect_time_health_boost_" .. key
	local datname = "effect_data_health_boost_" .. key

	if tab[keyname] <= 0 then
    -- Get currently active health boost.
    local cboost = hunger.get_health_boost(pname)

		tab[keyname] = nil
		tab[datname] = nil

		-- Get remaining health boost from any other effects.
    local nboost = hunger.get_health_boost(pname)

    if nboost == 0 then
			if pref:get_hp() > 0 then
				minetest.chat_send_player(pname, "# Server: Max health boost expired.")
			end
			hud.change_item(pref, "health", {text="hud_heart_fg.png"})
    end

		local hp_max = pova.get_active_modifier(pref, "properties").hp_max
		local hp = pref:get_hp()
		local perc = (hp / hp_max)
		if perc > 1 then perc = 1 end

		-- Note: must manually notify HP change reason here.
		armor.notify_set_hp_reason({reason="hp_boost_end"})
		pova.remove_modifier(pref, "properties", "hp_boost_" .. key)

		-- Restore baseline HP level.
		local new_hp_max = pova.get_active_modifier(pref, "properties").hp_max
		local new_hp = perc * new_hp_max

		-- Note: must manually notify HP change reason here.
		armor.notify_set_hp_reason({reason="hp_boost_end"})
		pref:set_hp(new_hp)

		armor:update_inventory(pref)

		-- Manually update HUD.
		hud.player_event(pref, "health_changed")
		return
	end

	-- Check again soon.
	tab[keyname] = tab[keyname] - 1
	minetest.after(1, hunger.time_health_boost, pname, key)
end
