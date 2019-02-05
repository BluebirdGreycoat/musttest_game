
moretrees = moretrees or {}



moretrees.can_grow = function(pos)
	return basictrees.can_grow(pos)
end



moretrees.sapling_selection_box = {
    type = "fixed",
    fixed = {-0.3, -0.5, -0.3, 0.3, 0.35, 0.3},
}



moretrees.sapling_groups = {
    level = 1,
    snappy = 3,
    choppy = 3,
    oddly_breakable_by_hand = 3,
    --dig_immediate = 3,
        
    flammable = 2,
    attached_node = 1,
    sapling = 1,
}



moretrees.tree_groups = {
    tree = 1,
    level = 1,
    choppy = 1,
    flammable = 2,
}



moretrees.get_wood_groups = function(extra)
    local groups = extra or {}
    
    groups.level = 1
    groups.choppy = 2
    
    groups.flammable = 2
    groups.wood = 1
    return groups
end



moretrees.stair_groups = {
    level = 1,
    choppy = 2,
    
    flammable = 2,
}



moretrees.leaves_groups = {
    level = 1,
    snappy = 3,
    choppy = 2,
    oddly_breakable_by_hand = 3,
    
    leafdecay = 3,
    flammable = 2,
    leaves = 1,
    green_leaves = 1,
}



moretrees.get_leafdrop_table = function(chance, sapling, leaves)
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

