
local function setup_obelisk(info)
	local npos = vector.offset(info.pos, 1, math.random(0, 2), 1)
	local node = minetest.get_node(npos)

	if node.name ~= "cavestuff:glow_white_crystal" then return end

	local meta = minetest.get_meta(npos)
	meta:set_int("fortress_suppressor", 1)
	meta:set_string("fortress_location", minetest.pos_to_string(info.spawn))
	meta:mark_as_private({"fortress_suppressor", "fortress_location"})

	local fort = fortress.v2.touch_specific_fort(info.spawn)
	if not fort then return end

	-- Add position to list of this fort's suppressors. Forbid duplicates.
	fort.suppressors = fort.suppressors or {}
	if type(fort.suppressors) ~= "table" then return end

	local need_add = true
	for k, v in ipairs(fort.suppressors) do
		if vector.equals(v, npos) then
			need_add = false
			break
		end
	end
	if need_add then
		table.insert(fort.suppressors, npos)
		fortress.v2.save_fort_information()
	end

	minetest.log("action", "Spawned " .. info.schem .. " at " ..
		minetest.pos_to_string(info.pos) .. "!")
end



function fortress.v2.handle_notify(info)
	if info.schem == "nf_active_obelisk" then
		setup_obelisk(info)
	end
end
