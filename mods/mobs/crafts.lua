
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



local meat_types = {
	-- Regular meat, creature type not defined.
	{name="mobs:meat_raw", desc="Strange Raw Meat", image="mobs_meat_raw.png", food=3, cooked="mobs:meat", is_raw=true},
	{name="mobs:meat", desc="Strange Cooked Meat", image="mobs_meat.png", food=6},

	-- Mutton.
	{name="mobs:meat_raw_mutton", desc="Raw Mutton", image="mobs_meat_raw.png", food=4, cooked="mobs:meat_mutton", is_raw=true},
	{name="mobs:meat_mutton", desc="Cooked Mutton", image="mobs_meat.png", food=10},

	-- Pork.
	{name="mobs:meat_raw_pork", desc="Raw Pork", image="mobs_meat_raw.png", food=4, cooked="mobs:meat_pork", is_raw=true, is_gross=true},
	{name="mobs:meat_pork", desc="Cooked Pork", image="mobs_meat.png", food=7, is_gross=true},
}

for k, v in ipairs(meat_types) do
	local eat_meat = minetest.item_eat(v.food)
	local do_eat_meat = eat_meat

	if v.is_raw or v.is_gross then
		do_eat_meat = function(itemstack, user, pointed_thing)
			-- Damage player only if meat was raw.
			if v.is_raw then
				-- Do not kill player.
				if user:get_hp() > 1 then
					user:set_hp(user:get_hp() - 1)
				end
			end
			-- Send message if meat was raw or gross.
			minetest.chat_send_player(user:get_player_name(), "# Server: You eat " .. v.desc .. "? Eww, gross!")
			return eat_meat(itemstack, user, pointed_thing)
		end
	end

	local groups = {food_meat = 1, flammable = 3}
	if v.is_raw then
		groups.food_meat_raw = 1
	end
	if v.is_gross then
		groups.food_meat_gross = 1
	end

	minetest.register_craftitem(v.name, {
		description = v.desc,
		inventory_image = v.image,
		groups = groups,
		on_use = do_eat_meat,
	})

	if v.cooked then
		minetest.register_craft({
			type = "cooking",
			output = v.cooked,
			recipe = v.name,
			cooktime = 5,
		})
	end
end



minetest.register_craftitem("mobs:leather", {
	description = "Leather",
	inventory_image = "mobs_leather.png",
	groups = {flammable = 2},
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
