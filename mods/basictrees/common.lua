
basictrees = basictrees or {}



basictrees.sapling_selection_box = {
    type = "fixed",
    fixed = {-0.3, -0.5, -0.3, 0.3, 0.35, 0.3},
}



basictrees.trunk_nodebox = {
	{0, 0, 2, 16, 16, 14},
	{2, 0, 0, 14, 16, 16},
}
utility.transform_nodebox(basictrees.trunk_nodebox)



basictrees.sapling_groups = {
    flammable = 2,
    attached_node = 1,
    sapling = 1,
    
    level = 1,
    snappy = 3,
    choppy = 3,
    oddly_breakable_by_hand = 3,
    --dig_immediate = 3,
}



basictrees.tree_groups = {
    tree = 1,
    level = 1,
    choppy = 1,
    flammable = 2,
}

basictrees.cw_tree_groups = {
    tree = 1,
    level = 1,
    choppy = 1,
}



basictrees.get_wood_groups = function(extra)
    local groups = extra or {}
    
    groups.level = 1
    groups.choppy = 2
    --groups.oddly_breakable_by_hand = 1
    
    groups.flammable = 2
    groups.wood = 1
    return groups
end



basictrees.leaves_groups = {
    level = 1,
    snappy = 3,
    choppy = 2,
    oddly_breakable_by_hand = 3,
    
    leafdecay = 3,
    flammable = 2,
    leaves = 1,
    green_leaves = 1,
}

basictrees.cw_leaves_groups = {
    level = 1,
    snappy = 3,
    choppy = 2,
    oddly_breakable_by_hand = 3,

    leafdecay = 3,
    leaves = 1,
    green_leaves = 1,
}



basictrees.can_grow = function(pos)
	-- Reduced chance to grow if cold/ice nearby.
	local cold = minetest.find_nodes_in_area(vector.subtract(pos, 1), vector.add(pos, 1), "group:cold")
	if #cold > math.random(0, 18) then
		return false
	end

	if pos.y < math.random(-64, 0) then
		return false
	end

	local node_under = minetest.get_node_or_nil({x = pos.x, y = pos.y - 1, z = pos.z})
	if not node_under then
		return false
	end
	local name_under = node_under.name
	local is_soil = minetest.get_item_group(name_under, "soil")
	if is_soil == 0 then
		return false
	end
	local light_level = minetest.get_node_light(pos)
	if not light_level or light_level < 12 then
		return false
	end
	return true
end



basictrees.get_leafdrop_table = function(chance, sapling, leaves)
    local drop = {
		max_items = 1,
		items = {
			{items={sapling}, rarity=chance},
			{items={"default:stick"}, rarity=10},
	
			-- Player will get leaves only if he gets nothing else; this is because 'max_items' is 1.
			{items={leaves}},
		}
	}
    return drop
end



