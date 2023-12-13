
-- Localize for performance.

function mese_crystals.on_tool_use(itemstack, user, pt)
	if not user or not user:is_player() then return end
	if pt.type ~= "node" then return end

	local pos = pt.under
	local pname = user:get_player_name()

	if minetest.test_protection(pos, pname) then
		return
	end

	local node = minetest.get_node(pos)
	if node.name == "default:diamondblock" then
		ambiance.sound_play("default_break_glass", pos, 1.0, 32)
		local dir = vector.subtract(pt.under, pt.above)
		if dir.y == 0 then
			local np = vector.add(pos, dir)
			local gotten = mese_crystals.harvest_direction(np, dir, pname)
			if gotten then
				itemstack:add_wear_by_uses(400)
			end
		end
		return itemstack
	end

	local gotten = mese_crystals.harvest_pos(pos, user)
	if gotten then
		itemstack:add_wear_by_uses(400)
	end

	return itemstack
end



if not mese_crystals.tool_registered then
	minetest.register_tool("mese_crystals:crystaline_bell", {
		description = "Crystaline Bell",
		inventory_image = "crystalline_bell.png",
		groups = {not_repaired_by_anvil = 1},

		on_use = function(...)
			return mese_crystals.on_tool_use(...)
		end,
	})

	mese_crystals.tool_registered = true
end
