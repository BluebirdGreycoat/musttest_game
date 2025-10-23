
local HASH_POSITION = minetest.hash_node_position
local UNHASH_POSITION = minetest.get_position_from_hash
local POS_TO_STR = minetest.pos_to_string



function fortress.v2.process_layout(params)
	local spawn_pos = params.spawn_pos
	local chunkstep = params.step
	local vec_add = vector.add
	local vec_mul = vector.multiply
	local completed = params.traversal.completed

	for poshash, chunkname in pairs(params.traversal.determined) do
		-- Don't repeat if already done.
		if not completed[poshash] then
			local chunkpos = UNHASH_POSITION(poshash)
			local schempos = vec_add(spawn_pos, vec_mul(chunkpos, chunkstep))
			local altname = params.override_chunk_schems[poshash]

			if altname then
				-- If we got IGNORE at this position from 'override_chunk_schems', then
				-- don't place any schematics.
				if altname ~= "IGNORE" then
					local chunkdata = params.chunks[altname]
					fortress.v2.expand_single_schem(schempos, chunkdata, params)
					fortress.v2.collect_chests(schempos, chunkdata, params)
				end
			else
				local chunkdata = params.chunks[chunkname]
				fortress.v2.expand_single_schem(schempos, chunkdata, params)
				fortress.v2.collect_chests(schempos, chunkdata, params)
			end
		end

		-- Mark as done.
		completed[poshash] = true
	end

	local schem_count = #params.build.schems
	local chest_count = #params.build.chests

	params.log("action", "Added " .. schem_count .. " schems to fortress.")
	params.log("action", "Added " .. chest_count .. " chests to fortress.")
end



function fortress.v2.expand_single_schem(schempos, chunkdata, params)
	-- Obtain relevant parameters for this section of fortress.
	-- A chunk may contain multiple schematics to place, each with their own
	-- parameters and chance to spawn.

	-- Not all chunks specify schems, e.g., "air" chunks.
	if not chunkdata.schem then return end

	-- Calculate size of chunk. A rough guess which defaults to step size.
	local size = vector.multiply((chunkdata.size or {x=1, y=1, z=1}), params.step)
	local random = params.yeskings
	local thischunk = chunkdata.schem
	local all_schems = params.build.schems

	-- Will store the names of excluded schem files.
	-- We allow schems to be defined as excluding the possibility of other schems,
	-- if placed. Exclusions are processed (and handled) in the order they appear
	-- in the data.
	local excluded = {}

	-- Add schems which are part of this chunk.
	-- A chunk may have multiple schems with different parameters.
	for _, v in ipairs(thischunk) do
		local chance = v.chance or 100

		if random(1, 100) <= chance and not excluded[v.file] then
			local file = v.file
			local path = params.schemdir .. "/" .. file .. ".mts"
			local offset = table.copy(v.offset or {x=0, y=0, z=0})
			local force = true
			local priority = v.priority or 0

			-- Only process this schem's exclusion of other schems if we are actually
			-- going to place this schem (chance has succeeded).
			if v.exclude then
				for name, _ in pairs(v.exclude) do
					excluded[name] = true
				end
			end

			-- The position adjustment setting may specify min/max values for each
			-- dimension coordinate.
			if offset.x_min then
				offset.x = random(offset.x_min, offset.x_max)
				offset.x_min = nil
				offset.x_max = nil
			end
			if offset.y_min then
				offset.y = random(offset.y_min, offset.y_max)
				offset.y_min = nil
				offset.y_max = nil
			end
			if offset.z_min then
				offset.z = random(offset.z_min, offset.z_max)
				offset.z_min = nil
				offset.z_max = nil
			end

			if type(v.force) == "boolean" then
				force = v.force
			end

			local rotation = v.rotation or "0"
			local realschempos = vector.add(schempos, offset)

			-- Add fortress section to construction queue.
			all_schems[#all_schems + 1] = {
				file = path,
				pos = realschempos,
				size = size,
				rotation = rotation,
				force = force,
				replacements = params.replacements,
				priority = priority,
			}
		end
	end
end



-- Read chunk data and calculate where to place chests.
-- Store chest locations in the builder data.
function fortress.v2.collect_chests(schempos, chunkdata, params)
	if not chunkdata.chests then
		return
	end

	local random = params.yeskings
	local all_chests = params.build.chests
	local used_locations = {}

	for _, v in ipairs(chunkdata.chests) do
		-- Spawn loot chest only if chance succeeds.
		if random(1, 100) <= v.chance then
			local p2 = table.copy(v.pos)

			-- The position adjustment setting may specify min/max values for each
			-- dimension coordinate.
			if p2.x_min then
				p2.x = random(p2.x_min, p2.x_max)
				p2.x_min = nil
				p2.x_max = nil
			end
			if p2.y_min then
				p2.y = random(p2.y_min, p2.y_max)
				p2.y_min = nil
				p2.y_max = nil
			end
			if p2.z_min then
				p2.z = random(p2.z_min, p2.z_max)
				p2.z_min = nil
				p2.z_max = nil
			end

			local loc = vector.add(schempos, p2)
			local hash = HASH_POSITION(loc)

			-- Don't overwrite already-added chests.
			if not used_locations[hash] then
				used_locations[hash] = true

				all_chests[#all_chests + 1] = {
					pos = loc,
					loot = v.loot,
				}
			end
		end
	end
end
