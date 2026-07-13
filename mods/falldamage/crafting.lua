
-- This is also handled in the workbench (autocrafter) code.
-- Warning: NOT called for bulk crafts (like cooking, etc) recipes from machines!
-- Consequently this is currently only useful for tools crafted in a regular craft grid.
minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	local idef = itemstack:get_definition()
	if idef and idef._on_craft then
		idef._on_craft(itemstack, player)
	end
end)
