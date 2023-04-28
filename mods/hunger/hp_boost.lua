
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

	-- Boost max HP by 15000 points for 30 seconds, time-additive.
	-- Note that this is just 500 short of the highest we can go; HP capped by
	-- engine at 65535.
	tab[keyname] = (tab[keyname] or 0) + data.time
	tab[datname] = tab[datname] or data

	-- Don't stack 'minetest.after' chains.
	-- Also don't stack 'hp_max'.
	if already_boosted then
		return
	end

	local hp = pref:get_hp()
	local hp_max = xp.get_hp_max(pname)
	local perc = (hp / hp_max)

	-- This will get all existing health boosts, + the one we just added.
	local cboost = oldboost + data.health
	hp_max = hp_max + cboost
	hp = hp_max * perc

	pref:set_properties({hp_max=hp_max})
	pref:set_hp(hp)

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

		local nmax = xp.get_hp_max(pname)
		local hp = pref:get_hp()
		local hp_max = nmax + cboost
		local perc = (hp / hp_max)

		-- Restore baseline HP level.
		local nmax = nmax + nboost
		local nhp = perc * nmax
		pref:set_properties({hp_max = nmax})
		pref:set_hp(nhp)

		armor:update_inventory(pref)
		return
	end

	-- Check again soon.
	tab[keyname] = tab[keyname] - 1
	minetest.after(1, hunger.time_health_boost, pname, key)
end
