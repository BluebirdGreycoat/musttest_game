
moretrees = moretrees or {}



moretrees.can_grow = function(pos)
	return basictrees.can_grow(pos)
end



moretrees.sapling_selection_box = {
    type = "fixed",
    fixed = {-0.3, -0.5, -0.3, 0.3, 0.35, 0.3},
}



moretrees.sapling_groups = utility.dig_groups("plant", {
    flammable = 2,
    attached_node = 1,
    sapling = 1,
})



moretrees.tree_groups = utility.dig_groups("tree", {
    tree = 1,
    flammable = 2,
})



moretrees.get_wood_groups = function(extra)
    local groups = utility.dig_groups("wood", extra or {})
    
    groups.flammable = 2
    groups.wood = 1
    return groups
end



moretrees.stair_groups = utility.dig_groups("wood", {
    flammable = 2,
})



moretrees.leaves_groups = utility.dig_groups("leaves", {
    leafdecay = 3,
    flammable = 2,
    leaves = 1,
    green_leaves = 1,
})



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

