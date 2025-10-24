
-- API function. Teleports, TP arrows, and Jaunt query this to see if they can
-- teleport to or from a location. Function must return FALSE if tp is to be
-- disallowed here, otherwise TRUE for all other positions.
function fortress.can_teleport_at(pos)
	pos = vector.round(pos)

	local forts = fortress.v2.get_fortinfo_at_pos(pos)
	if #forts > 0 then return false end

	return true
end
