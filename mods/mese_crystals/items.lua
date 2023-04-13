
-- Localize for performance.
local math_random = math.random


if not mese_crystals.nodes_registered then
	local boxes = {
		{-0.2, -0.5, -0.2, 0.2, -0.1, 0.2},
		{-0.2, -0.5, -0.2, 0.2, 0.10, 0.2},
		{-0.2, -0.5, -0.2, 0.2, 0.25, 0.2},
		{-0.2, -0.5, -0.2, 0.2, 0.35, 0.2},
	}
	local light = {1, 3, 5, 7}

	-- Register 4 levels of crystal.
	for i = 1, 4, 1 do
		minetest.register_node("mese_crystals:mese_crystal_ore" .. i, {
			description = "Zentamine Crystal Ore",
			mesh = "mese_crystal_ore" .. i .. ".obj",
			tiles = {"crystal.png"},
			paramtype = "light",
			paramtype2 = "facedir",
			drawtype = "mesh",
			groups = utility.dig_groups("crystal", {attached_node = 1, fall_damage_add_percent = 60}),
			drop = "default:mese_crystal_fragment " .. i,
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
				player:set_hp(player:get_hp() - (1*500), {reason="ground"})
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
		description = "Zentamine Crystal Seed\n\nGrows fastest in or below the cavern of the Brimstone Ocean!\nThe care and tending of zentamine crystals is difficult.",
		inventory_image = "mese_crystal_seed.png",

		on_place = function(...)
			return mese_crystals.on_seed_place(...)
		end,
	})

	mese_crystals.seed_registered = true
end



