
beds.public_spawns = {}

local worldpath = minetest.get_worldpath()
local pubfile = worldpath .. "/public_bed_spawns"



function beds.read_public_spawns()
	local file, err = io.open(pubfile, "r")
	if err then
		beds.public_spawns = {}
	end
	if file then
		local datstr = file:read("*all")
		local dattab = minetest.deserialize(datstr)
		if dattab and type(dattab) == "table" then
			beds.public_spawns = dattab
		else
			beds.public_spawns = {}
		end
		file:close()
	end
end



function beds.save_public_spawns()
	local datstr = minetest.serialize(beds.public_spawns)
	if datstr then
		minetest.safe_file_write(pubfile, datstr)
	end
end



-- Add public spawn, or do nothing if already exists.
function beds.add_public_spawn(pos)
	pos = vector.round(pos)

	local eq = vector.equals
	local num = #beds.public_spawns
	local items = beds.public_spawns

	-- Make sure position does not exist.
	for k = 1, num do
		if eq(pos, items[k]) then
			return
		end
	end

	items[#items + 1] = vector.copy(pos)
	beds.save_public_spawns()
end



-- Remove public spawn, or do nothing if not exist.
function beds.remove_public_spawn(pos)
	pos = vector.round(pos)

	local eq = vector.equals
	local num = #beds.public_spawns
	local items = beds.public_spawns

	for k = 1, num do
		if eq(pos, items[k]) then
			-- This is your standard swap'n'pop. Order doesn't matter.
			items[k] = items[#items]
			items[#items] = nil
			beds.save_public_spawns()
			return
		end
	end
end



function beds.delete_public_spawns_from_area(minp, maxp)
	local i = 1
	local items = beds.public_spawns

	::do_next::
	if i > #items then
		return
	end
	local p = items[i]

	if p.x >= minp.x and p.x <= maxp.x and
			p.y >= minp.y and p.y <= maxp.y and
			p.z >= minp.z and p.z <= maxp.z then
		-- Don't need to worry about relative ordering.
		-- This is your standard swap'n'pop.
		items[i] = items[#items]
		items[#items] = nil
		goto do_next
	end

	i = i + 1
	goto do_next

	-- Done.
	beds.save_public_spawns()
end
