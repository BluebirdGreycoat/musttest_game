
-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round
local vector_add = vector.add
local vector_equals = vector.equals
local math_random = math.random
local CITYBLOCK_DELAY_TIME = city_block.CITYBLOCK_DELAY_TIME
local time_active = city_block.time_active



function city_block.delete_blocks_from_area(minp, maxp)
	local i = 1
	local blocks = city_block.blocks

	::do_next::
	if i > #blocks then
		return
	end
	local p = blocks[i].pos

	if p.x >= minp.x and p.x <= maxp.x and
			p.y >= minp.y and p.y <= maxp.y and
			p.z >= minp.z and p.z <= maxp.z then
		-- Don't need to worry about relative ordering.
		-- This is your standard swap'n'pop.
		blocks[i] = blocks[#blocks]
		blocks[#blocks] = nil
		goto do_next
	end

	i = i + 1
	goto do_next

	-- Done.
	city_block:save()
end



function city_block.erase_jail(pos)
	pos = vector_round(pos)
	local b = city_block.blocks
	for k, v in ipairs(b) do
		if vector_equals(pos, v.pos) then
			v.is_jail = nil
			city_block:save()

			local meta = minetest.get_meta(pos)
			local pname = meta:get_string("owner")
			local dname = rename.gpn(pname)
			meta:set_string("infotext", city_block.get_infotext(pos))

			return
		end
	end
end



function city_block.get_infotext(pos)
	local meta = minetest.get_meta(pos)
	local pname = meta:get_string("owner")
	local cityname = meta:get_string("cityname")
	local dname = rename.gpn(pname)

	local text = "City Marker (Placed by <" .. dname .. ">!)"

	if cityname ~= "" then
		text = text .. "\nRegion Designate: \"" .. cityname .. "\""
	end

	local blockdata = city_block.get_block(pos)
	if blockdata and blockdata.pvp_arena then
		text = text .. "\nThis marks a dueling arena.\nPunch with gold ingot to duel."
	end

	return text
end



function city_block.after_place_node(pos, placer)
	if placer and placer:is_player() then
		local pname = placer:get_player_name()
		local meta = minetest.get_meta(pos)
		local dname = rename.gpn(pname)
		meta:set_string("rename", dname)
		meta:set_string("owner", pname)
		meta:set_string("infotext", city_block.get_infotext(pos))
		table.insert(city_block.blocks, {
			pos = vector_round(pos),
			owner = pname,
			time = os.time(),
		})
		city_block:save()
	end
end



function city_block.on_destruct(pos)
	-- The cityblock may not exist in the list if the node was created by falling,
	-- and was later dug.
	for i, EachBlock in ipairs(city_block.blocks) do
		if vector_equals(EachBlock.pos, pos) then
			table.remove(city_block.blocks, i)
			city_block:save()
		end
	end
end



function city_block._on_update_infotext(pos)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	-- Nobody placed this block.
	if owner == "" then
		return
	end
	local dname = rename.gpn(owner)

	meta:set_string("rename", dname)
	meta:set_string("infotext", city_block.get_infotext(pos))
end
