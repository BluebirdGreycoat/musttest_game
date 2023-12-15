
-- Time-recursive function.
function mese_crystals.harvest_direction(pos, dir, pname, data)
	-- First 3 params will be nil if recursive call.
	data = data or {
		count = 0,
		pos = vector.copy(pos),
		dir = vector.copy(dir),
		pname = pname,
	}

	if minetest.test_protection(data.pos, data.pname) then
		return
	end

	local gotten = mese_crystals.harvest_pos(data.pos)

	if gotten then
		data.count = data.count + 1
		data.pos = vector.add(data.pos, data.dir)

		if data.count >= 16 then
			return
		end

		minetest.after(0.1, function()
			mese_crystals.harvest_direction(nil, nil, nil, data)
		end)
	end

	-- We got at least one.
	return gotten
end



function mese_crystals.harvest_pos(pos, user)
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
	else
		-- Not a crystal.
		return
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
		ambiance.sound_play("default_break_glass", pos, 0.3, 32)

		local stack
		if math.random(1, 30) == 1 then
			-- Chance to get an actual crystal.
			stack = ItemStack("default:mese_crystal")
		else
			stack = ItemStack("default:mese_crystal_fragment")
		end

		if user then
			local inv = user:get_inventory()
			if inv then
				stack = inv:add_item("main", stack)
			end
		end

		if not stack:is_empty() then
			local obj = minetest.add_item(pos, stack)
			if obj then
				obj:set_velocity({
					x = math.random(-100, 100) / 50,
					y = math.random(50, 100) / 10,
					z = math.random(-100, 100) / 50,
				})
			end
		end

		-- Gotten.
		return true
	end
end
