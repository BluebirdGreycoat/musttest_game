
beds.public_spawns = {}

local vector_distance = vector.distance
local worldpath = minetest.get_worldpath()
local pubfile = worldpath .. "/public_bed_spawns"



function beds.read_public_spawns()
	local file, err = io.open(pubfile, "r")
	if err then
		--minetest.chat_send_all('error: ' .. err)
		beds.public_spawns = {}
		return
	end
	if file then
		local datstr = file:read("*all")
		local dattab = minetest.deserialize(datstr)
		if dattab and type(dattab) == "table" then
			--minetest.chat_send_all('got spawns from file')
			beds.public_spawns = dattab
		else
			--minetest.chat_send_all('could not deserialize')
			beds.public_spawns = {}
		end
		file:close()
	end
end

-- Read the spawns.
beds.read_public_spawns()



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



-- Copied over from the cityblock code and adapted for public bed spawns.
function beds.nearest_public_spawns(pos, num, rangelim)
	local get_rn = rc.current_realm_at_pos
	local realm = get_rn(pos)

	-- Copy the master table's indices so we don't modify it.
	-- We do not need to copy the inner table data itself. Just the indices.
	-- Only copy over public spawns in the same realm, too.
	local blocks = {}
	local sblocks = beds.public_spawns
	local t2 = os.time()

	for i=1, #sblocks, 1 do
		local p = sblocks[i]

		if rangelim then
			if vector_distance(p, pos) < rangelim then
				if get_rn(p) == realm then
					blocks[#blocks+1] = sblocks[i]
				end
			end
		else
			if get_rn(p) == realm then
				blocks[#blocks+1] = sblocks[i]
			end
		end
	end

	-- Sort spawns, nearest spawns first.
	table.sort(blocks,
		function(a, b)
			local d1 = vector_distance(a, pos)
			local d2 = vector_distance(b, pos)
			return d1 < d2
		end)

	-- Return N-nearest spawns (should be at the front of the sorted table).
	local ret = {}
	for i = 1, num, 1 do
		if i <= #blocks then
			ret[#ret + 1] = blocks[i]
		else
			break
		end
	end
	return ret
end
