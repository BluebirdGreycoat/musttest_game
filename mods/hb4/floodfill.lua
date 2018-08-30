
hb4 = hb4 or {}
hb4.floodfill = hb4.floodfill or {}



local function get_node_name(pos)
	local node = minetest.get_node_or_nil(pos)
	if node then
		return node.name
	end
	local meta = minetest.get_meta(pos)
	return meta:get_string("nodename")
end



-- Recursive algorithm.
local function floodfill(startpos, nodelist, maxdepth)
	local traversal = {}
	local queue = {}
	local output = {}
	local curpos, hash, exists, name, found, norm, cb, count, depth
	local maxlength = 1
	local first = true
	local get_node_hash = minetest.hash_node_position
	startpos.d = 1
	queue[#queue+1] = startpos
	count = 1

	::continue::
	curpos = queue[#queue]
	queue[#queue] = nil

	depth = curpos.d
	curpos.d = nil

	hash = get_node_hash(curpos)
	exists = false
	if traversal[hash] then
		exists = true
		if depth >= traversal[hash] then
			goto next
		end
	end

	if depth >= maxdepth then
		goto next
	end

	count = count + 1
	name = get_node_name(curpos)
	found = false
	norm = true
	cb = nil

	for n, m in pairs(nodelist) do
		if n == name then
			found = true
			if type(m) == "function" then
				cb = m
			elseif type(m) == "string" then
				if m == "leaf" then
					-- The first node scanned musn't be treated as a leaf.
					if not first then
						norm = false
					end
				end
			end
			break
		end
	end

	if not found then
		goto next
	end

	traversal[hash] = depth
	if not exists then
		output[#output+1] = {pos=curpos, name=name}
	end

	if cb then
		-- The node callback can add to the adjacency list.
		cb(curpos, queue, depth+1)
	elseif norm then
		queue[#queue+1] = {x=curpos.x+1, y=curpos.y, z=curpos.z, d=depth+1}
		queue[#queue+1] = {x=curpos.x-1, y=curpos.y, z=curpos.z, d=depth+1}
		queue[#queue+1] = {x=curpos.x, y=curpos.y+1, z=curpos.z, d=depth+1}
		queue[#queue+1] = {x=curpos.x, y=curpos.y-1, z=curpos.z, d=depth+1}
		queue[#queue+1] = {x=curpos.x, y=curpos.y, z=curpos.z+1, d=depth+1}
		queue[#queue+1] = {x=curpos.x, y=curpos.y, z=curpos.z-1, d=depth+1}
	end

	if #queue > maxlength then
		maxlength = #queue
	end

	::next::
	first = false
	if #queue > 0 then
		goto continue
	end

	--minetest.chat_send_all("# Server: Array size: " .. maxlength)
	return count, output
end



local function floodfill2(startpos, nodelist, depth, maxdepth)
	local queue = {}
	local traversal = {}
	local output = {}
	local pos = startpos
	local hash
	local adjacent = {}
	local node
	local name
	local found
	local normaladjacency
	local nodecallback

	::continue::
	if #queue > 0 then
		-- This should be the normal case.
		pos = queue[#queue]
		queue[#queue] = nil
	end

	hash = minetest.hash_node_position(pos)
	if traversal[hash] then
		-- This method makes the algorithm very slow, but is needed
		-- in order to correctly bind the flood distance to a given range.
		if traversal[hash] < depth then
			goto next
		end
	end

	traversal[hash] = depth

	if depth > maxdepth then
		goto next
	end

	node = minetest.get_node(pos)
	name = node.name
	found = false
	normaladjacency = true
	nodecallback = nil

	for n, m in pairs(nodelist) do
		if n == name then
			found = true
			if type(m) == "function" then
				nodecallback = m
			elseif type(m) == "string" then
				if m == "leaf" then
					normaladjacency = false
				end
			end
			break
		end
	end

	if not found then
		goto next
	end

	output[#output+1] = {pos=table.copy(pos), name=name}

	adjacent = {}
	if nodecallback then
		-- The node callback can set the adjacency list.
		adjacent = nodecallback(pos, node)
	elseif normaladjacency then
		adjacent = {
			{x=pos.x+1, y=pos.y, z=pos.z},
			{x=pos.x-1, y=pos.y, z=pos.z},
			{x=pos.x, y=pos.y+1, z=pos.z},
			{x=pos.x, y=pos.y-1, z=pos.z},
			{x=pos.x, y=pos.y, z=pos.z+1},
			{x=pos.x, y=pos.y, z=pos.z-1},
		}
	end

	-- Add adjacent nodes to the queue for checking.
	for k, v in ipairs(adjacent) do
		queue[#queue+1] = v
	end

	::next::
	if #queue > 0 then
		goto continue
	end

	return output
end



-- Find all nodes attached to a given node, following only nodes in
-- the given list of nodes. Uses a 'floodfill' recursive style algorithm.
function hb4.floodfill.execute(pos, nodes, max)
	local count, out = floodfill(pos, nodes, max)
	return out, count
	--return floodfill2(pos, nodes, 1, max)
end



--[===[

local function floodfill(startpos, nodelist, traversal, depth, maxdepth, output, calls)
	local hash = minetest.hash_node_position(startpos)
	local exists = false
	if traversal[hash] then
		exists = true
		if depth >= traversal[hash] then
			return calls
		end
	end

	if depth > maxdepth then
		return calls
	end

	local name = get_node_name(startpos)
	local found = false
	local normaladjacency = true
	local nodecallback

	for n, m in pairs(nodelist) do
		if n == name then
			found = true
			if type(m) == "function" then
				nodecallback = m
			elseif type(m) == "string" then
				if m == "leaf" then
					normaladjacency = false
				end
			end
			break
		end
	end

	if not found then
		return calls
	end

	traversal[hash] = depth
	if not exists then
		output[#output+1] = {pos=table.copy(startpos), name=name}
	end

	local adjacent = {}

	if nodecallback then
		-- The node callback can set the adjacency list.
		adjacent = nodecallback(startpos)
	elseif normaladjacency then
		adjacent = {
			{x=startpos.x+1, y=startpos.y, z=startpos.z},
			{x=startpos.x-1, y=startpos.y, z=startpos.z},
			{x=startpos.x, y=startpos.y+1, z=startpos.z},
			{x=startpos.x, y=startpos.y-1, z=startpos.z},
			{x=startpos.x, y=startpos.y, z=startpos.z+1},
			{x=startpos.x, y=startpos.y, z=startpos.z-1},
		}
	end

	for k, v in ipairs(adjacent) do
		calls = floodfill(v, nodelist, traversal, depth+1, maxdepth, output, calls+1)
	end

	return calls
end
--]===]

