
exile = exile or {}
exile.modpath = minetest.get_modpath("exile")

-- Localize for performance.
local vector_distance = vector.distance
local vector_normalize = vector.normalize
local vector_subtract = vector.subtract
local vector_multiply = vector.multiply
local vector_round = vector.round
local vector_add = vector.add

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

function exile.send_to_exile(pname)
	local pref = minetest.get_player_by_name(pname)
	if pref then
		local pos = pref:get_pos()
		local rn1 = rc.current_realm_at_pos(pos)
		local cb = city_block:nearest_blocks_to_position(pos, 5, 100)

		-- Calculate the average postion of nearby city-blocks.
		local x, y, z, n = 0, 0, 0, #cb
		for i=1, n, 1 do
			local b = cb[i]
			local p = b.pos
			x = x + p.x
			y = y + p.y
			z = z + p.z
		end
		x = x / n
		y = y / n
		z = z / n

		-- Calculate a new position away from the city-blocks.
		local center = {x=x, y=y, z=z}
		local gpos = vector_round(vector_add(vector_multiply(vector_subtract(pos, center), 2), center))
		local rn2 = rc.current_realm_at_pos(gpos)

		-- Only if we wouldn't cause player to change realms, or enter the void.
		if rn2 ~= "" and rn1 == rn2 then
			pref:set_pos(gpos)
		end
	end
end

if not exile.registered then
	local c = "exile:core"
	local f = exile.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	exile.registered = true
end
