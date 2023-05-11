
if not minetest.global_exists("fortress") then fortress = {} end
fortress.modpath = minetest.get_modpath("fortress")
fortress.worldpath = minetest.get_worldpath()
fortress.schempath = fortress.modpath .. "/schems"

if fortress.debug_layout == nil then
	fortress.debug_layout = false
end

-- Localize for performance.
local vector_round = vector.round
local math_floor = math.floor
local math_random = math.random

-- Default fortress definition.
dofile(fortress.modpath .. "/default.lua")



local keydirs = {
	["+x"] = {x=1, y=0, z=0},
	["-x"] = {x=-1, y=0, z=0},
	["+y"] = {x=0, y=1, z=0},
	["-y"] = {x=0, y=-1, z=0},
	["+z"] = {x=0, y=0, z=1},
	["-z"] = {x=0, y=0, z=-1},
}

-- Spawn a fortress starting at a position.
-- Public API function. Pass valid values for `pos` and `data`.
function fortress.spawn_fortress(pos, data, start, traversal, build, internal)
	local exceeding_soft_extent = false

	-- For debugging.
	--exceeding_soft_extent = true

	-- Build traversal table if not provided. The traversal table allows us to
	-- know if a section of fortress was already generated at a cell location. The
	-- table contains the hashes of locations where fortress was generated.
	if not traversal then traversal = {} end
	if not build then build = {} end
	if not internal then
		internal = {
			-- Recursion depth.
			depth = 0,

			-- Algorithm start time.
			time = os.time(),

			-- Storage for limits information.
			limit = {},

			-- Initial starting position.
			pos = vector.round({x=pos.x, y=pos.y, z=pos.z}),

			-- Reference to the fortress data sheet.
			data = data,

			-- Step size.
			step = table.copy(data.step),

			-- Max/soft extents.
			max_extent = table.copy(data.max_extent),
			soft_extent = table.copy(data.soft_extent),
		}
		minetest.log("action", "Computing fortress pattern @ " .. minetest.pos_to_string(vector_round(pos)) .. "!")
	end
	pos = vector_round(pos)

	-- In debug layout mode, make SMALLER fortresses.
	if fortress.debug_layout then
		internal.step = {x=1, y=1, z=1}
		internal.max_extent = vector.round(vector.divide(data.max_extent, data.step))
		internal.soft_extent = vector.round(vector.divide(data.soft_extent, data.step))
	end

	-- Use `initial` if not specified.
	-- Multiple initial start-points may be specified, pick a random one.
	if not start then
		start = data.initial[math_random(1, #data.initial)]
	end

	-- Chosen chunk must have associated data.
	local info = data.chunks[start]
	if not info then goto checkdone end

	-- Distance from inital pos must not be too large! Hard abort.
	-- This prevents trying to generate HUGE fortresses that would slow things.
	if pos.x < (internal.pos.x - internal.max_extent.x) or pos.x > (internal.pos.x + internal.max_extent.x) or
			pos.y < (internal.pos.y - internal.max_extent.y) or pos.y > (internal.pos.y + internal.max_extent.y) or
			pos.z < (internal.pos.z - internal.max_extent.z) or pos.z > (internal.pos.z + internal.max_extent.z) then
		--minetest.log('action', 'stopping placement of ' .. start)
		goto checkdone
	end

	if pos.x < (internal.pos.x - internal.soft_extent.x) or pos.x > (internal.pos.x + internal.soft_extent.x) or
			pos.y < (internal.pos.y - internal.soft_extent.y) or pos.y > (internal.pos.y + internal.soft_extent.y) or
			pos.z < (internal.pos.z - internal.soft_extent.z) or pos.z > (internal.pos.z + internal.soft_extent.z) then
		exceeding_soft_extent = true
	end

	-- Calculate all positions this chunk will potentially occupy.
	-- This adds a position hash for each possible location from 'offset' to
	-- 'size'. The position hashes are sparse, so this is more efficient than it
	-- looks.
	do
		local hash = minetest.hash_node_position(pos)
		local hashes = {}
		local size = info.size or {x=1, y=1, z=1}
		for x = 0, size.x-1, 1 do
			for y = 0, size.y-1, 1 do
				for z = 0, size.z-1, 1 do
					local p3 = vector_round(vector.add(pos, vector.multiply({x=x, y=y, z=z}, internal.step)))
					local hash = minetest.hash_node_position(p3)
					hashes[#hashes+1] = hash
				end
			end
		end

		-- Do nothing if this chunk already occupied.
		for k, v in ipairs(hashes) do
			if traversal[v] then
				goto checkdone
			end
		end

		-- Occupy this chunk!
		for k, v in ipairs(hashes) do
			traversal[v] = {
				-- Store chunk name for debugging.
				-- It will be stored in "infotext" metadata for manual inspection.
				chunk = start,
			}
		end
	end

	-- Obtain relevant parameters for this section of fortress.
	-- A chunk may contain multiple schematics to place, each with their own
	-- parameters and chance to spawn.
	do
		-- Chunks may be limited how often they can be used in the fortress pattern.
		-- Here, we increment limit if limit is finite (non-zero).
		-- Elsewhere in code we read the current limit and reduce chance of
		-- chunk being chosen accordingly. Zero means no limit imposed.
		local limit = info.limit or 0
		internal.limit[start] = internal.limit[start] or 0
		if limit > 0 then
			internal.limit[start] = internal.limit[start] + 1
		end

		-- Calculate size of chunk.
		local size = vector.multiply(info.size or {x=1, y=1, z=1}, internal.step)

		-- Add schems which are part of this chunk.
		-- A chunk may have multiple schems with different parameters.
		local thischunk = info.schem
		for k, v in ipairs(thischunk) do
			local chance = v.chance or 100

			if math_random(1, 100) <= chance then
				local file = v.file
				local path = fortress.schempath .. "/" .. file .. ".mts"
				local adjust = table.copy(v.adjust or {x=0, y=0, z=0})
				local force = true

				-- The position adjustment setting may specify min/max values for each
				-- dimension coordinate.
				if adjust.x_min then
					adjust.x = math_random(adjust.x_min, adjust.x_max)
					adjust.x_min = nil
					adjust.x_max = nil
				end
				if adjust.y_min then
					adjust.y = math_random(adjust.y_min, adjust.y_max)
					adjust.y_min = nil
					adjust.y_max = nil
				end
				if adjust.z_min then
					adjust.z = math_random(adjust.z_min, adjust.z_max)
					adjust.z_min = nil
					adjust.z_max = nil
				end

				if type(v.force) == "boolean" then
					force = v.force
				end

				local rotation = v.rotation or "0"
				local schempos = vector.add(pos, adjust)

				-- Add fortress section to construction queue.
				build[#build+1] = {
					file = path,
					pos = vector.new(schempos),
					size = size,
					rotation = rotation,
					force = force,
					replacements = data.replacements,
				}
			end
		end
	end

	-- Current chunk may not have next chunks defined.
	-- Thus we have reached a dead-end.
	if not info.next then
		goto checkdone
	end

	-- Recursively generate further chunks.
	for dir, chunks4dir in pairs(info.next) do
		local dirvec = keydirs[dir]
		local p2 = vector_round(vector.add(vector.multiply(dirvec, internal.step), pos))

		-- We're looking at the direction-specific neighbor list.
		-- Add up the max chance value by accumulating each chunk's individual chance.
		-- This complicated chance-calculation code is simply to give all chunks a
		-- relatively fair chance to be chosen, regardless of their absolute chance
		-- values.
		local all_chance = {}
		local max_chance = 0
		local avg_chance = 0

		-- First, calculate the average chance of all chunks having a chance specified.
		-- The average chance becomes the default chance for any chunks not having their
		-- chance specified, in later calculations.
		local chunks_with_chance = 0
		for index, neighbor in ipairs(chunks4dir) do
			if neighbor.chance then
				if neighbor.chance > 0 then
					avg_chance = avg_chance + neighbor.chance
					chunks_with_chance = chunks_with_chance + 1
				end
			end
		end
		if chunks_with_chance > 0 then
			avg_chance = math.floor(avg_chance / chunks_with_chance)
		end
		if avg_chance <= 0 then
			avg_chance = 1
		end

		-- Calculate each chunk's chance range (min, max).
		-- If the neighbor is a fallback, and its chance is not specified, then by
		-- default its chance is 1/4 the average chance of all other chunks.
		for index, neighbor in ipairs(chunks4dir) do
			-- Default fallback chance is 1/4 the average chance, but can't be less than 1.
			-- To make the chance for a fallback section 0, you must explicitly set the chance.
			local def_fb_chance = math.max(math.floor(avg_chance / 4), 1)
			local chunk_chance = math.floor(neighbor.chance or ((neighbor.fallback and def_fb_chance) or avg_chance))
			local chunk_limit = (info and info.limit) or 0

			-- Zeroize chance if chosen chunk is over the limit for this chunk,
			-- and the chunk is limited (has a positive, non-zero limit).
			if chunk_limit > 0 then
				local count = internal.limit[neighbor.chunk] or 0
				if count > chunk_limit then
					chunk_chance = 0
				end
			end

			-- If exceeding max soft extents, then chunk chances are always zero,
			-- and only 'fallback' chunks may be placed, if any are available.
			if exceeding_soft_extent then
				chunk_chance = 0
			end

			if chunk_chance > 0 then
				local cur_chance = max_chance + 1
				max_chance = max_chance + chunk_chance
				all_chance[neighbor.chunk] = {min=cur_chance, max=max_chance}

				-- Check that the 'chance ranges' are in consecutive order with no gaps.
				--minetest.log('action', neighbor.chunk .. " CHANCE: min=" .. all_chance[neighbor.chunk].min .. ", max=" .. all_chance[neighbor.chunk].max)
			end
		end

		-- Get a random number between 1 and max chance value.
		-- If 0, then random chance was NOT chosen!
		local random_chance = 0
		if max_chance >= 1 then
			random_chance = math.random(1, max_chance)
		end

		--[[
		minetest.log('action', start .. ":" .. dir .. ": avg chance is " .. avg_chance)
		minetest.log('action', start .. ":" .. dir .. ": max chance is " .. max_chance)
		minetest.log('action', start .. ":" .. dir .. ": rnd chance is " .. random_chance)
		--]]

		-- Null chance range.
		local fallback_range = {min=0, max=0}

		-- For all chunks in direction-specific neighbor list (+/-X, +/-Y, +/-Z).
		for index, neighbor in ipairs(chunks4dir) do
			-- Chunk's chance range, or null range if not present.
			local chance_range = all_chance[neighbor.chunk] or fallback_range
			--minetest.log('action', neighbor.chunk .. " chance: min=" .. chance_range.min .. ", max=" .. chance_range.max)

			-- Add chunk data to fortress pattern if chance test succeeds.
			-- Note that once a chunk passes the 'chance test', no further chunk will
			-- be checked/added, UNLESS the 'continue' flag was set on the successful chunk.
			if (random_chance > 0 and random_chance >= chance_range.min and random_chance <= chance_range.max)
					or neighbor.fallback then
				-- If chunk had the 'fallback' flag set, it is ALWAYS permitted.
				-- For this reason you should ensure that 'fallback' chunks always come
				-- last in their list, otherwise you WILL get overlaps. Multiple fallback
				-- chunks will overlap. This may or may not be a problem for you.

				--[[
				if dir == "+x" or dir == "-x" or dir == "+z" or dir == "-z" then
					minetest.log('action', 'looking at: ' .. neighbor.chunk)
				end
				--]]

				local continue = false
				if type(neighbor.continue) == "boolean" then
					continue = neighbor.continue
				end

				local p3 = vector.multiply(neighbor.shift or {x=0, y=0, z=0}, internal.step)
				local loc = vector_round(vector.add(p3, p2))

				internal.depth = internal.depth + 1
				--minetest.log("action", "depth " .. internal.depth .. "!")

				-- Using minetest.after() to avoid stack overflow.
				-- Instead of doing recusion on the stack, we do recursion through time.
				minetest.after(0, function()
					internal.depth = internal.depth - 1
					assert(internal.depth >= 0)
					fortress.spawn_fortress(loc, data, neighbor.chunk, traversal, build, internal)
				end)

				-- Generated chunk. Don't need to continue through chunks for this dir.
				if not continue then
					break
				end
			end
		end
	end

	-- Check if all build-data is gathered yet.
	::checkdone::
	if internal.depth == 0 then
		local minp = table.copy(internal.pos)
		local maxp = table.copy(internal.pos)

		-- Calculate voxelmanip area bounds.
		for k, v in ipairs(build) do
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

		minetest.log("action", "Fortress pos: " .. minetest.pos_to_string(internal.pos))
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
			fortress.apply_design(internal, traversal, build)
		end

		minetest.emerge_area(minp, maxp, cb)
	end
end



-- To be called once map region fully loaded.
function fortress.apply_design(internal, traversal, build)
	local minp = table.copy(internal.vm_minp)
	local maxp = table.copy(internal.vm_maxp)

	if fortress.is_protected(minp, maxp) then
		minetest.log("error", "Cannot spawn fortress, protection is present.")
		return
	end

	if not fortress.debug_layout then
		local vm = minetest.get_voxel_manip(minp, maxp)

		-- Note: replacements can only be sensibly defined for the entire fortress
		-- sheet as a whole. Defining custom replacement lists for individual fortress
		-- sections would NOT work the way you expect! Blame Minetest.
		local rp = internal.data.replacements or {}

		for k, v in ipairs(build) do
			minetest.place_schematic_on_vmanip(vm, v.pos, v.file, v.rotation, rp, v.force)
		end

		vm:write_to_map()
	end

	-- Display hash locations.
	if fortress.debug_layout then
		for k, v in pairs(traversal) do
			local p = minetest.get_position_from_hash(k)
			minetest.set_node(p, {name="wool:red"})
			local meta = minetest.get_meta(p)
			meta:set_string("infotext", "Chunk: " .. v.chunk)
		end
	end

	minetest.log("action", "Finished generating fortress pattern in " .. math_floor(os.time()-internal.time) .. " seconds!")
end



-- Quickly check for protection in an area.
function fortress.is_protected(minp, maxp)
	-- Step size, to avoid checking every single node.
	-- This assumes protections cannot be smaller than this size.
	local ss = 5
	local check = minetest.test_protection

	for x=minp.x, maxp.x, ss do
		for y=minp.y, maxp.y, ss do
			for z=minp.z, maxp.z, ss do
				if check({x=x, y=y, z=z}, "") then
					-- Protections are present.
					return true
				end
			end
		end
	end

	-- Nothing in the area is protected.
	return false
end



-- Public API function.
-- Name must be a fortress data sheet.
function fortress.generate(pos, name)
	if fortress[name] then
		fortress.spawn_fortress(pos, fortress[name])
	end
end



function fortress.chat_command(name, param)
	local player = minetest.get_player_by_name(name)
	if not player or not player:is_player() then
		return
	end

	local pos = vector_round(player:get_pos())
	fortress.spawn_fortress(pos, fortress.default)
end



if not fortress.run_once then
	minetest.register_chatcommand("spawn_fortress", {
		params = "",
		description = "Spawn a fortress starting at your current location.",
		privs = {server=true},

		func = function(...)
			fortress.chat_command(...)
			return true
		end,
	})

	local c = "fortress:core"
	local f = fortress.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	fortress.run_once = true
end
