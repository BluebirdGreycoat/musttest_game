
-- Todo:
-- Allow fortress chunks to extend downward without limit until rock.

fortress = fortress or {}
fortress.modpath = minetest.get_modpath("fortress")
fortress.worldpath = minetest.get_worldpath()
fortress.schempath = fortress.modpath .. "/schems"
fortress.pending = fortress.pending or {}
fortress.active = fortress.active or {}
fortress.dirty = true

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
	-- Build traversal table if not provided. The traversal table allows us to
	-- know if a section of fortress was already generated at a cell location. The
	-- table contains the hashes of locations where fortress was generated.
	if not traversal then traversal = {} end
	if not build then build = {} end
	if not internal then
		internal = {
			depth = 0,
			time = os.clock(),
			limit = {},
			pos = {x=pos.x, y=pos.y, z=pos.z},
		}
		minetest.log("action", "Computing fortress pattern @ " .. minetest.pos_to_string(vector.round(pos)) .. "!")
	end
	pos = vector.round(pos)

	-- Use `initial` if not specified.
	-- Multiple initial start-points may be specified, pick a random one.
	if not start then
		start = data.initial[math.random(1, #data.initial)]
	end

	-- Chosen chunk must have associated data.
	local info = data.chunks[start]
	if not info then goto checkdone end

	-- Use default offset if none specified.
	do
		local offset = info.offset or {x=0, y=0, z=0}
		pos = vector.round(vector.add(pos, vector.multiply(offset, data.step)))
	end

	-- Calculate all positions this chunk will potentially occupy.
	do
		local hash = minetest.hash_node_position(pos)
		local hashes = {}
		local size = info.size or {x=1, y=1, z=1}
		for x = 0, size.x-1, 1 do
			for y = 0, size.y-1, 1 do
				for z = 0, size.z-1, 1 do
					local p3 = vector.round(vector.add(pos, vector.multiply({x=x, y=y, z=z}, data.step)))
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
			traversal[v] = true
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
			if math.random(1, 100) <= chance then
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
		local p2 = vector.round(vector.add(vector.multiply(dirvec, data.step), pos))
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
					local diff = math.floor(limit2 - limit)
					-- Every 1 count past the limit reduces chance by 10.
					chance = chance - diff * 10
				end
			end

			-- Add chunk data to fortress pattern if chance test succeeds.
			if math.random(1, 100) <= chance then
				local continue = false
				if type(chunk.continue) == "boolean" then
					continue = chunk.continue
				end
				local p3 = vector.multiply(chunk.shift or {x=0, y=0, z=0}, data.step)
				local loc = vector.round(vector.add(p3, p2))
				local delay = (math.random(1, 10)/10)+1.0
				internal.depth = internal.depth + 1
				--minetest.chat_send_all("# Server: Depth " .. internal.depth .. "!")
				minetest.after(delay, function()
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
		minetest.log("action", "Finished generating fortress pattern in " .. math.floor(os.clock()-internal.time) .. " seconds!")

		-- Push build data to pending queue.
		for k, v in ipairs(build) do
			(fortress.pending)[#(fortress.pending)+1] = v
		end
		fortress.dirty = true

		-- Save data for later, perhaps after a restart.
		-- But more commonly, fortress will be generated this session.
		fortress.save_data()
	end
end



-- Using data in the pending table, construct a fortress.
-- This data is created by attempting to spawn a fortress,
-- and is saved on shutdown to allow resuming after restart.
-- This function is called once a second.
function fortress.resume_construction()
	if #fortress.pending == 0 then
		-- Nothing to write!
		return
	end
	-- Count entries in active list (starts out contigious, may have holes).
	local count = 0
	for k, v in pairs(fortress.active) do
		count = count + 1
	end
	if count > 0 then
		-- Write already in progress!
		return
	end

	-- Swap buffers.
	fortress.active = fortress.pending
	fortress.pending = {}
	fortress.dirty = true

	local internal = {
		depth = 0,
		time = os.clock(),
	}
	minetest.log("action", "Generating fortress structure!")

	-- The first time we iterate over the active list it is a contigious
	-- array. During the process that this starts, the array gains holes.
	local timer = 1
	for k, v in pairs(fortress.active) do
		internal.depth = internal.depth + 1
		minetest.after(timer, function()
			-- Positions to preload. Need a larger area in order to make sure any protections are discovered.
			local minp = vector.add(v.pos, vector.new(-16, -16, -16))
			local maxp = vector.add(v.pos, vector.add(v.size, vector.new(16, 16, 16)))

			local tbparam = {}

			-- Callback function. Will be called when area is emerged.
			local cb = function(blockpos, action, calls_remaining, param)
				-- We don't do anything until the last callback.
				if calls_remaining ~= 0 then
					-- Don't decrement the depth counter.
					-- We haven't actually done anything.
					goto checkdone
				end

				if action == core.EMERGE_CANCELLED or action == core.EMERGE_ERRORED then
					minetest.log("error", "Failed to emerge area for fortress chunk at " .. minetest.pos_to_string(v.pos) .. "!")
					-- Don't decrement the depth counter.
					-- We haven't actually done anything.
					goto checkdone
				end

				internal.depth = internal.depth - 1

				if fortress.is_protected(minp, maxp) then
					minetest.log("error", "Cannot place fortress chunk at " .. minetest.pos_to_string(v.pos) .. " due to protection!")
					fortress.active[k] = nil
					fortress.dirty = true
					goto checkdone
				end

				minetest.place_schematic(v.pos, v.file, v.rotation, {}, v.force)
				fortress.active[k] = nil
				fortress.dirty = true
				minetest.log("action", "Placed fortress section @ " .. minetest.pos_to_string(v.pos) .. "!")

				::checkdone::
				if internal.depth == 0 then
					minetest.log("action", "Fortress fully generated in " .. math.floor(os.clock()-internal.time) .. " seconds!")
					fortress.save_data()
				end
			end

			-- The fortress chunk is placed after generating map.
			minetest.emerge_area(minp, maxp, cb, tbparam)
		end)
		-- Separate calls to build fortress sections by random time, sequentially.
		timer = timer + (math.random(1, 100)/20)
	end
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



function fortress.save_data()
	if not fortress.dirty then
		return
	end
	local data = {}
	for k, v in ipairs(fortress.pending) do
		data[#data+1] = v
	end
	for k, v in pairs(fortress.active) do
		data[#data+1] = v
	end
	local str = minetest.serialize(data)
	if type(str) ~= "string" then
		return
	end
	local file = io.open(fortress.worldpath .. "/fortress.dat", "w")
	if file then
		file:write(str)
		file:close()
		minetest.log("action", "Saved " .. #data .. " pending fortress sections!")
		fortress.dirty = false
	end
end



function fortress.load_data()
	local file = io.open(fortress.worldpath .. "/fortress.dat", "r")
	if file then
		-- Data should always be a contigious array.
		local data = minetest.deserialize(file:read("*all"))
		if type(data) == "table" then
			fortress.pending = data
			fortress.dirty = false
		end
		file:close()
		minetest.log("action", "Loaded " .. #data .. " pending fortress sections!")
	end
end



function fortress.chat_command(name, param)
	local player = minetest.get_player_by_name(name)
	if not player or not player:is_player() then
		return
	end

	local pos = vector.round(player:get_pos())
	fortress.spawn_fortress(pos, fortress.default)
end



if not fortress.run_once then
	fortress.load_data()

	local delay = 1
	local timer = 0
	minetest.register_globalstep(function(dtime)
		timer = timer + dtime
		if timer < delay then
			return
		end
		timer = 0
		return fortress.resume_construction()
	end)

	minetest.register_on_shutdown(function()
		return fortress.save_data()
	end)
	minetest.register_on_mapsave(function()
		return fortress.save_data()
	end)

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
