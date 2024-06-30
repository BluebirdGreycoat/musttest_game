
-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round
local vector_add = vector.add
local vector_equals = vector.equals
local math_random = math.random
local CITYBLOCK_DELAY_TIME = city_block.CITYBLOCK_DELAY_TIME
local time_active = city_block.time_active



function city_block.get_block(pos)
	local allblocks = city_block.blocks
	local numblocks = #(city_block.blocks)
	local block

	for i = 1, numblocks do
		local entry = allblocks[i]
		if vector_equals(entry.pos, pos) then
			block = entry
			break
		end
	end

	return block
end



-- Returns a table of the N-nearest city-blocks to a given position.
-- The return value format is: {{pos, owner}, {pos, owner}, ...}
-- Note: only returns blocks in the same realm! See RC mod.
-- The 'rangelim' parameter is optional, if specified, blocks farther than this
-- are ignored entirely.
function city_block:nearest_blocks_to_position(pos, num, rangelim)
	local get_rn = rc.current_realm_at_pos
	local realm = get_rn(pos)

	-- Copy the master table's indices so we don't modify it.
	-- We do not need to copy the inner table data itself. Just the indices.
	-- Only copy over blocks in the same realm, too.
	local blocks = {}
	local sblocks = self.blocks
	local t2 = os.time()

	for i=1, #sblocks, 1 do
		local p = sblocks[i].pos
		local t1 = sblocks[i].time or 0

		if time_active(t1, t2) then
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
	end

	-- Sort blocks, nearest blocks first.
	table.sort(blocks,
		function(a, b)
			local d1 = vector_distance(a.pos, pos)
			local d2 = vector_distance(b.pos, pos)
			return d1 < d2
		end)

	-- Return N-nearest blocks (should be at the front of the sorted table).
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



function city_block:nearest_jails_to_position(pos, num, rangelim)
	local get_rn = rc.current_realm_at_pos
	local realm = get_rn(pos)

	-- Copy the master table's indices so we don't modify it.
	-- We do not need to copy the inner table data itself. Just the indices.
	-- Only copy over blocks in the same realm, too.
	local blocks = {}
	local sblocks = self.blocks
	local t2 = os.time()

	for i=1, #sblocks, 1 do
		local v = sblocks[i]
		local p = v.pos
		local t1 = v.time or 0

		if v.is_jail and time_active(t1, t2) then
			if rangelim then
				if vector_distance(p, pos) < rangelim then
					if get_rn(p) == realm then
						blocks[#blocks+1] = v
					end
				end
			else
				if get_rn(p) == realm then
					blocks[#blocks+1] = v
				end
			end
		end
	end

	-- Sort blocks, nearest blocks first.
	table.sort(blocks,
		function(a, b)
			local d1 = vector_distance(a.pos, pos)
			local d2 = vector_distance(b.pos, pos)
			return d1 < d2
		end)

	-- Return N-nearest blocks (should be at the front of the sorted table).
	local ret = {}
	for i=1, num, 1 do
		if i <= #blocks then
			ret[#ret+1] = blocks[i]
		else
			break
		end
	end
	return ret
end



-- Get nearest named cityblock to position which is owned by 'owner'. If 'owner'
-- is nil or an empty string, returns any nearest named cityblock.
function city_block:nearest_named_region(pos, owner)
	local get_rn = rc.current_realm_at_pos
	local realm = get_rn(pos)

	-- Copy the master table's indices so we don't modify it.
	-- We do not need to copy the inner table data itself. Just the indices.
	-- Only copy over blocks in the same realm, too.
	local blocks = {}
	local sblocks = self.blocks
	local t2 = os.time()

	for i=1, #sblocks, 1 do
		local b = sblocks[i]
		local p = b.pos
		local t1 = b.time or 0

		if time_active(t1, t2) then
			if b.area_name and vector_distance(p, pos) < 100 and
					(not owner or owner == "" or b.owner == owner) then
				if get_rn(p) == realm then
					blocks[#blocks+1] = sblocks[i]
				end
			end
		end
	end

	-- Sort blocks, nearest blocks first.
	table.sort(blocks,
		function(a, b)
			local d1 = vector_distance(a.pos, pos)
			local d2 = vector_distance(b.pos, pos)
			return d1 < d2
		end)

	-- Return N-nearest blocks (should be at the front of the sorted table).
	if #blocks > 0 then
		return {blocks[1]}
	end
	return {}
end



-- Get city information for the given position.
function city_block.city_info(pos)
	pos = vector_round(pos)
	local marker = city_block:nearest_blocks_to_position(pos, 1, 100)
	if marker and marker[1] then
		-- Covers a 45x45x45 area.
		local r = 22
		local vpos = marker[1].pos
		if pos.x >= (vpos.x - r) and pos.x <= (vpos.x + r) and
			 pos.z >= (vpos.z - r) and pos.z <= (vpos.z + r) and
			 pos.y >= (vpos.y - r) and pos.y <= (vpos.y + r) then
			return marker[1]
		end
	end
end



function city_block:in_city(pos)
	pos = vector_round(pos)
	-- Covers a 45x45x45 area.
	local r = 22
	local blocks = self.blocks
	local t2 = os.time()

	for i=1, #blocks, 1 do -- Convenience of ipairs() does not justify its overhead.
		local v = blocks[i]
		local vpos = v.pos
		local t1 = v.time or 0

		if time_active(t1, t2) then
			if pos.x >= (vpos.x - r) and pos.x <= (vpos.x + r) and
				pos.z >= (vpos.z - r) and pos.z <= (vpos.z + r) and
				pos.y >= (vpos.y - r) and pos.y <= (vpos.y + r) then
				return true
			end
		end
	end
	return false
end



-- Query whether pos is in a dueling arena. Size is same as city area.
function city_block:in_pvp_arena(pos)
	pos = vector_round(pos)
	-- Covers a 45x45x45 area.
	local r = 22
	local blocks = self.blocks
	local t2 = os.time()

	for i=1, #blocks, 1 do -- Convenience of ipairs() does not justify its overhead.
		local v = blocks[i]
		local vpos = v.pos
		local t1 = v.time or 0

		if time_active(t1, t2) then
			if pos.x >= (vpos.x - r) and pos.x <= (vpos.x + r) and
				 pos.z >= (vpos.z - r) and pos.z <= (vpos.z + r) and
				 pos.y >= (vpos.y - r) and pos.y <= (vpos.y + r) then
				if v.pvp_arena then
					return true
				end
			end
		end
	end
	return false
end



-- Pass the player doing the liquid dig/place action.
function city_block:in_disallow_liquid_zone(pos, player)
	-- Never in city zone, if not a player doing this.
	if not player or not player:is_player() then
		return false
	end

	local pname = player:get_player_name()
	pos = vector_round(pos)

	-- Copy the master table's indices so we don't modify it.
	-- We do not need to copy the inner table data itself. Just the indices.
	local blocks = {}
	local sblocks = self.blocks
	local t2 = os.time()

	-- Covers a 45x45x45 area.
	local r = 22

	for i=1, #sblocks, 1 do
		local vpos = sblocks[i].pos
		local t1 = sblocks[i].time or 0

		-- Only include active blocks.
		if time_active(t1, t2) then
			-- This is a cubic distance check.
			if pos.x >= (vpos.x - r) and pos.x <= (vpos.x + r) and
				pos.z >= (vpos.z - r) and pos.z <= (vpos.z + r) and
				pos.y >= (vpos.y - r) and pos.y <= (vpos.y + r) then
				-- Add this block to list.
				blocks[#blocks+1] = sblocks[i]
			end
		end
	end

	-- Sort blocks, nearest blocks first.
	table.sort(blocks,
		function(a, b)
			local d1 = vector_distance(a.pos, pos)
			local d2 = vector_distance(b.pos, pos)
			return d1 < d2
		end)

	-- No intersecting blocks at all?
	if #blocks == 0 then
		return false
	end

	-- Check only the first, nearest block. Assumed active.
	local bcheck = blocks[1]

	if bcheck.owner == pname then
		return false
	end

	-- Nearest block NOT owned by player.
	-- This means this position is "in city" for purposes of placing/digging liquid.
	return true
end



function city_block:in_city_suburbs(pos)
	pos = vector_round(pos)
	local r = 44
	local blocks = self.blocks
	local t2 = os.time()

	for i=1, #blocks, 1 do -- Convenience of ipairs() does not justify its overhead.
		local v = blocks[i]
		local vpos = v.pos
		local t1 = v.time or 0

		if time_active(t1, t2) then
			if pos.x >= (vpos.x - r) and pos.x <= (vpos.x + r) and
				pos.z >= (vpos.z - r) and pos.z <= (vpos.z + r) and
				pos.y >= (vpos.y - r) and pos.y <= (vpos.y + r) then
				return true
			end
		end
	end
	return false
end



function city_block:in_safebed_zone(pos)
	-- Covers a 111x111x111 area.
	pos = vector_round(pos)
	local r = 55
	local blocks = self.blocks
	local t2 = os.time()

	for i=1, #blocks, 1 do -- Convenience of ipairs() does not justify its overhead.
		local v = blocks[i]
		local vpos = v.pos
		local t1 = v.time or 0

		if time_active(t1, t2) then
			if pos.x >= (vpos.x - r) and pos.x <= (vpos.x + r) and
				pos.z >= (vpos.z - r) and pos.z <= (vpos.z + r) and
				pos.y >= (vpos.y - r) and pos.y <= (vpos.y + r) then
				return true
			end
		end
	end
	return false
end



function city_block:in_no_tnt_zone(pos)
	pos = vector_round(pos)
	local r = 50
	local blocks = self.blocks
	local t2 = os.time()

	for i=1, #blocks, 1 do -- Convenience of ipairs() does not justify its overhead.
		local v = blocks[i]
		local vpos = v.pos
		local t1 = v.time or 0

		if time_active(t1, t2) then
			if pos.x >= (vpos.x - r) and pos.x <= (vpos.x + r) and
				pos.z >= (vpos.z - r) and pos.z <= (vpos.z + r) and
				pos.y >= (vpos.y - r) and pos.y <= (vpos.y + r) then
				return true
			end
		end
	end
	return false
end



function city_block:in_no_leecher_zone(pos)
	pos = vector_round(pos)
	local r = 100
	local blocks = self.blocks
	local t2 = os.time()

	for i=1, #blocks, 1 do -- Convenience of ipairs() does not justify its overhead.
		local v = blocks[i]
		local vpos = v.pos
		local t1 = v.time or 0

		if time_active(t1, t2) then
			if pos.x >= (vpos.x - r) and pos.x <= (vpos.x + r) and
				pos.z >= (vpos.z - r) and pos.z <= (vpos.z + r) and
				pos.y >= (vpos.y - r) and pos.y <= (vpos.y + r) then
				return true
			end
		end
	end
	return false
end
