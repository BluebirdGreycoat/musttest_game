--[[
function throwing.entity_blocks_arrow(entity_name)
	-- Dropped itemstacks don't take damage.
	if entity_name == "__builtin:item" then
		return true
	end

	-- Ignore other arrows/fireballs in flight.
	local is_arrow = (string.find(entity_name, "arrow") or string.find(entity_name, "fireball"))
	if is_arrow then
		return true
	end

	-- Entity is unknown, so punch it for damage!
	return false
end
--]]
