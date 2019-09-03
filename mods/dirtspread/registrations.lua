
-- File is reloadable.

dirtspread.register_active_block("default:dirt", {
	min_time = 1,
	max_time = 5,

	-- If function uses `minetest.add_node`, neighbor nodes will be notified again.
	-- This can create a cascade effect, which may or may not be desired.
	func = function(pos, node)
		local above = {x=pos.x, y=pos.y+1, z=pos.z}
		local light = minetest.get_node_light(above, 0.5) or 0 -- Light level in daytime.

		-- If in complete darkness, turn to sterile dirt.
		if light == 0 then
			node.name = "darkage:darkdirt"
			minetest.add_node(pos, node)
			return
		end

		-- Get what's above us.
		local n2 = minetest.get_node(above)
		local ndef = minetest.registered_nodes[n2.name]

		if not ndef then
			return
		end

		local groups = ndef.groups or {}

		-- Convert to dirt_with_snow if snow on top.
		if (groups.snow and groups.snow > 0) or (groups.snowy and groups.snowy > 0) then
			node.name = "default:dirt_with_snow"
			minetest.add_node(pos, node)
			return
		end

		-- Get what's to the 4 sides.
		local sides = {
			{x=pos.x-1, y=pos.y, z=pos.z},
			{x=pos.x+1, y=pos.y, z=pos.z},
			{x=pos.x, y=pos.y, z=pos.z-1},
			{x=pos.x, y=pos.y, z=pos.z+1},
		}

		-- If snow nearby, convert to dirt with snow.
		for k, v in ipairs(sides) do
			local n2 = minetest.get_node(v)
			local ndef = minetest.registered_nodes[n2.name]
			if ndef then
				local groups = ndef.groups or {}
				if (groups.snow and groups.snow > 0) or (groups.snowy and groups.snowy > 0) then
					node.name = "default:dirt_with_snow"
					minetest.add_node(pos, node)
				end
			end
		end
	end,
})
