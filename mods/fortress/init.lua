
if not minetest.global_exists("fortress") then fortress = {} end
fortress.modpath = minetest.get_modpath("fortress")
fortress.worldpath = minetest.get_worldpath()
fortress.schempath = fortress.modpath .. "/schems"

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
			pos = {x=pos.x, y=pos.y, z=pos.z},
		}
		minetest.log("action", "Computing fortress pattern @ " .. minetest.pos_to_string(vector_round(pos)) .. "!")
	end
	pos = vector_round(pos)

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
	if pos.x < (internal.pos.x - data.max_extent.x) or pos.x > (internal.pos.x + data.max_extent.x) or
			pos.y < (internal.pos.y - data.max_extent.y) or pos.y > (internal.pos.y + data.max_extent.y) or
			pos.z < (internal.pos.z - data.max_extent.z) or pos.z > (internal.pos.z + data.max_extent.z) then
		goto checkdone
	end

	if pos.x < (internal.pos.x - data.soft_extent.x) or pos.x > (internal.pos.x + data.soft_extent.x) or
			pos.y < (internal.pos.y - data.soft_extent.y) or pos.y > (internal.pos.y + data.soft_extent.y) or
			pos.z < (internal.pos.z - data.soft_extent.z) or pos.z > (internal.pos.z + data.soft_extent.z) then
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
					local p3 = vector_round(vector.add(pos, vector.multiply({x=x, y=y, z=z}, data.step)))
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
		local size = vector.multiply(info.size or {x=1, y=1, z=1}, data.step)

		-- Add schems which are part of this chunk.
		-- A chunk may have multiple schems with different parameters.
		local thischunk = info.schem
		for k, v in ipairs(thischunk) do
			local chance = v.chance or 100

			if math_random(1, 100) <= chance then
				local file = v.file
				local path = fortress.schempath .. "/" .. file .. ".mts"
				local adjust = v.adjust or {x=0, y=0, z=0}
				local force = true

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
	for dir, chunks in pairs(info.next) do
		local dirvec = keydirs[dir]
		local p2 = vector_round(vector.add(vector.multiply(dirvec, data.step), pos))

		for index, chunk in ipairs(chunks) do
			local info = data.chunks[chunk.chunk]
			-- Current chunk must have associated data.
			if not info then
				goto skipme
			end

			--minetest.chat_send_all(dump(chunk))
			local chance = chunk.chance or 100
			local limit = info.limit or 0

			-- Adjust chance if chosen chunk is over the limit for this chunk,
			-- and the chunk is limited (has a positive, non-zero limit).
			if limit > 0 then
				local limit2 = internal.limit[chunk.chunk] or 0
				if limit2 > limit then
					local diff = math_floor(limit2 - limit)
					-- Every 1 count past the limit reduces chance by 10.
					chance = chance - diff * 10
				end
			end

			-- If exceeding max soft extents, then chunk chances are always zero,
			-- and only 'fallback' chunks may be placed, if any are available.
			if exceeding_soft_extent then
				chance = 0
			end

			-- Add chunk data to fortress pattern if chance test succeeds.
			if math_random(1, 100) <= chance or chunk.fallback then
				--if exceeding_soft_extent and chunk.fallback then
				--	minetest.log("action", "Exceeding soft extent.")
				--	minetest.log("action", "Current chunk is: " .. start)
				--	minetest.log("action", "Next chunk would be: " .. chunk.chunk)
				--end

				local continue = false
				if type(chunk.continue) == "boolean" then
					continue = chunk.continue
				end
				local p3 = vector.multiply(chunk.shift or {x=0, y=0, z=0}, data.step)
				local loc = vector_round(vector.add(p3, p2))

				internal.depth = internal.depth + 1
				--minetest.log("action", "depth " .. internal.depth .. "!")

				-- Using minetest.after() to avoid stack overflow.
				-- Instead of doing recusion on the stack, we do recursion through time.
				minetest.after(0, function()
					internal.depth = internal.depth - 1
					assert(internal.depth >= 0)
					fortress.spawn_fortress(loc, data, chunk.chunk, traversal, build, internal)
				end)

				-- Generated chunk. Don't need to continue through chunks for this dir.
				if not continue then
					break
				end
			end

			::skipme::
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

	local vm = minetest.get_voxel_manip(minp, maxp)
	local replacements = {}

	for k, v in ipairs(build) do
		minetest.place_schematic_on_vmanip(vm, v.pos, v.file, v.rotation, replacements, v.force)
	end

	vm:write_to_map()
	minetest.log("action", "Finished generating fortress pattern in " .. math_floor(os.time()-internal.time) .. " seconds!")

	-- Display hash locations.
	---[[
	for k, v in pairs(traversal) do
		local p = minetest.get_position_from_hash(k)
		minetest.set_node(p, {name="wool:red"})
		local meta = minetest.get_meta(p)
		meta:set_string("infotext", "Chunk: " .. v.chunk)
	end
	--]]
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
