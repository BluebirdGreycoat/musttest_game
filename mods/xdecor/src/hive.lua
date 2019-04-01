local hive = {}
local honey_max = 5

function hive.construct(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	local formspec = [[ size[8,5;]
			label[0.5,0;Bees are busy making honey ...]
			image[6,0;1,1;hive_bee.png]
			image[5,0;1,1;hive_layout.png]
			list[context;honey;5,0;1,1;]
			list[current_player;main;0,1.35;8,4;] ]]
			..xbg..default.get_hotbar_bg(0,1.35)

	meta:set_string("formspec", formspec)
	meta:set_string("infotext", "Artificial Hive")
	inv:set_size("honey", 1)

	local timer = minetest.get_node_timer(pos)
	timer:start(math.random(64, 128))
end

function hive.timer(pos)
	local time = (minetest.get_timeofday() or 0) * 24000
	if time < 5500 or time > 18500 then return true end

	local inv = minetest.get_meta(pos):get_inventory()
	local honeystack = inv:get_stack("honey", 1)
	local honey = honeystack:get_count()

	local radius = 4
	local minp = vector.add(pos, -radius)
	local maxp = vector.add(pos, radius)
	local flowers = minetest.find_nodes_in_area_under_air(minp, maxp, "group:flower")

	if #flowers > 2 and honey < honey_max then
		inv:add_item("honey", "xdecor:honey")
	elseif honey == honey_max then
		local timer = minetest.get_node_timer(pos)
		timer:stop()
		return
	end
	return true
end

xdecor.register("hive", {
	description = "Artificial Hive",
	tiles = {"xdecor_hive_top.png", "xdecor_hive_top.png",
		 "xdecor_hive_side.png", "xdecor_hive_side.png",
		 "xdecor_hive_side.png", "xdecor_hive_front.png"},
	groups = utility.dig_groups("wood", {flammable=1}),
	on_construct = hive.construct,
	on_timer = hive.timer,
	can_dig = function(pos)
		local inv = minetest.get_meta(pos):get_inventory()
		return inv:is_empty("honey")
	end,
	on_punch = function(_, _, puncher)
		if puncher:get_hp() > 0 then
			puncher:set_hp(puncher:get_hp() - 2)
			if puncher:get_hp() <= 0 then
				minetest.chat_send_all("# Server: <" .. rename.gpn(puncher:get_player_name()) .. "> was stung by a swarm of angry bees.")
			end
		end
	end,
	allow_metadata_inventory_put = function() return 0 end,
	on_metadata_inventory_take = function(pos, _, _, stack)
		local timer = minetest.get_node_timer(pos)
		timer:start(math.random(64, 128))
	end
})

-- Craft items

minetest.register_craftitem("xdecor:honey", {
	description = "Honey",
	inventory_image = "xdecor_honey.png",
	wield_image = "xdecor_honey.png",
	groups = {food_honey = 1, food_sugar = 1, flammable = 2, not_in_creative_inventory=1},
	on_use = minetest.item_eat(2)
})

-- Recipes

minetest.register_craft({
	output = "xdecor:hive",
	recipe = {
		{"group:stick", "group:stick", "group:stick"},
		{"default:paper", "basictrees:tree_wood", "default:paper"},
		{"group:stick", "group:stick", "group:stick"}
	}
})
