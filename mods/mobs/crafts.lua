
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
	{name="mobs:meat_raw", desc="Raw Meat (Unidentified)", image="mobs_meat_raw.png", food=3, cooked="mobs:meat", is_raw=true},
	{name="mobs:meat", desc="Cooked Meat (Unidentified)", image="mobs_meat.png", food=6},

	-- Mutton.
	{name="mobs:meat_raw_mutton", desc="Raw Mutton", image="mobs_mutton_raw.png", food=4, cooked="mobs:meat_mutton", is_raw=true},
	{name="mobs:meat_mutton", desc="Cooked Mutton", image="mobs_mutton.png", food=10},

	-- Pork.
	{name="mobs:meat_raw_pork", desc="Raw Pork (Yuck)", image="mobs_pork_raw.png", food=4, cooked="mobs:meat_pork", is_raw=true, is_gross=true},
	{name="mobs:meat_pork", desc="Cooked Pork (Yuck)", image="mobs_pork.png", food=7, is_gross=true},

	-- White Wolf.
	{name="nssm:white_wolf_leg", desc="White Wolf Leg", image="werewolf_leg.png", food=3, cooked="nssm:roasted_white_wolf_leg", is_raw=true},
	{name="nssm:roasted_white_wolf_leg", desc="Roasted White Wolf Leg", image="roasted_werewolf_leg.png", food=6},
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
					user:set_hp(user:get_hp() - (1*500), {reason="poison"})
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

	minetest.register_craftitem(":" .. v.name, {
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
	groups = {flammable = 2, leather = 1},
})

minetest.register_tool("mobs:net", {
	description = "Capturing Net",
	inventory_image = "mobs_net.png",
  groups = {not_repaired_by_anvil = 1, flammable = 2},
})



minetest.register_craft({
	output = "mobs:net",
	recipe = {
		{"group:stick",     "",                 "group:stick"     },
		{"group:stick",     "",                 "group:stick"     },
		{"farming:string",    "group:stick",    "farming:string"    },
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



--------------------------------------------------------------------------------
minetest.register_craftitem("mobs:leather_padding", {
	description = "Sewn Leather Padding",
	inventory_image = "mobs_leather_padding.png",
	groups = {flammable = 2, leather_padding = 1},
})

minetest.register_craft({
	output = "mobs:leather_padding",
	type = "shapeless",
	recipe = {"group:leather", "farming:string", "farming:cotton"},
})

minetest.register_craft({
	type = "fuel",
	recipe = "mobs:leather_padding",
	burntime = 6,
})



--------------------------------------------------------------------------------
minetest.register_craftitem("mobs:flame_bolt", {
	description = "Flame Bolt",
	inventory_image = "mobs_flame_bolt.png",
	groups = {flammable = 3},
	light_source = 14,
})

-- Stores metadata, needs wear bar.
-- Note: this also makes the staff repairable by combining it with another.
minetest.register_tool("mobs:flame_staff", {
	description = "Flame Staff",
	inventory_image = "mobs_flame_staff.png",
	groups = {flammable = 1, not_repaired_by_anvil = 1},
	light_source = 14,
	wear_represents = "teleport_uses",
	on_use = function(...)
		return obsidian_gateway.on_flamestaff_use(...)
	end,
})

minetest.register_craft({
	output = "mobs:flame_staff",
	recipe = {
		{"", "mobs:flame_bolt", ""},
		{"", "mobs:flame_bolt", ""},
		{"farming:cloth", "mobs:flame_bolt", "farming:cloth"},
	},
})
