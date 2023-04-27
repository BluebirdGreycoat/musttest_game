
-- HOT = Heal Over Time

-- Localize for performance.
local vector_round = vector.round
local math_floor = math.floor
local math_min = math.min



-- Apply a HOT modifier to player.
-- HOT modifier shall have a name ('key') which keeps separate from other HOTs.
-- A HoT with particular name can only have one active instance per player, so
-- they don't stack, UNLESS they are different types.
function hunger.apply_hot(pname, key, data)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local tab = hunger.players[pname]
	if not tab then
		return
	end

	local hotname = "effect_time_hot_" .. key
	local datname = "effect_data_hot_" .. key

	local already_boosted = false
	if tab[hotname] then
		already_boosted = true
	end

	-- HOT for several seconds, time-additive.
	tab[hotname] = (tab[hotname] or 0) + data.time
	tab[datname] = tab[datname] or data

	-- Don't stack 'minetest.after' chains.
	if already_boosted then
		return
	end

	hunger.time_hot(pname, key)
end



-- Private function!
function hunger.time_hot(pname, key)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local tab = hunger.players[pname]
	if not tab then
		return
	end

	local hotname = "effect_time_hot_" .. key
	local datname = "effect_data_hot_" .. key

	if tab[hotname] <= 0 then
		tab[hotname] = nil
		tab[datname] = nil
		return
	end

	-- Cancel if health reached full
	if pref:get_hp() == pref:get_properties().hp_max then
    tab[hotname] = nil
		tab[datname] = nil
    return
  end

  local data = tab[datname]
	pref:set_hp(pref:get_hp() + data.heal)

	-- Check again soon.
	tab[hotname] = tab[hotname] - 1
	minetest.after(1, hunger.time_hot, pname, key)
end
