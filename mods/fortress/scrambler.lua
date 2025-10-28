
-- API function. Teleports, TP arrows, and Jaunt query this to see if they can
-- teleport to or from a location. Function must return FALSE if tp is to be
-- disallowed here, otherwise TRUE for all other positions.
function fortress.can_teleport_at(pos)
	pos = vector.round(pos)

	local forts = fortress.v2.get_fortinfo_at_pos(pos)
	for k, v in ipairs(forts) do
		if v.spawned then
			if type(v.suppressors) == "table" then
				if #v.suppressors > 0 then return false end
			elseif (v.suppressors or 0) > 0 then
				return false
			end
		end
	end

	return true
end



-- API function. Returns an array of fort informations for all generated forts
-- that intersect the given position.
--
-- At minimum, the array subtable elements look like:
-- {pos, minp, maxp}
-- Additional keys can be "time" and "spawned".
--
-- Returns an empty table if there are no forts intersecting the given position.
function fortress.get_forts_at_pos(pos)
	pos = vector.round(pos)
	return fortress.v2.get_fortinfo_at_pos(pos)
end



-- API function. Get the complete layout (as a table) of a fort at a given
-- spawn location. If no fort spawned from the location, returns nil.
--
-- You can get fort spawn locations by calling fortress.get_forts_at_pos() and
-- inspecting the 'pos' entries in each info subtable.
--
-- If not nil, the returned table uses hashed "chunk" positions (always
-- relative to 'spawnpos') as keys, and values are string chunk names.
function fortress.get_fort_layout(spawnpos)
	spawnpos = vector.round(spawnpos)

	local hash = minetest.hash_node_position(spawnpos)
	local key = tostring(hash)
	local data = fortress.v2.sql_read(key)

	if not data then return end

	local layout = minetest.deserialize(data)
	if type(layout) ~= "table" then return end

	return layout
end
