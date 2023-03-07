
net2 = net2 or {}
net2.modpath = minetest.get_modpath("networks")

-- Localize vector.distance() for performance.
local vector_distance = vector.distance

-- Network cache tables.
-- Caches are sorted first by voltage tier, then by owner,
-- and finally by hashed position.
net2.networks = net2.networks or {}
net2.networks.lv = net2.networks.lv or {}
net2.networks.mv = net2.networks.mv or {}
net2.networks.hv = net2.networks.hv or {}



-- Put energy into the network.
-- Return the amount that didn't fit.
function net2.put_energy(pos, owner, energy, tier)
	local nodes = net2.get_network(pos, owner, tier)
	local bats = nodes.batteries
	local convs = nodes.converters
	local allitems = minetest.registered_items
	for k, v in ipairs(bats) do
		local def = allitems[v.name]
		energy = def.on_energy_put(v.pos, energy)
		if energy <= 0 then
			energy = 0
			break
		end
	end
	for k, v in ipairs(convs) do
		local def = allitems[v.name]
		energy = def.on_energy_put(v.pos, energy, tier)
		if energy <= 0 then
			energy = 0
			break
		end
	end
	return energy
end



-- Get energy from the network.
-- Return the amount actually gotten.
function net2.get_energy(pos, owner, energy, tier)
	local nodes = net2.get_network(pos, owner, tier)
	local bats = nodes.batteries or {}
	local gens = nodes.generators or {}
	local total = 0
	local needed = energy
	local allitems = minetest.registered_items
	for k, v in ipairs(bats) do
		local def = allitems[v.name]
		if def.on_energy_get then
			local gotten = def.on_energy_get(v.pos, energy)
			energy = energy - gotten
			total = total + gotten
			if total >= needed then
				return total
			end
		end
	end
	for k, v in ipairs(gens) do
		local def = allitems[v.name]
		if def.on_energy_get then
			local gotten = def.on_energy_get(v.pos, energy)
			energy = energy - gotten
			total = total + gotten
			if total >= needed then
				return total
			end
		end
	end
	return total
end



-- Queued algorithm.
local function floodfill(startpos, nodelist, maxdepth, netowner)
	local traversal = {}
	local queue = {}
	local output = {}
	local curpos, hash, exists, nodename, nodeowner, found, norm, cb, count, depth
	local first = true
	local get_node_hash = minetest.hash_node_position
	local get_node_info = nodestore.get_nodename_and_realowner
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
	nodename, nodeowner = get_node_info(curpos, hash, netowner)

	-- Owner must be correct.
	if nodeowner ~= netowner then
		goto next
	end

	found = false
	norm = true
	cb = nil

	for n, m in pairs(nodelist) do
		if n == nodename then
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
		output[#output+1] = {pos=curpos, name=nodename}
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

	::next::
	first = false
	if #queue > 0 then
		goto continue
	end

	return count, output
end



-- Called from inside the floodfill algorithm.
-- This lets the floodfill algorithm find new parts of the network.
local function attached_hubs_and_nodes(pos, queue, d)
	local info = nodestore.get_hub_info(pos)

	for k, v in ipairs({
		{mp="np", me="ne", pos={x=pos.x, y=pos.y, z=pos.z+1, d=d}},
		{mp="sp", me="se", pos={x=pos.x, y=pos.y, z=pos.z-1, d=d}},
		{mp="ep", me="ee", pos={x=pos.x+1, y=pos.y, z=pos.z, d=d}},
		{mp="wp", me="we", pos={x=pos.x-1, y=pos.y, z=pos.z, d=d}},
		{mp="up", me="ue", pos={x=pos.x, y=pos.y+1, z=pos.z, d=d}},
		{mp="dp", me="de", pos={x=pos.x, y=pos.y-1, z=pos.z, d=d}},
	}) do
		local e = info[v.me]
		local got = false
		if e == 1 then
			local p = info[v.mp]
			if p then
				p.d = d
				queue[#queue+1] = p
				got = true
			end
		end
		if not got then
			queue[#queue+1] = v.pos
		end
	end
end



-- Node tables used in the floodfill algorithm.
net2.traversable = {}
net2.traversable.lv = {
	["stat2:lv"] = attached_hubs_and_nodes,
	["gen2:lv_inactive"] = "leaf",
	["gen2:lv_active"] = "leaf",
	["geo2:lv_inactive"] = "leaf",
	["geo2:lv_active"] = "leaf",
	["wat2:lv_inactive"] = "leaf",
	["wat2:lv_active"] = "leaf",
	["solar:lv"] = "leaf",
	["conv2:converter"] = "leaf",
	["grind2:lv_inactive"] = "leaf",
	["grind2:lv_active"] = "leaf",
	["ecfurn2:lv_inactive"] = "leaf",
	["ecfurn2:lv_active"] = "leaf",
	["extract2:lv_active"] = "leaf",
	["extract2:lv_inactive"] = "leaf",
	["comp2:lv_active"] = "leaf",
	["comp2:lv_inactive"] = "leaf",
	["gemcut2:lv_active"] = "leaf",
	["gemcut2:lv_inactive"] = "leaf",
	["distrib2:lv_machine"] = "leaf",
	["charger:charger"] = "leaf",
	["workshop:workshop"] = "leaf",
	["solar:panel"] = "leaf",
}
net2.traversable.mv = {
	["stat2:mv"] = attached_hubs_and_nodes,
	["gen2:mv_inactive"] = "leaf",
	["gen2:mv_active"] = "leaf",
	["solar:mv"] = "leaf",
	["windy:winder"] = "leaf",
	["tide:tide"] = "leaf",
	["breeder:inactive"] = "leaf",
	["breeder:active"] = "leaf",
	["conv2:converter"] = "leaf",
	["grind2:mv_inactive"] = "leaf",
	["grind2:mv_active"] = "leaf",
	["ecfurn2:mv_inactive"] = "leaf",
	["ecfurn2:mv_active"] = "leaf",
	["extract2:mv_active"] = "leaf",
	["extract2:mv_inactive"] = "leaf",
	["comp2:mv_active"] = "leaf",
	["comp2:mv_inactive"] = "leaf",
	["alloyf2:mv_active"] = "leaf",
	["alloyf2:mv_inactive"] = "leaf",
	["cent2:mv_active"] = "leaf",
	["cent2:mv_inactive"] = "leaf",
	["distrib2:mv_machine"] = "leaf",
}
net2.traversable.hv = {
	["stat2:hv"] = attached_hubs_and_nodes,
	["gen2:hv_inactive"] = "leaf",
	["gen2:hv_active"] = "leaf",
	["solar:hv"] = "leaf",
	["reactor:inactive"] = "leaf",
	["reactor:active"] = "leaf",
	["conv2:converter"] = "leaf",
	["ecfurn2:hv_inactive"] = "leaf",
	["ecfurn2:hv_active"] = "leaf",
	["distrib2:hv_machine"] = "leaf",
	["leecher:leecher"] = "leaf",
}

-- All machines capable of producing and buffering EUs.
net2.generators = {
	"gen2:hv_inactive",
	"gen2:hv_active",
	"solar:hv",
    "breeder:inactive",
	"breeder:active",
	"reactor:inactive",
	"reactor:active",
	"gen2:mv_inactive",
	"gen2:mv_active",
	"solar:mv",
	"windy:winder",
	"tide:tide",
	"gen2:lv_inactive",
	"gen2:lv_active",
	"geo2:lv_inactive",
	"geo2:lv_active",
	"wat2:lv_inactive",
	"wat2:lv_active",
	"solar:lv",
}

local function is_generator(name)
	for k, v in ipairs(net2.generators) do
		if v == name then
			return true
		end
	end
end

local function is_converter(name)
	if name == "conv2:converter" then
		return true
	end
end



-- Register batteries as traversable nodes.
for k, v in ipairs({
	{tier="lv"},
	{tier="mv"},
	{tier="hv"},
}) do
	-- Batteries are added to the traversability table of the same tier.
	local tb = net2.traversable[v.tier]
	for i = 0, 12, 1 do
		tb["bat2:bt" .. i .. "_" .. v.tier] = "leaf"
	end
end



-- Get a network of a voltage tier. Obtains a cached table, if possible.
-- The returned table shall contain the positions of all nodes that are
-- visible from the position of the inital node doing the scan.
function net2.get_network(pos, owner, tier)
	local hash = minetest.hash_node_position(pos)
	if not net2.networks[tier][owner] then
		net2.networks[tier][owner] = {}
	end
	local owner_cache = net2.networks[tier][owner]

	if owner_cache[hash] then
		return owner_cache[hash].nodes
	end

	local donodes = net2.traversable[tier]
	local trash, allnodes = floodfill(pos, donodes, stat2.chain_limit(tier)+3, owner)

	-- Determine network radius. This allows us to use a cool optimization.
	local rad = 0
	for k, v in ipairs(allnodes) do
		local d = vector_distance(pos, v.pos)
		if d > rad then
			rad = d
		end
	end
	-- Plus a little extra.
	rad = math.ceil(rad+2)

	local cache = {}

	cache.nodes = {}
	cache.nodes.allnodes = allnodes

	local batteries = {}
	for k, v in ipairs(allnodes) do
		if string.find(v.name, "^bat2:bt") then
			batteries[#batteries+1] = v
		end
	end

	local generators = {}
	for k, v in ipairs(allnodes) do
		if is_generator(v.name) then
			generators[#generators+1] = v
		end
	end

	local converters = {}
	for k, v in ipairs(allnodes) do
		if is_converter(v.name) then
			converters[#converters+1] = v
		end
	end

	cache.nodes.batteries = batteries
	cache.nodes.generators = generators
	cache.nodes.converters = converters
	cache.pos = pos
	cache.radius = rad

	owner_cache[hash] = cache
	return cache.nodes
end



-- Idea: If networks kept track of who owns them, we could keep networks
-- from different players seperate. Energy sharing would have to
-- be done using a special node. Thus, modifying a network belonging
-- to one player would not drop caches for a network owned by another.



-- Clear caches which may be dirty.
-- This is needed whenever a node of that tier is added or removed.
-- Pass the position of the added/removed node, its owner, and tier.
-- These 3 things are used to optimize which caches are cleared.
function net2.clear_caches(pos, owner, tier)
	local tbrm = {}
	local hash = minetest.hash_node_position(pos)
	if not net2.networks[tier][owner] then
		goto done
	end
	-- If the node itself has a cache, we always clear it.
	net2.networks[tier][owner][hash] = nil
	for k, v in pairs(net2.networks[tier][owner]) do
		-- Any caches closer than their calculated radius could be dirty.
		if vector_distance(v.pos, pos) <= v.radius then
			tbrm[#tbrm+1] = k
		end
	end
	-- Actually remove caches which could be dirty.
	for k, v in ipairs(tbrm) do
		net2.networks[tier][owner][v] = nil
	end

	::done::
end



if not net2.run_once then
  local c = "net2:core"
  local f = net2.modpath .. "/net2.lua"
  reload.register_file(c, f, false)

  net2.run_once = true
end
