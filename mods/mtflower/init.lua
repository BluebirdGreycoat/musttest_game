
mtflower = mtflower or {}
mtflower.modpath = minetest.get_modpath("mtflower")

-- All branch positions have been tested and declared accurate.
local branches = {
	-- Straights.
	{{x= 1, y=0, z= 0}, {x= 2, y=0, z= 0}},
	{{x=-1, y=0, z= 0}, {x=-2, y=0, z= 0}},
	{{x= 0, y=0, z= 1}, {x= 0, y=0, z= 2}},
	{{x= 0, y=0, z=-1}, {x= 0, y=0, z=-2}},

	-- Straight turns.
	{{x= 1, y=0, z= 0}, {x= 2, y=0, z= 1}},
	{{x= 1, y=0, z= 0}, {x= 2, y=0, z=-1}},

	{{x=-1, y=0, z= 0}, {x=-2, y=0, z= 1}},
	{{x=-1, y=0, z= 0}, {x=-2, y=0, z=-1}},

	{{x= 0, y=0, z= 1}, {x= 1, y=0, z= 2}},
	{{x= 0, y=0, z= 1}, {x=-1, y=0, z= 2}},

	{{x= 0, y=0, z=-1}, {x= 1, y=0, z=-2}},
	{{x= 0, y=0, z=-1}, {x=-1, y=0, z=-2}},

	-- Straight diagonals.
	{{x= 1, y=0, z= 1}, {x= 2, y=0, z= 2}},
	{{x=-1, y=0, z=-1}, {x=-2, y=0, z=-2}},
	{{x= 1, y=0, z=-1}, {x= 2, y=0, z=-2}},
	{{x=-1, y=0, z= 1}, {x=-2, y=0, z= 2}},

	-- Diagonal turns.
	{{x= 1, y=0, z= 1}, {x= 1, y=0, z= 2}},
	{{x= 1, y=0, z= 1}, {x= 2, y=0, z= 1}},

	{{x=-1, y=0, z=-1}, {x=-1, y=0, z=-2}},
	{{x=-1, y=0, z=-1}, {x=-2, y=0, z=-1}},

	{{x= 1, y=0, z=-1}, {x= 1, y=0, z=-2}},
	{{x= 1, y=0, z=-1}, {x= 2, y=0, z=-1}},

	{{x=-1, y=0, z= 1}, {x=-1, y=0, z= 2}},
	{{x=-1, y=0, z= 1}, {x=-2, y=0, z= 1}},
}

function mtflower.may_replace_node(pos, tree, leaf, is_leaf)
	pos = vector.round(pos)
	local node = minetest.get_node(pos)

	-- Replace air and leaves of the same kind of tree.
	if node.name == "air" or node.name == leaf then
		return true
	end

	-- Never replace ignore or trunk/branch nodes.
	if node.name == "ignore" or node.name == tree then
		return
	end

	local ndef = minetest.registered_nodes[node.name] or {}

	-- Leaves do not replace liquid.
	if is_leaf and ndef.liquidtype ~= "none" then
		return
	end

	-- Allow replacing `buildable_to`, `floodable`.
	if ndef.buildable_to or ndef.floodable then
		return true
	end

	-- Or liquids.
	if ndef.liquidtype ~= "none" then
		return true
	end
end

function mtflower.shape_to_positions(shape, offset)
	if type(shape) == "string" then
		if shape == "single" then
			return {{x=0, y=0, z=0}}, {x=0, y=0, z=0}
		elseif shape == "cross" then
			return {
														 {x= 1, y=0, z= 0},
					{x= 0, y=0, z= 1}, {x= 0, y=0, z= 0}, {x= 0, y=0, z=-1},
														 {x=-1, y=0, z= 0},
				}, {x=0, y=0, z=0}
		elseif shape == "square" then
			local spots = {
				{x=0, y=0, z=0}, {x=1, y=0, z=0},
				{x=0, y=0, z=1}, {x=1, y=0, z=1},
			}
			if not offset then
				local adjust = {x=math.random(-1, 0), y=0, z=math.random(-1, 0)}
				for k, v in ipairs(spots) do
					local p = vector.add(v, adjust)
					v.x = p.x
					v.y = p.y
					v.z = p.z
				end
				return spots, adjust
			else
				for k, v in ipairs(spots) do
					v.x = v.x + offset.x
					v.y = v.y + offset.y
					v.z = v.z + offset.z
				end
				return spots, offset
			end
		end
	end

	-- Fallback.
	return {{x=0, y=0, z=0}}, {x=0, y=0, z=0}
end

function mtflower.generate_roots(pos, shape, offset, tree, leaf)
	pos = vector.round(pos)

	-- Get a list of positions to start the bottom of the root from.
	local starts = mtflower.shape_to_positions(shape, offset)

	-- Adjust start positions downward 1 meter so they don't interfere with trunk.
	for k, v in ipairs(starts) do
		v.y = v.y - 1
	end

	-- Sanitize arguments.
	if type(height) ~= "number" then height = tonumber(height) or 10 end
	if height < 1 then height = 1 end
	if type(leaves) ~= "string" then leaves = "default:leaves" end
	if leaves == "ignore" then leaves = "" end
	if not minetest.registered_nodes[leaves] then return {} end
	if type(tree) ~= "string" then tree = "default:tree" end
	if tree == "ignore" then return {} end
	if not minetest.registered_nodes[tree] then return {} end

	local roots = {}

	-- Grow roots downward.
	for y = 0, -16, -1 do
		local stops = 0

		-- Increment height of all start positions, stacking upwards.
		for k, v in ipairs(starts) do
			local p = vector.add(pos, v)

			if mtflower.may_replace_node(p, tree, leaves) then
				table.insert(roots, p)
			else
				stops = stops + 1
			end

			v.y = v.y - 1
		end

		-- If hit something that completely blocks root, stop growing downward.
		if stops == #starts then
			break
		end
	end

	-- Place root nodes.
	minetest.bulk_set_node(roots, {name = tree})

	-- Return all positions of roots.
	return roots
end

function mtflower.generate_trunk(pos, shape, height, tree, leaves)
	pos = vector.round(pos)

	-- Get a list of positions to start the bottom of the trunk from.
	local starts, offset = mtflower.shape_to_positions(shape)

	-- Sanitize arguments.
	if type(height) ~= "number" then height = tonumber(height) or 10 end
	if height < 1 then height = 1 end
	if type(leaves) ~= "string" then leaves = "default:leaves" end
	if leaves == "ignore" then leaves = "" end
	if not minetest.registered_nodes[leaves] then return {} end
	if type(tree) ~= "string" then tree = "default:tree" end
	if tree == "ignore" then return {} end
	if not minetest.registered_nodes[tree] then return {} end

	local trunks = {}

	for y = 0, height - 1, 1 do
		local stops = 0

		-- Increment height of all start positions, stacking upwards.
		for k, v in ipairs(starts) do
			local p = vector.add(pos, v)

			if mtflower.may_replace_node(p, tree, leaves) then
				table.insert(trunks, p)
			else
				stops = stops + 1
			end

			v.y = v.y + 1
		end

		-- If hit something that completely blocks trunk, stop growing upward.
		if stops == #starts then
			break
		end
	end

	-- Place trunk nodes.
	minetest.bulk_set_node(trunks, {name = tree})

	-- Return all positions of trunks.
	return trunks, offset
end

function mtflower.try_spawn_branch(pos, tree, leaf, recursive, cluster_count, first_cluster)
	pos = vector.round(pos)

	-- Sanitize arguments.
	if type(tree) ~= "string" then tree = "default:tree" end
	if tree == "ignore" then return {}, {} end
	if not minetest.registered_nodes[tree] then return {}, {} end
	if type(recursive) ~= "number" then recursive = 1 end
	if recursive < 1 then recursive = 1 end
	if type(leaf) ~= "string" then leaf = "default:tree" end
	if not minetest.registered_nodes[leaf] then return {}, {} end
	if leaf == "ignore" then return {}, {} end

	local branch
	local tree_near = {x=0, y=0, z=0}
	local p1
	local p2
	local try_count = 1

	while tree_near do
		if try_count >= 3 then
			break
		end

		branch = branches[math.random(1, #branches)]

		p1 = vector.add(pos, branch[1])
		p2 = vector.add(pos, branch[2])

		-- Do not spawn branches if the 'end' would be too close to the trunk or a branch.
		tree_near = minetest.find_node_near(p2, 1, {"mtflower:ignore", tree})
		try_count = try_count + 1
	end

	if tree_near then return {}, {} end

	local all = {}
	local arms = {}

	-- Declare these positions as branch nodes, if a branch can be placed.
	if mtflower.may_replace_node(p1, tree, leaf) then
		minetest.set_node(p1, {name="mtflower:ignore"})
		table.insert(all, p1)

		-- Add this position to the list of arm positions (branch next to trunk).
		-- Only for top level frame of recursive function.
		if recursive == 1 then
			table.insert(arms, p1)
		end
	end

	if mtflower.may_replace_node(p2, tree, leaf) then
		minetest.set_node(p2, {name="mtflower:ignore"})
		table.insert(all, p2)
	end

	-- In top-level frame of recursive function -- can call self to create more complex branches.
	-- Recursive marker must be GREATER THAN 1 for the recursive calls!
	if recursive == 1 then
		local endpoints = {table.copy(p2)}

		if cluster_count >= 2 and not first_cluster then
			endpoints = {}

			-- Fork in two directions.
			local more1 = mtflower.try_spawn_branch(p2, tree, leaf, 2, cluster_count, first_cluster)
			for k, v in ipairs(more1) do
				table.insert(all, v)
			end
			table.insert(endpoints, more1[2])

			local more2 = mtflower.try_spawn_branch(p2, tree, leaf, 2, cluster_count, first_cluster)
			for k, v in ipairs(more2) do
				table.insert(all, v)
			end
			table.insert(endpoints, more2[2])
		end

		-- For big trees, make one of the branches even longer (if possible).
		-- Do this for all clusters including the first one.
		if cluster_count >= 3 and #endpoints > 0 then
			local randp = endpoints[math.random(1, #endpoints)]
			local more3 = mtflower.try_spawn_branch(randp, tree, leaf, 2, cluster_count, first_cluster)
			for k, v in ipairs(more3) do
				table.insert(all, v)
			end
		end
	end

	-- Return all the locations where branch nodes were placed.
	return all, arms
end

function mtflower.generate_branches(trunks, tries, tree, leaf)
	trunks = table.copy(trunks)

	-- Sort trunk locations by Y-height, largest first.
	table.sort(trunks, function(a, b) if a.y > b.y then return true end end)

	local all = {}
	local arms = {}

	local create_branch = function(pos, cluster_count, first_cluster)
		local branch, arm = mtflower.try_spawn_branch(pos, tree, leaf, 1, cluster_count, first_cluster)

		for k, v in ipairs(branch) do
			table.insert(all, v)
		end
		for k, v in ipairs(arm) do
			table.insert(arms, v)
		end
	end

	local find_trunk_at_height = function(y)
		local found = {}

		for k, v in ipairs(trunks) do
			if v.y == y then
				table.insert(found, v)
			end
		end

		if #found > 0 then
			return found[math.random(1, #found)]
		end
	end

	local ymax = trunks[1].y
	local ymin = trunks[#trunks].y

	local spawn_horizontal_cluster = function(y, cluster_count, first_cluster)
		for i = 1, tries, 1 do
			local found = find_trunk_at_height(y)
			if found then
				create_branch(found, cluster_count, first_cluster)
			end
		end
	end

	-- This function spawns 2 or 3 horizontal layers going down from Y-start.
	local spawn_cluster = function(ytop, cluster_count, first_cluster)
		local width = math.random(3, 5)
		for y = ytop, ytop - width, -2 do
			spawn_horizontal_cluster(y, cluster_count, first_cluster)
		end
	end

	-- Calcuate how many branch clusters we can spawn on this tree, based on height.
	local cluster_count = 0
	for y = ymax, ymin, -10 do
		cluster_count = cluster_count + 1
	end

	-- Actually spawn the clusters.
	local first_cluster = true
	local dist = math.random(-11, -8)
	for y = ymax, ymin, dist do
		if y > ymin + 8 or first_cluster then
			spawn_cluster(y + math.random(-1, 1), cluster_count, first_cluster)
			first_cluster = false
		end
	end

	-- Branch locations calculated, place branch nodes.
	minetest.bulk_set_node(all, {name=tree})

	return all, arms
end

function mtflower.spawn_leaf_cube(pos, tree, leaves)
	pos = vector.round(pos)
	local above = vector.add(pos, {x=0, y=1, z=0})

	-- Sanitize arguments.
	if type(tree) ~= "string" then tree = "default:tree" end
	if type(leaves) ~= "string" then leaves = "default:leaves" end
	if tree == "ignore" or leaves == "ignore" then return {} end
	if not minetest.registered_nodes[tree] then return {} end
	if not minetest.registered_nodes[leaves] then return {} end

	-- Ensure the start position really is a trunk.
	if minetest.get_node(pos).name ~= tree then
		return {}
	end

	-- Require node above to be air or leaves, to spawn more leaves.
	if not mtflower.may_replace_node(above, tree, leaves, true) then
		return {}
	end

	local minp = vector.add(pos, {x=-1, y=-1, z=-1})
	local maxp = vector.add(pos, {x= 1, y= 1, z= 1})

	local sides = {
		{x= 1, y= 0, z= 0},
		{x=-1, y= 0, z= 0},
		{x= 0, y= 1, z= 0},
		{x= 0, y=-1, z= 0},
		{x= 0, y= 0, z= 1},
		{x= 0, y= 0, z=-1},
	}
	for k, v in ipairs(sides) do
		v.x = v.x + pos.x
		v.y = v.y + pos.y
		v.z = v.z + pos.z
	end

	local is_side = function(pos)
		for k, v in ipairs(sides) do
			if vector.equals(v, pos) then
				return true
			end
		end
	end

	-- Keep track of where leaves are spawned.
	local spots = {}

	for x = minp.x, maxp.x, 1 do
		for y = minp.y, maxp.y, 1 do
			for z = minp.z, maxp.z, 1 do
				local p = {x=x, y=y, z=z}

				-- Skip placing 1 in 7 leaves, but never skip sides.
				if math.random(1, 7) <= 6 or is_side(p) then
					if mtflower.may_replace_node(p, tree, leaves, true) then
						minetest.set_node(p, {name=leaves})
						table.insert(spots, p)
					end
				end
			end
		end
	end

	-- Has a chance to spawn extra leaves outside the cube, on the sides.
	local extras = {
		{x= 2, y= 0, z= 0},
		{x=-2, y= 0, z= 0},
		{x= 0, y= 2, z= 0},
		{x= 0, y=-2, z= 0},
		{x= 0, y= 0, z= 2},
		{x= 0, y= 0, z=-2},
	}
	for k, v in ipairs(extras) do
		v.x = v.x + pos.x
		v.y = v.y + pos.y
		v.z = v.z + pos.z

		if math.random(1, 4) == 1 then
			if mtflower.may_replace_node(v, tree, leaves, true) then
				minetest.set_node(v, {name=leaves})
				table.insert(spots, v)
			end
		end
	end

	return spots
end

function mtflower.generate_leaves(trunks, branch, tree, leaf)
	local leaves = {}

	-- Put leaves on all eligible trunk nodes.
	for k, v in ipairs(trunks) do
		local spots = mtflower.spawn_leaf_cube(v, tree, leaf)

		for i, j in ipairs(spots) do
			table.insert(leaves, j)
		end
	end

	-- Put leaves around all eligible branch nodes.
	for k, v in ipairs(branch) do
		local spots = mtflower.spawn_leaf_cube(v, tree, leaf)

		for i, j in ipairs(spots) do
			table.insert(leaves, j)
		end
	end

	return leaves
end

function mtflower.branch_tries_from_shape(shape)
	if type(shape) == "string" then
		if shape == "cross" then
			return 16
		elseif shape == "square" then
			return 8
		elseif shape == "single" then
			return 4
		end
	end

	-- Fallback.
	return 4
end

function mtflower.generate_tree(pos, shape, height, tree, leaf)
	local tries = mtflower.branch_tries_from_shape(shape)
	local trunks, offset = mtflower.generate_trunk(pos, shape, height, tree, leaf)
	local roots = mtflower.generate_roots(pos, shape, offset, tree, leaf)

	if not trunks or #trunks == 0 then
		return
	end

	local branch, arms = mtflower.generate_branches(trunks, tries, tree, leaf)
	local leaves = mtflower.generate_leaves(trunks, branch, tree, leaf)

	-- Positions of roots, trunks, branches, arms, & leaves.
	return true, roots, trunks, branch, arms, leaves
end

function mtflower.can_grow(pos)
	pos = vector.round(pos)

	if pos.y > math.random(-200, -100) then
		return false
	end

	-- Reduced chance to grow if cold/ice nearby.
	local below = {x=pos.x, y=pos.y-1, z=pos.z}
	local cold = minetest.find_nodes_in_area(vector.subtract(below, 1), vector.add(below, 1), "group:cold")
	if #cold > math.random(0, 18) then
		return false
	end

	local node_under = minetest.get_node_or_nil(below)
	if not node_under then
		return false
	end
	local name_under = node_under.name
	local is_soil = minetest.get_item_group(name_under, "glowmineral")
	if is_soil == 0 then
		return false
	end
	local light_level = minetest.get_node_light(pos)
	if not light_level or light_level < 12 then
		return false
	end

	-- Mineral-grown trees require a heat source.
	if not minetest.find_node_near(pos, 10, "group:lava") then
		return false
	end

	return true
end

-- This function returns `true` if a tree was actually spawned.
function mtflower.try_grow(pos, tree, leaf, lamp, mineral)
	--minetest.chat_send_all('growing tree')
	if pos.y > -100 then
		return
	end

	local minp = vector.add(pos, {x=-5, y=-5, z=-5})
	local maxp = vector.add(pos, {x= 5, y= 5, z= 5})

	local positions = minetest.find_nodes_in_area(minp, maxp, mineral)

	local height = math.floor(#positions * 1.5)
	if height > 40 then
		height = 40
	end
	height = math.floor(height * (math.random(95, 105) / 100))
	if height < 6 then
		return
	end

	local shape = "single"

	if height >= 30 then
		shape = "cross"
	elseif height >= math.random(20, 30) then
		shape = "square"
	end

	-- Create the tree.
	minetest.set_node(pos, {name='air'}) -- Remove sapling first.
	local success, roots, trunks, branch, arms, leaves =
		mtflower.generate_tree(pos, shape, height, tree, leaf)

	if not success then
		return
	end

	-- Remove items out of the soil (the tree 'eats' them).
	minetest.bulk_set_node(positions, {name="default:gravel"})
	for k, v in ipairs(positions) do
		minetest.check_for_falling(v)
	end

	-- Scatter items drawn up out of the soil in the tree itself.
	if arms and #arms > 0 then
		local amount = math.floor(#positions / 4)
		for i = 1, amount, 1 do
			local spot = arms[math.random(1, #arms)]
			minetest.set_node(spot, {name=lamp})
		end
	end

	return true
end

if not mtflower.registered then
	-- Used when generating branches.
	minetest.register_node("mtflower:ignore", {
		drawtype = "airlike",
		description = "MTFLOWER IGNORE (Please Report to Admin)",
		paramtype = "light",
		sunlight_propagates = true,
		walkable = false,
		pointable = false,
		groups = {immovable = 1},
		climbable = false,
		buildable_to = true,
		floodable = true,
		drop = "",

		on_finish_collapse = function(pos, node)
			minetest.remove_node(pos)
		end,

		on_collapse_to_entity = function(pos, node)
    	-- Do nothing.
  	end,
	})

	-- Register mod as reloadable if reload functionality is available.
	if minetest.get_modpath("reload") then
		local c = "mtflower:core"
		local f = mtflower.modpath .. "/init.lua"
		reload.register_file(c, f, false)
	end

	mtflower.registered = true
end
