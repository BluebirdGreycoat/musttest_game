
-- name tag
minetest.register_craftitem("mobs:nametag", {
	description = "Mob Name Tag",
	inventory_image = "mobs_nametag.png",
	groups = {flammable = 2},
})

minetest.register_craft({
	type = "shapeless",
	output = "mobs:nametag",
	recipe = {"default:paper", "dye:black", "farming:string"},
})

local eat_raw_meat = minetest.item_eat(4)
minetest.register_craftitem("mobs:meat_raw", {
	description = "Raw Meat",
	inventory_image = "mobs_meat_raw.png",
	groups = {food_meat_raw = 1, flammable = 2},

	on_use = function(itemstack, user, pointed_thing)
		-- Do not kill player.
    if user:get_hp() > 1 then
      user:set_hp(user:get_hp() - 1)
    end
    minetest.chat_send_player(user:get_player_name(), "# Server: Eww, you eat that? Gross!")
    return eat_raw_meat(itemstack, user, pointed_thing)
  end,
})

minetest.register_craftitem("mobs:leather", {
	description = "Leather",
	inventory_image = "mobs_leather.png",
	groups = {flammable = 2},
})


minetest.register_craftitem("mobs:meat", {
	description = "Cooked Meat",
	inventory_image = "mobs_meat.png",
	on_use = minetest.item_eat(10),
	groups = {food_meat = 1, flammable = 2},
})



minetest.register_craft({
	type = "cooking",
	output = "mobs:meat",
	recipe = "mobs:meat_raw",
	cooktime = 5,
})



minetest.register_tool("mobs:net", {
	description = "Capturing Net",
	inventory_image = "mobs_net.png",
  groups = {not_repaired_by_anvil = 1, flammable = 2},
})



minetest.register_craft({
	output = "mobs:net",
	recipe = {
		{"default:stick",     "",                 "default:stick"     },
		{"default:stick",     "",                 "default:stick"     },
		{"farming:string",    "default:stick",    "farming:string"    },
	}
})

-- items that can be used as fuel
minetest.register_craft({
	type = "fuel",
	recipe = "mobs:net",
	burntime = 8,
})

minetest.register_craft({
	type = "fuel",
	recipe = "mobs:leather",
	burntime = 4,
})

minetest.register_craft({
	type = "fuel",
	recipe = "mobs:nametag",
	burntime = 3,
})
