
-- Can use this in node definitions to allow a node to be placed inside
-- protected areas (similar to snow). The node is marked "protection_cancel"
-- so anyone else could come and remove it.
function protector.on_place_ignore_protection(itemstack, placer, pointed_thing)
	local pname = placer and placer:get_player_name() or ""

	-- Protection prevents proper operation of 'item_place_node'
	protector.enable_protection(false)
	local newstack, place_to = core.item_place_node(itemstack, placer, pointed_thing)
	protector.enable_protection(true)

	-- Check if player put object in location protected by someone else.
	if place_to and minetest.test_protection(place_to, pname) then
		local meta = minetest.get_meta(place_to)
		meta:set_int("protection_cancel", 1)
		meta:mark_as_private("protection_cancel")
	end

	return newstack
end
