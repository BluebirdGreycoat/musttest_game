
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
	{name="mobs:meat", desc="Cooked Meat (Unidentified)\n\nEat to improve resistance to certain kinds of damage, for a time.", image="mobs_meat.png", food=6},

	-- Naraxen meat.
	{name="mobs:naraxen_meat_raw", desc="Raw Naraxen Meat (Unidentified)", image="mobs_meat_raw.png", food=3, cooked="mobs:naraxen_meat", is_raw=true},
	{name="mobs:naraxen_meat", desc="Naraxen Meat (Unidentified)", image="mobs_meat.png", food=6},

	-- Mutton.
	{name="mobs:meat_raw_mutton", desc="Raw Mutton", image="mobs_mutton_raw.png", food=4, cooked="mobs:meat_mutton", is_raw=true},
	{name="mobs:meat_mutton", desc="Cooked Mutton\n\nEat to improve resistance to certain kinds of damage, for a time.", image="mobs_mutton.png", food=10},

	-- Pork.
	{name="mobs:meat_raw_pork", desc="Raw Pork (Yuck)", image="mobs_pork_raw.png", food=4, cooked="mobs:meat_pork", is_raw=true, is_gross=true},
	{name="mobs:meat_pork", desc="Cooked Pork (Yuck)\n\nEat to improve resistance to certain kinds of damage, for a time.", image="mobs_pork.png", food=7, is_gross=true},

	-- White Wolf.
	{name="nssm:white_wolf_leg", desc="White Wolf Leg", image="werewolf_leg.png", food=3, cooked="nssm:roasted_white_wolf_leg", is_raw=true},
	{name="nssm:roasted_white_wolf_leg", desc="Roasted White Wolf Leg\n\nEat to improve resistance to certain kinds of damage, for a time.", image="roasted_werewolf_leg.png", food=6},
}

for k, v in ipairs(meat_types) do
	local eat_meat = minetest.item_eat(v.food)
	local do_eat_meat = function(itemstack, user, pointed_thing)
		-- Damage player only if meat was raw.
		if v.is_raw then
			-- Do not kill player.
			if user:get_hp() > 1*500 then
				-- Light poisoning that lasts awhile.
				hb4.delayed_harm({
					name = user:get_player_name(),
					step = 15,
					min = 50,
					max = 100,
					hp_min = 1,
					poison = true,
				})
			end
		end

		if v.name == "mobs:meat_mutton" then
			hunger.apply_damage_resistance(user:get_player_name(), "mutton", {resistance=0.8, time=30})
		elseif v.name == "nssm:roasted_white_wolf_leg" then
			hunger.apply_damage_resistance(user:get_player_name(), "wolf", {resistance=0.3, time=360})
		elseif v.name == "mobs:meat_pork" then
			hunger.apply_damage_resistance(user:get_player_name(), "pork", {resistance=0.7, time=10})
		elseif v.name == "mobs:meat" then
			hunger.apply_damage_resistance(user:get_player_name(), "pork", {resistance=0.5, time=7})
		end

		-- Send message if meat was raw or gross.
		if v.is_gross or v.is_raw then
			local pname = user:get_player_name()
			local key = pname .. ":gross_food"
			if not spam.test_key(key) then
				minetest.chat_send_player(pname,
					"# Server: You eat " .. utility.get_short_desc(v.desc) .. "? Eww, gross!")
				spam.mark_key(key, 60*60)
			end
		end

		return eat_meat(itemstack, user, pointed_thing)
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
		_xp_zerocost_drop = true,
		_xdecor_soup_ingredient = true,
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
-- Stores metadata, needs wear bar.
-- Note: this also makes the staff repairable by combining it with another.
minetest.register_tool("mobs:flame_staff", {
	description = "Flame Staff",
	inventory_image = "mobs_flame_staff.png",
	wield_image = "mobs_flame_staff.png^[transformR270",
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
