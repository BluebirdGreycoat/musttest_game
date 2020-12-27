
-- If any trees get added to the game, consider extending this list.
local all_trees = {
	{trunk="basictrees:acacia_trunk"},
	{trunk="basictrees:aspen_trunk"},
	{trunk="basictrees:jungletree_trunk"},
	{trunk="basictrees:pine_trunk"},
	{trunk="basictrees:tree_trunk"},

	{trunk="jungletree:jungletree_tree"},
	{trunk="firetree:trunk"},

	{trunk="moretrees:apple_tree_tree"},
	{trunk="moretrees:beech_tree"},
	{trunk="moretrees:birch_tree"},
	{trunk="moretrees:cedar_tree"},
	{trunk="moretrees:date_palm_tree"},
	{trunk="moretrees:fir_tree"},
	{trunk="moretrees:jungletree_tree"},
	{trunk="moretrees:oak_tree"},
	{trunk="moretrees:palm_tree"},
	{trunk="moretrees:poplar_tree"},
	{trunk="moretrees:rubber_tree_tree"},
	{trunk="moretrees:sequoia_tree"},
	{trunk="moretrees:spruce_tree"},
	{trunk="moretrees:willow_tree"},
}

-- For all listed tree trunk nodes, register cuttings for them.
for _, tree in ipairs(all_trees) do
	assert(type(tree.trunk) == "string")
	local ndef = minetest.registered_items[tree.trunk]
	assert(ndef)
	assert(ndef.sounds)
	assert(ndef.tiles)
	assert(ndef.description)

	local stairname = string.split(tree.trunk, ":")[2]
	assert(type(stairname) == "string")

	stairs.register_stair_and_slab(
		stairname,
		tree.trunk,
		{choppy = 3, oddly_breakable_by_hand = 1, flammable = 2},
		ndef.tiles,
		ndef.description,
		ndef.sounds
	)
end

-- Register a copy of this node for use with acacia trees sapling schematic.
local acacia_branch = minetest.registered_nodes["stairs:slope_acacia_trunk_outer"]
if acacia_branch then
	acacia_branch = table.copy(acacia_branch)
	acacia_branch.name = nil
	acacia_branch.drop = "default:stick 10"

	-- Acacia slopes left over from cut trees look pretty ugly.
	-- This fixes them up and makes them slightly useful.
	acacia_branch.on_finish_collapse = function(pos, node)
		minetest.remove_node(pos)
		minetest.add_item(pos, "default:stick " .. math.random(1, 10))
	end
	acacia_branch.on_collapse_to_entity = function(pos, node)
		minetest.add_item(pos, "default:stick " .. math.random(1, 10))
	end

	minetest.register_node(":basictrees:acacia_branch", acacia_branch)
end
