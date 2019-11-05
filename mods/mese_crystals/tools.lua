
function mese_crystals.on_tool_use(itemstack, user, pt)
	if pt.type ~= "node" then return end
	local pos = pt.under
	if minetest.test_protection(pos, user:get_player_name()) then return end
	local node = minetest.get_node(pos)
	local growth_stage = 0

	-- Determine growth stage.
	if node.name == "mese_crystals:mese_crystal_ore4" then
		growth_stage = 4
	elseif node.name == "mese_crystals:mese_crystal_ore3" then
		growth_stage = 3
	elseif node.name == "mese_crystals:mese_crystal_ore2" then
		growth_stage = 2
	elseif node.name == "mese_crystals:mese_crystal_ore1" then
		growth_stage = 1
	end

	-- Update crystaline plant.
	if growth_stage == 4 then
		node.name = "mese_crystals:mese_crystal_ore3"
		minetest.swap_node(pos, node)
		minetest.get_node_timer(pos):start(mese_crystals.get_grow_time())
	elseif growth_stage == 3 then
		node.name = "mese_crystals:mese_crystal_ore2"
		minetest.swap_node(pos, node)
		minetest.get_node_timer(pos):start(mese_crystals.get_grow_time())
	elseif growth_stage == 2 then
		node.name = "mese_crystals:mese_crystal_ore1"
		minetest.swap_node(pos, node)
		minetest.get_node_timer(pos):start(mese_crystals.get_grow_time())
	else
		-- Just restart growing timer.
		minetest.get_node_timer(pos):start(mese_crystals.get_grow_time())
	end

	-- Give wielder a harvest.
	if growth_stage > 1 then
		ambiance.sound_play("default_break_glass", pos, 0.3, 10)
		itemstack:add_wear(65535 / 400)
		local inv = user:get_inventory()
		local stack
		if math.random(1, 40) == 1 then
			stack = ItemStack("default:mese_crystal")
		else
			stack = ItemStack("mese_crystals:zentamine")
		end
		if inv:room_for_item("main", stack) then
			inv:add_item("main", stack)
		else
			minetest.item_drop(stack, nil, pos)
			minetest.chat_send_player(user:get_player_name(), "# Server: Cannot obtain harvest, no room in inventory!")
		end
	end

	return itemstack
end



if not mese_crystals.tool_registered then
	minetest.register_tool("mese_crystals:crystaline_bell", {
		description = "Crystaline Bell\n\nHarvests zentamine crystals.\nCannot be repaired on anvil.\nNon-metalic.",
		inventory_image = "crystalline_bell.png",
		groups = {not_repaired_by_anvil = 1},

		on_use = function(...)
			return mese_crystals.on_tool_use(...)
		end,
	})

	mese_crystals.tool_registered = true
end
