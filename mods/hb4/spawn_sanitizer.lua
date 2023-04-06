
if not minetest.global_exists("spawn_sanitizer") then spawn_sanitizer = {} end
spawn_sanitizer.modpath = minetest.get_modpath("hb4")

spawn_sanitizer.areas = {
	-- Lava Pit A.
	{minp={x=2, y=-55, z=-12}, maxp={x=-2, y=-53, z=-10}},

	-- Lava Pit B.
	{minp={x=-2, y=-55, z=12}, maxp={x=2, y=-53, z=10}},
}

function spawn_sanitizer.sanitize_all()
	local c_air = minetest.get_content_id("air")

	for _, area in ipairs(spawn_sanitizer.areas) do
		local minp = {x=area.minp.x, y=area.minp.y, z=area.minp.z}
		local maxp = {x=area.maxp.x, y=area.maxp.y, z=area.maxp.z}

		-- Sort.
		minp, maxp = utility.sort_positions(minp, maxp)

		local vm = minetest.get_voxel_manip()
		local emin, emax = vm:read_from_map(minp, maxp)
		local data = vm:get_data()
		local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

		for z = minp.z, maxp.z do
    for x = minp.x, maxp.x do
		for y = minp.y, maxp.y do
			--minetest.chat_send_player("MustTest", minetest.pos_to_string({x=x, y=y, z=z}))
			local vp = area:index(x, y, z)
			data[vp] = c_air
		end
		end
		end

		vm:set_data(data)
		vm:write_to_map()
	end
end

if not spawn_sanitizer.registered then
	-- Clean areas after startup.
	minetest.after(10, function() spawn_sanitizer.sanitize_all() end)

	spawn_sanitizer.registered = true
end

