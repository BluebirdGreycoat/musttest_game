-- This file implements a constraint-rule based dungeon generator.
--[===[

local CHEST_NAMES = {
	"morechests:woodchest_public_closed",
	"chests:chest_public_closed",
	"morechests:ironchest_public_closed",
}

-- Map direction strings to vectors.
local KEYDIRS = {
	["+x"] = {x=1, y=0, z=0},
	["-x"] = {x=-1, y=0, z=0},
	["+y"] = {x=0, y=1, z=0},
	["-y"] = {x=0, y=-1, z=0},
	["+z"] = {x=0, y=0, z=1},
	["-z"] = {x=0, y=0, z=-1},
}

local HASH_POSITION = minetest.hash_node_position
local UNHASH_POSITION = minetest.get_position_from_hash



local function initialize_params(pos, data, start, traversal, build, internal)
	-- Build traversal table if not provided. The traversal table allows us to
	-- know if a section of fortress was already generated at a cell location. The
	-- table contains the hashes of locations where fortress was generated.
	if not traversal then
		traversal = {
			-- List of positions to be determined, indexed by pos hash.
			-- Values are tables like: {chunk="chunkname", chance=100, ...}
			indeterminate = {},

			-- List of fully determined positions, indexed by pos hash.
			-- Values are strings like: "chunkname"
			determined = {},
		}
	end

	-- Initialize build table to an empty array. This array describes all schems
	-- which must be placed, and their parameters, once the fortress generation
	-- algorithm is complete.
	if not build then
		build = {
			schems = {},
			chests = {},
		}
	end

	if not internal then
		internal = {
			-- Algorithm start time.
			time = os.time(),

			-- Initial starting position.
			spawn_pos = vector.round({x=pos.x, y=pos.y, z=pos.z}),

			-- Reference to the fortress data sheet.
			data = data,

			-- Step size.
			step = table.copy(data.step),

			-- Extents.
			max_extent = table.copy(data.max_extent),

			-- Limits. Indexed by chunk name, values are current usage count.
			limits = {},
		}

		minetest.log("action", "Computing fortress pattern @ " ..
			minetest.pos_to_string(vector.round(pos)) .. "!")
	end

	-- Ensure the start position is rounded. Floating positions can screw us up!
	pos = vector.round(pos)

	-- Use `initial` if not specified.
	-- Multiple initial start-points may be specified, pick a random one.
	if not start then
		start = data.initial[math.random(1, #data.initial)]
	end

	-- Add initial to the list of indeterminates.
	-- Just one possibility with a chance of 100.
	-- The initial chunk always begins at {x=0, y=0, z=0} in "chunk space".
	traversal.indeterminate[HASH_POSITION({x=0, y=0, z=0})] = {
		{chunk=start, chance=100},
	}

	return pos, data, start, traversal, build, internal
end



local function add_schematics(pos, info, internal, traversal, build)
	-- Obtain relevant parameters for this section of fortress.
	-- A chunk may contain multiple schematics to place, each with their own
	-- parameters and chance to spawn.

	-- Calculate size of chunk.
	local size = vector.multiply(info.size or {x=1, y=1, z=1}, internal.step)

	-- Add schems which are part of this chunk.
	-- A chunk may have multiple schems with different parameters.
	local thischunk = info.schem
	for k, v in ipairs(thischunk) do
		local chance = v.chance or 100

		if math.random(1, 100) <= chance then
			local file = v.file
			local path = internal.data.schemdir .. "/" .. file .. ".mts"
			local adjust = table.copy(v.adjust or {x=0, y=0, z=0})
			local force = true
			local priority = v.priority or 0

			-- The position adjustment setting may specify min/max values for each
			-- dimension coordinate.
			if adjust.x_min then
				adjust.x = math.random(adjust.x_min, adjust.x_max)
				adjust.x_min = nil
				adjust.x_max = nil
			end
			if adjust.y_min then
				adjust.y = math.random(adjust.y_min, adjust.y_max)
				adjust.y_min = nil
				adjust.y_max = nil
			end
			if adjust.z_min then
				adjust.z = math.random(adjust.z_min, adjust.z_max)
				adjust.z_min = nil
				adjust.z_max = nil
			end

			if type(v.force) == "boolean" then
				force = v.force
			end

			local rotation = v.rotation or "0"
			local schempos = vector.add(pos, adjust)

			-- Add fortress section to construction queue.
			build.schems[(#build.schems)+1] = {
				file = path,
				pos = vector.new(schempos),
				size = size,
				rotation = rotation,
				force = force,
				replacements = internal.data.replacements,
				priority = priority,
			}
		end
	end
end



-- To be called once map region fully loaded.
local function apply_fortress_design(internal, traversal, build)
	local minp = table.copy(internal.vm_minp)
	local maxp = table.copy(internal.vm_maxp)

	if fortress.is_protected(minp, maxp) then
		minetest.log("error", "Cannot spawn fortress, protection is present.")
		return
	end

	local vm = minetest.get_voxel_manip(minp, maxp)

	-- Note: replacements can only be sensibly defined for the entire fortress
	-- sheet as a whole. Defining custom replacement lists for individual fortress
	-- sections would NOT work the way you expect! Blame Minetest.
	local rp = internal.data.replacements or {}

	-- Sort chunks by priority. Lowest priority first. This matters for schems
	-- that have 'force' == true, since they can overwrite what's already there.
	table.sort(build.schems,
		function(a, b)
			return a.priority < b.priority
		end)

	for k, v in ipairs(build.schems) do
		minetest.place_schematic_on_vmanip(
			vm, v.pos, v.file, v.rotation, rp, v.force)
	end

	vm:write_to_map(true)

	-- Add loot chests.
	for k, v in ipairs(build.chests) do
		local p = v.pos
		local n = minetest.get_node(p)

		-- Only if location not already occupied.
		if n.name == "air" then
			local param2 = math.random(0, 3)
			local cname = CHEST_NAMES[math.random(1, #CHEST_NAMES)]
			minetest.set_node(p, {name=cname, param2=param2})
			fortress.add_loot_items(p, v.loot)
		end
	end

	mapfix.work(minp, maxp)
	minetest.log("action", "Finished generating fortress pattern in " ..
		math.floor(os.time()-internal.time) .. " seconds!")
end



local function write_fortress_to_map(internal, traversal, build)
	local minp = table.copy(internal.spawn_pos)
	local maxp = table.copy(internal.spawn_pos)

	-- Calculate voxelmanip area bounds.
	for k, v in ipairs(build.schems) do
		if v.pos.x < minp.x then
			minp.x = v.pos.x
		end
		if v.pos.x + v.size.x > maxp.x then
			maxp.x = v.pos.x + v.size.x
		end

		if v.pos.y < minp.y then
			minp.y = v.pos.y
		end
		if v.pos.y + v.size.y > maxp.y then
			maxp.y = v.pos.y + v.size.y
		end

		if v.pos.z < minp.z then
			minp.z = v.pos.z
		end
		if v.pos.z + v.size.z > maxp.z then
			maxp.z = v.pos.z + v.size.z
		end
	end

	minetest.log("action", "Fortress pos: " ..
		minetest.pos_to_string(internal.spawn_pos))
	minetest.log("action", "Fortress minp: " .. minetest.pos_to_string(minp))
	minetest.log("action", "Fortress maxp: " .. minetest.pos_to_string(maxp))

	internal.vm_minp = minp
	internal.vm_maxp = maxp

	-- Build callback function. When the map is loaded, we can spawn the fortress.
	local cb = function(blockpos, action, calls_remaining)
		-- Check if there was an error.
		if action == core.EMERGE_CANCELLED or action == core.EMERGE_ERRORED then
			minetest.log("error", "Failed to emerge area to spawn fortress.")
			return
		end

		-- We don't do anything until the last callback.
		if calls_remaining ~= 0 then
			return
		end

		-- Actually spawn the fortress once map completely loaded.
		apply_fortress_design(internal, traversal, build)
	end

	-- Load entire map region, generating chunks as needed.
	-- Overgenerate ceiling to try to avoid lighting issues in caverns.
	-- Doing this seems to be the trick.
	-- This will FAIL if in cavern, but ceiling is more than 100 nodes up!
	local omaxp = vector.offset(maxp, 0, 100, 0)
	minetest.emerge_area(minp, omaxp, cb)
end



local function space_free(chunkpos, chunkdata, traversal)
	-- Calculate all positions this chunk will potentially occupy.
	-- This adds a position hash for each possible location from 'offset' to
	-- 'size'. The position hashes are sparse, so this is more efficient than it
	-- looks.
	local hashes = {}
	local size = chunkdata.size or {x=1, y=1, z=1}

	for x = 0, size.x - 1, 1 do
		for y = 0, size.y - 1, 1 do
			for z = 0, size.z - 1, 1 do
				local curpos = {x=x, y=y, z=z}
				local p3 = vector.add(chunkpos, curpos)
				local hash = HASH_POSITION(p3)
				hashes[#hashes + 1] = hash
			end
		end
	end

	-- Do nothing if this chunk already occupied.
	for _, hash in ipairs(hashes) do
		if traversal.determined[hash] or traversal.indeterminate[hash] then
			return false
		end
	end

	return true
end



local function claim_space(chunkpos, chunkname, chunkdata, traversal)
	-- Calculate all positions this chunk will potentially occupy.
	-- This adds a position hash for each possible location from 'offset' to
	-- 'size'. The position hashes are sparse, so this is more efficient than it
	-- looks.
	local hashes = {}
	local size = chunkdata.size or {x=1, y=1, z=1}

	for x = 0, size.x - 1, 1 do
		for y = 0, size.y - 1, 1 do
			for z = 0, size.z - 1, 1 do
				local curpos = {x=x, y=y, z=z}
				local p3 = vector.add(chunkpos, curpos)
				local hash = HASH_POSITION(p3)
				hashes[#hashes + 1] = hash
			end
		end
	end

	-- Occupy this chunk!
	for _, hash in ipairs(hashes) do
		traversal.determined[hash] = {
			-- Store chunk name for debugging.
			-- It will be stored in "infotext" metadata for manual inspection.
			chunk = chunkname,

			-- Indicates that this is a placeholder entry in the traversal table.
			-- This is needed to support large chunks that cover multiple tiles.
			placeholder = true,
		}
	end

	-- Returns chunk-space position hashes.
	return hashes
end



-- Process the next (single) chunk to fully determine.
-- Returns its position hash (chunk pos) or nil, if nothing indeterminate.
local function determine_next_chunk(data, traversal, build, internal)
	local chunkposhash, allowedchunks = next(traversal.indeterminate)

	-- If table is empty ...
	if not chunkposhash then return end

	if #allowedchunks > 0 then
		-- Step 0: select a random chunk from the list of possibilities.
		local chunkname = allowedchunks[math.random(1, #allowedchunks)].chunk
		local chunkpos = UNHASH_POSITION(chunkposhash)
		local chunkdata = data.chunks[chunkname]

		-- Step 1: add current chunk to list of fully-determined chunks.
		-- Remove this entry from the list of indeterminate (possible) chunks.
		local otherhashes = claim_space(chunkpos, chunkname, chunkdata, traversal)
		traversal.determined[chunkposhash] = {chunk=chunkname}
		traversal.indeterminate[chunkposhash] = nil

		-- Update limits count.
		internal.limits[chunkname] = (internal.limits[chunkname] or 0) + 1

		return chunkname, chunkposhash, otherhashes, allowedchunks
	end
end



-- Return the INTERSECTION of 2 chunk arrays (an array which only contains
-- entries that are present in BOTH input arrays).
local function get_chunk_intersection(entries, neighbors)
	local chunk_set = {}

	for _, m in ipairs(neighbors) do
		chunk_set[m.chunk] = true
	end

	local t = {}

	for _, v in ipairs(entries) do
		if chunk_set[v.chunk] then
			t[#t + 1] = v
		end
	end

	return t
end



local function chunkpos_ok(pos, internal)
	local minp = {
		x = -internal.max_extent.x,
		y = -internal.max_extent.y,
		z = -internal.max_extent.z,
	}
	local maxp = {
		x = internal.max_extent.x,
		y = internal.max_extent.y,
		z = internal.max_extent.z,
	}

	if pos.x >= minp.x and pos.x <= maxp.x
			and pos.y >= minp.y and pos.y <= maxp.y
			and pos.z >= minp.z and pos.z <= maxp.z then
		return true
	end
end



local function filter_chunk_limits(data, neighbors, internal)
	local t = {}

	for _, neighborinfo in ipairs(neighbors) do
		if data.chunks[neighborinfo.chunk].limit then
			if (internal.limits[neighborinfo.chunk] or 0)
					< data.chunks[neighborinfo.chunk].limit then
				t[#t + 1] = neighborinfo
			end
		else
			t[#t + 1] = neighborinfo
		end
	end

	return t
end



-- Must return true if all neighbors updated successfully.
local function update_chunk_neighbors(chunkposhash, data, traversal, internal)
	local chunkpos = UNHASH_POSITION(chunkposhash)
	local chunkname = traversal.determined[chunkposhash].chunk
	local chunkdata = data.chunks[chunkname]
	local chunkneighbors = chunkdata.next

	-- Chunk might not define any neighbors.
	if not chunkneighbors then
		return true
	end

	local combinedneighbors = {}
	local neighborsgood = {}

	-- Update neighbor positions of current chunk with allowed chunks.
	-- This means creating/updating a list of allowed chunks for each position.
	for dirkey, neighbors in pairs(chunkneighbors) do
		-- 'neighbors' is an array like so: {{chunk="name1"}, {chunk="name2"}, ...}
		local filteredneighbors = filter_chunk_limits(data, neighbors, internal)
		local neighborpos = vector.add(chunkpos, KEYDIRS[dirkey])
		local neighborhash = HASH_POSITION(neighborpos)

		-- Skip neighbor locations already fully determined.
		-- Note: the determined chunkname for this neighbor should always be one of
		-- the allowed neighbors of the current chunk. Otherwise we're in trouble.
		if not traversal.determined[neighborhash]
				and chunkpos_ok(neighborpos, internal) then
			if not traversal.indeterminate[neighborhash] then
				combinedneighbors[neighborhash] = filteredneighbors
				neighborsgood[neighborhash] = true
			else
				local oldlist = traversal.indeterminate[neighborhash]
				local newlist = get_chunk_intersection(oldlist, filteredneighbors)

				if #newlist > 0 then
					combinedneighbors[neighborhash] = newlist
					neighborsgood[neighborhash] = true
				else
					neighborsgood[neighborhash] = false
				end
			end
		end
	end

	-- If any neighbors are marked bad, we fail.
	for k, v in pairs(neighborsgood) do
		if not v then return end
	end

	-- Apply all updated neighbor lists to the traversal 'indeterminate' table.
	for neighborhash, neighborlist in pairs(combinedneighbors) do
		traversal.indeterminate[neighborhash] = neighborlist
	end

	return true
end



local function expand_all_chunkschems(data, traversal, build, internal)
	local spawnpos = internal.spawn_pos
	local chunkstep = internal.step

	for poshash, entryinfo in pairs(traversal.determined) do
		-- Skip placeholder entries (supports large chunks).
		if not entryinfo.placeholder then
			local chunkname = entryinfo.chunk
			local chunkpos = UNHASH_POSITION(poshash)
			local schempos = vector.add(spawnpos,
				vector.multiply(chunkpos, chunkstep))
			local chunkdata = data.chunks[chunkname]
			add_schematics(schempos, chunkdata, internal, traversal, build)
		end
	end
end



-- User provides only 'pos' and 'data'. All other paremeters are internal use.
local function generate_fortress(pos, data, start, traversal, build, internal)
	-- Initialize if needed.
	pos, data, start, traversal, build, internal =
		initialize_params(pos, data, start, traversal, build, internal)

	local chunkname,
		chunkposhash,
		otherhashes,
		prevallowedchunks

	chunkname, chunkposhash, otherhashes, prevallowedchunks
		= determine_next_chunk(data, traversal, build, internal)

	while chunkposhash do
		if update_chunk_neighbors(chunkposhash, data, traversal, internal) then
			chunkname, chunkposhash, otherhashes, prevallowedchunks
				= determine_next_chunk(data, traversal, build, internal)
		else
			-- Backtrack.
			traversal.indeterminate[chunkposhash] = prevallowedchunks
			traversal.determined[chunkposhash] = nil
			internal.limits[chunkname] = internal.limits[chunkname] - 1

			for _, hash in ipairs(otherhashes) do
				traversal.determined[hash] = nil
			end
		end
	end

	-- Done, write everything to the map after C++ mapgen finishes.
	expand_all_chunkschems(data, traversal, build, internal)
	write_fortress_to_map(internal, traversal, build)
end



-- Public API function.
function fortress.generate_wfc(pos, data)
	generate_fortress(pos, data)
end



function fortress.chat_command_wfc(name, param)
	local player = minetest.get_player_by_name(name)
	if not player or not player:is_player() then
		return
	end

	local pos = vector.round(player:get_pos())
	fortress.generate_wfc(pos, fortress.newfort_data)
end
--]===]
