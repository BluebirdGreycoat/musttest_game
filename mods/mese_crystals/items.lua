
-- Localize for performance.
local math_random = math.random



function mese_crystals.on_finish_collapse(pos, node)
	minetest.remove_node(pos)
	minetest.add_item(pos, ItemStack("default:mese_crystal_fragment"))
end



function mese_crystals.on_collapse_to_entity(pos, node)
	return {ItemStack("default:mese_crystal_fragment")}
end



if not mese_crystals.nodes_registered then
	local boxes = {
		{-0.2, -0.5, -0.2, 0.2, -0.1, 0.2},
		{-0.2, -0.5, -0.2, 0.2, 0.10, 0.2},
		{-0.2, -0.5, -0.2, 0.2, 0.25, 0.2},
		{-0.2, -0.5, -0.2, 0.2, 0.35, 0.2},
		{-0.2, -0.5, -0.2, 0.2, 0.35, 0.2},
	}
	local light = {1, 3, 5, 7, 8}

	-- Register 5 levels of crystal.
	for i = 1, 5, 1 do
		local dropstring = "default:mese_crystal_fragment " .. i

		minetest.register_node("mese_crystals:mese_crystal_ore" .. i, {
			description = "Zentamine Crystal Ore",
			mesh = "mese_crystal_ore" .. i .. ".obj",
			tiles = {"crystal.png"},
			paramtype = "light",
			paramtype2 = "facedir",
			drawtype = "mesh",
			groups = utility.dig_groups("crystal", {attached_node = 1, fall_damage_add_percent = 60}),
			drop = dropstring,
			use_texture_alpha = "blend",
			sounds = default.node_sound_stone_defaults(),
			light_source = light[i],
			selection_box = {
				type = "fixed",
				fixed = boxes[i],
			},
			collision_box = {
				type = "fixed",
				fixed = boxes[i],
			},
			on_player_walk_over = function(pos, player)
				utility.damage_player(player, "fleshy", 1*500, "ground")

				if player:get_hp() == 0 then
        	minetest.chat_send_all("# Server: <" .. rename.gpn(player:get_player_name()) .. "> stepped on a zentamine spike.")
      	end
			end,
			on_timer = function(...)
				return mese_crystals.on_timer(...)
			end,
			on_rotate = function(...)
				return screwdriver.rotate_simple(...)
			end,
			on_construct = function(pos)
				local node = minetest.get_node(pos)
				node.param2 = math_random(0, 3)
				minetest.swap_node(pos, node)
			end,
			on_finish_collapse = function(...)
				return mese_crystals.on_finish_collapse(...)
			end,
			on_collapse_to_entity = function(...)
				return mese_crystals.on_collapse_to_entity(...)
			end,
		})
	end

	minetest.register_craftitem("mese_crystals:zentamine", {
  	description = "Zentamine Shard",
  	inventory_image = "zentamine_fragment.png",
	})


	mese_crystals.nodes_registered = true
end



function mese_crystals.on_seed_place(itemstack, user, pt)
	if pt.type ~= "node" then
		return
	end
	local pos = pt.under
	local node = minetest.get_node(pos)

	-- Pass through interactions to nodes that define them (like chests).
	do
		local pdef = minetest.reg_ns_nodes[node.name]
		if pdef and pdef.on_rightclick and not user:get_player_control().sneak then
			return pdef.on_rightclick(pos, node, user, itemstack, pt)
		end
	end

	if node.name == "default:obsidian" then
		local pos1 = pt.above
		local node1 = minetest.get_node(pos1)
		if node1.name == "air" and not minetest.is_protected(pos1, user:get_player_name()) then
			itemstack:take_item()
			node.name = "mese_crystals:mese_crystal_ore1"
			minetest.add_node(pos1, {name=node.name, param2=math_random(0, 3)})
			minetest.get_node_timer(pos1):start(mese_crystals.get_grow_time())

			dirtspread.on_environment(pos1)
			droplift.notify(pos1)
		end
	end
	return itemstack
end



if not mese_crystals.seed_registered then
	minetest.register_craftitem("mese_crystals:mese_crystal_seed", {
		description = "Zentamine Crystal Seed",
		inventory_image = "mese_crystal_seed.png",

		on_place = function(...)
			return mese_crystals.on_seed_place(...)
		end,
	})

	mese_crystals.seed_registered = true
end



