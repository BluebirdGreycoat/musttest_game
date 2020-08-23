
exile = exile or {}
exile.modpath = minetest.get_modpath("exile")

-- Localize for performance.
local vector_distance = vector.distance

-- Helper to query whether there is a nearby non-cheating player (also not self)
-- within a certain range.
local function nearby_noncheater(pname, pos, range)
	local players = minetest.get_connected_players()
	for i=1, #players, 1 do
		local pref = players[i]
		local pn = pref:get_player_name()
		if pn ~= pname then
			if vector_distance(pref:get_pos(), pos) < range then
				if not sheriff.is_suspected_cheater(pn) then
					return true
				end
			end
		end
	end
end

-- A player is violating their exile if ...
function exile.player_in_violation(pname)
	-- They are a registered cheater ...
	if sheriff.is_cheater(pname) then
		local pref = minetest.get_player_by_name(pname)
		-- And they are logged in ...
		if pref then
			local pos = pref:get_pos()
			-- And there's a normal player near them ...
			if nearby_noncheater(pname, pos, 50) then
				-- And they are in a city area ...
				if city_block:in_city(pos) then
					return true
				end
			end
		end
	end
end

if not exile.registered then
	local c = "exile:core"
	local f = exile.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	exile.registered = true
end
