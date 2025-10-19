-- This file implements a *BETTER* constraint-rule based dungeon generator.

-- List of allowed chest nodes.
local CHEST_NAMES = {
	-- Duplicated for probability.
	"morechests:woodchest_public_closed",
	"morechests:woodchest_public_closed",
	"morechests:woodchest_public_closed",

	"chests:chest_public_closed",
	"morechests:ironchest_public_closed",
}

-- Map direction strings to vectors.
local KEYDIRS = {
	["+x"] = {x= 1, y= 0, z= 0},
	["-x"] = {x=-1, y= 0, z= 0},
	["+y"] = {x= 0, y= 1, z= 0},
	["-y"] = {x= 0, y=-1, z= 0},
	["+z"] = {x= 0, y= 0, z= 1},
	["-z"] = {x= 0, y= 0, z=-1},
}

local HASH_POSITION = minetest.hash_node_position
local UNHASH_POSITION = minetest.get_position_from_hash
local POS_TO_STR = minetest.pos_to_string

-- Direction names.
local DIRNAME = {
	NORTH = "+z",
	SOUTH = "-z",
	EAST  = "+x",
	WEST  = "-x",
	UP    = "+y",
	DOWN  = "-y",
}



function fortress.gen_init(spawn_pos)
	local function get_all_chunk_names(chunks)
		local name_set = {}
		for name, _ in pairs(chunks) do name_set[name] = true end
		return name_set
	end

	local params = {
		-- Algorithm start time.
		time = os.time(),

		-- NOTE: Key 'algorithm_fail' is set if something errored and NOTHING should
		-- be written to map.

		-- Commonly used items.
		spawn_pos = vector.copy(vector.round(spawn_pos)),
		step = fortress.genfort_data.step,
		max_extent = fortress.genfort_data.max_extent,
		chunks = fortress.genfort_data.chunks,
		initial_chunks = fortress.genfort_data.initial_chunks,
		replacements = fortress.genfort_data.replacements,
		schemdir = fortress.genfort_data.schemdir,

		-- The traversal "grid" (sparse). Indexed by chunk hash position.
		-- Contains entries for "fully determined" tiles, and potential neighbors.
		traversal = {
			determined = {},
			potential = {},
		},

		-- Initialize build table to an empty array. This array describes all schems
		-- which must be placed, and their parameters, once the fortress generation
		-- algorithm is complete.
		build = {
			schems = {},
			chests = {},
		},

		-- Limits. Indexed by chunk name, values are current usage count.
		chunk_limits = {},

		-- A list of ALL available chunk names defined by the data.
		-- It's useful to have this precalculated.
		chunk_names = get_all_chunk_names(fortress.genfort_data.chunks),

		-- NOTE: during mapgen, additional keys 'vm_minp' and 'vm_maxp' are added to
		-- this table. There may be others!
	}

	-- Add initial to the list of indeterminates.
	-- Just one possibility with a chance of 100.
	-- The initial chunk always begins at {x=0, y=0, z=0} in "chunk space".
	if not params.initial_chunks or #params.initial_chunks == 0 then
		return nil -- Handle error.
	end

	local initial_chunk = params.initial_chunks[
		math.random(1, #params.initial_chunks)]

	params.traversal.potential[HASH_POSITION({x=0, y=0, z=0})] = {
		[initial_chunk] = true,
	}

	return true, params
end



-- API function for mapgens.
function fortress.make_fort(spawn_pos)
	local success, params = fortress.gen_init(spawn_pos)
	if not success then return end

	minetest.log("action", "Computing fortress pattern @ " ..
		POS_TO_STR(vector.round(params.spawn_pos)) .. "!")

	local runmore = fortress.process_next_chunk(params)
	while runmore do runmore = fortress.process_next_chunk(params) end

	if not params.algorithm_fail then
		fortress.expand_all_schems(params)
		fortress.write_to_map(params)
	else
		minetest.log("error", "Something failed in fortress algorithm!")
		minetest.log("error", "Not writing anything to map.")
	end
end



-- Called from debug chatcommand.
function fortress.genfort_chatcmd(name, param)
	local player = minetest.get_player_by_name(name)
	if not player or not player:is_player() then
		return
	end

	fortress.make_fort(vector.round(player:get_pos()))
end



function fortress.expand_all_schems(params)
	local spawn_pos = params.spawn_pos
	local chunkstep = params.step

	for poshash, chunkname in pairs(params.traversal.determined) do
		local chunkpos = UNHASH_POSITION(poshash)
		local schempos = vector.add(spawn_pos, vector.multiply(chunkpos, chunkstep))
		local chunkdata = params.chunks[chunkname]
		fortress.expand_single_schem(schempos, chunkdata, params)
	end
end



function fortress.expand_single_schem(schempos, chunkdata, params)
	-- Obtain relevant parameters for this section of fortress.
	-- A chunk may contain multiple schematics to place, each with their own
	-- parameters and chance to spawn.

	-- Not all chunks specify schems, e.g., "air" chunks.
	if not chunkdata.schem then return end

	-- Calculate size of chunk. This is a rough guess which defaults to the
	-- fortress step size.
	local size = vector.multiply((chunkdata.size or {x=1, y=1, z=1}), params.step)

	-- Add schems which are part of this chunk.
	-- A chunk may have multiple schems with different parameters.
	local thischunk = chunkdata.schem
	for k, v in ipairs(thischunk) do
		local chance = v.chance or 100

		if math.random(1, 100) <= chance then
			local file = v.file
			local path = params.schemdir .. "/" .. file .. ".mts"
			local offset = table.copy(v.offset or {x=0, y=0, z=0})
			local force = true
			local priority = v.priority or 0

			-- The position adjustment setting may specify min/max values for each
			-- dimension coordinate.
			if offset.x_min then
				offset.x = math.random(offset.x_min, offset.x_max)
				offset.x_min = nil
				offset.x_max = nil
			end
			if offset.y_min then
				offset.y = math.random(offset.y_min, offset.y_max)
				offset.y_min = nil
				offset.y_max = nil
			end
			if offset.z_min then
				offset.z = math.random(offset.z_min, offset.z_max)
				offset.z_min = nil
				offset.z_max = nil
			end

			if type(v.force) == "boolean" then
				force = v.force
			end

			local rotation = v.rotation or "0"
			local realschempos = vector.add(schempos, offset)

			-- Add fortress section to construction queue.
			params.build.schems[#params.build.schems + 1] = {
				file = path,
				pos = vector.new(realschempos),
				size = size,
				rotation = rotation,
				force = force,
				replacements = params.replacements,
				priority = priority,
			}
		end
	end
end



function fortress.write_to_map(params)
	local minp = table.copy(params.spawn_pos)
	local maxp = table.copy(params.spawn_pos)

	-- Calculate voxelmanip area bounds.
	for k, v in ipairs(params.build.schems) do
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

	minetest.log("action", "Fortress POS: " .. POS_TO_STR(params.spawn_pos))
	minetest.log("action", "Fortress MINP: " .. POS_TO_STR(minp))
	minetest.log("action", "Fortress MAXP: " .. POS_TO_STR(maxp))
	minetest.log("action", "Volume: " .. POS_TO_STR(vector.subtract(maxp, minp)))

	params.vm_minp = minp
	params.vm_maxp = maxp

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
		fortress.apply_genfort(params)
	end

	-- Load entire map region, generating chunks as needed.
	-- Overgenerate ceiling to try to avoid lighting issues in caverns.
	-- Doing this seems to be the trick.
	-- This will FAIL if in cavern, but ceiling is more than 100 nodes up!
	local omaxp = vector.offset(maxp, 0, 100, 0)
	minetest.emerge_area(minp, omaxp, cb)
end



-- To be called once map region fully loaded.
function fortress.apply_genfort(params)
	local minp = table.copy(params.vm_minp)
	local maxp = table.copy(params.vm_maxp)

	if fortress.is_protected(minp, maxp) then
		minetest.log("error", "Cannot spawn fortress, protection is present.")
		return
	end

	local vm = minetest.get_voxel_manip(minp, maxp)

	-- Note: replacements can only be sensibly defined for the entire fortress
	-- sheet as a whole. Defining custom replacement lists for individual fortress
	-- sections would NOT work the way you expect! Blame Minetest.
	local rp = params.replacements or {}

	-- Sort chunks by priority. Lowest priority first. This matters for schems
	-- that have 'force' == true, since they can overwrite what's already there.
	table.sort(params.build.schems,
		function(a, b)
			return a.priority < b.priority
		end)

	for k, v in ipairs(params.build.schems) do
		minetest.place_schematic_on_vmanip(
			vm, v.pos, v.file, v.rotation, rp, v.force)
	end

	vm:write_to_map(true)

	-- Add loot chests.
	for k, v in ipairs(params.build.chests) do
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

	-- Last-ditch effort to fix these darn lighting issues.
	mapfix.work(minp, maxp)

	-- Report success, and how long it took.
	minetest.log("action", "Finished generating fortress pattern in " ..
		math.floor(os.time() - params.time) .. " seconds!")
end
