
-- File is reloadable.

dirtspread.register_active_block("default:dirt", {
	min_time = 1,
	max_time = 5,

	-- If function returns `true`, timer will be restarted with new random timeout.
	func = function(pos, node)
		local above = {x=pos.x, y=pos.y+1, z=pos.z}
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
	end,
})
