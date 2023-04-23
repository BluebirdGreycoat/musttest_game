local hive = {}
local honey_max = 5

-- Localize for performance.
local math_random = math.random

local bees_time_min = 64
local bees_time_max = 64*8

local function update_formspec(pos, meta)
	local meta = meta or minetest.get_meta(pos)
	local status = meta:get_string("status")

	local text = "Bees are getting acclimated."
	if status ~= "" then
		text = status
	end

	local formspec = [[ size[8,5;]
			label[0.5,0;]] .. minetest.formspec_escape(text) .. [[]
			image[6,0;1,1;hive_bee.png]
			image[5,0;1,1;hive_layout.png]
			list[context;honey;5,0;1,1;]
			list[current_player;main;0,1.35;8,4;] ]]
			.. xbg .. default.get_hotbar_bg(0,1.35)

	meta:set_string("formspec", formspec)
end

function hive.construct(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	update_formspec(pos, meta)

	meta:set_string("infotext", "Beekeeper's Hive")
	inv:set_size("honey", 1)

	local timer = minetest.get_node_timer(pos)
	timer:start(math_random(bees_time_min, bees_time_max))
end

function hive.timer(pos)
	local time = (minetest.get_timeofday() or 0) * 24000
	if time < 5500 or time > 18500 then return true end

	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local honeystack = inv:get_stack("honey", 1)
	local honey = honeystack:get_count()

	local radius = 4
	local minp = vector.add(pos, -radius)
	local maxp = vector.add(pos, radius)
	local flowers = minetest.find_nodes_in_area_under_air(minp, maxp, "group:flower")

	local light = false
	local never_light = 0

	-- Don't bother with the light check unless other conditions are satisfied.
	if #flowers > 2 and honey < honey_max then
		local sides = {
			{x=1, y=0, z=0},
			{x=-1, y=0, z=0},
			{x=0, y=0, z=1},
			{x=0, y=0, z=-1},
			{x=0, y=1, z=0},
			{x=2, y=0, z=0},
			{x=-2, y=0, z=0},
			{x=0, y=0, z=2},
			{x=0, y=0, z=-2},
			{x=1, y=0, z=1},
			{x=-1, y=0, z=-1},
			{x=-1, y=0, z=1},
			{x=1, y=0, z=-1},
		}
		for k, v in ipairs(sides) do
			local p = vector.add(pos, v)
			local l = minetest.get_node_light(p) or 0
			if l >= 15 then
				light = true
				break
			end
			local nl = minetest.get_node_light(p, 0.5) or 0
			if nl < 15 then
				never_light = never_light + 1
			end
		end
	end

	if #flowers > 2 and honey < honey_max and light then
		inv:add_item("honey", "xdecor:honey")

		meta:set_string("status", "Bees are busy making honey ...")
		update_formspec(pos, meta)
	elseif honey == honey_max or never_light >= 13 then
		-- Honeycomb is full, or hive is underground/inside building.
		local timer = minetest.get_node_timer(pos)
		timer:stop()

		if never_light >= 13 then
			meta:set_string("status", "Bees are hibernating!")
			update_formspec(pos, meta)
		end

		return
	end

	if #flowers <= 2 then
		meta:set_string("status", "Lazy bees can't find flowers!")
		update_formspec(pos, meta)
	end

	return true
end

xdecor.register("hive", {
	description = "Beekeeper's Hive",
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

	on_punch = function(pos, node, puncher)
		if puncher:get_hp() > 0 then
			utility.damage_player(puncher, "poison", 2*500)

			if puncher:get_hp() <= 0 then
				minetest.chat_send_all("# Server: <" .. rename.gpn(puncher:get_player_name()) .. "> was stung by a swarm of angry bees.")
			end
		end

		-- Damage the honey stock.
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:remove_item("honey", "xdecor:honey")

		-- Restart timer.
		local timer = minetest.get_node_timer(pos)
		timer:start(math_random(bees_time_min, bees_time_max))
	end,

	allow_metadata_inventory_put = function() return 0 end,

	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		local timer = minetest.get_node_timer(pos)
		timer:start(math_random(bees_time_min, bees_time_max))

		-- Sting the player if they don't own this land.
		if player and minetest.test_protection(pos, player:get_player_name()) then
			if player:get_hp() > 0 then
				utility.damage_player(player, "poison", 1*500)

				if player:get_hp() <= 0 then
					minetest.chat_send_all("# Server: <" .. rename.gpn(player:get_player_name()) .. "> was stung by a swarm of angry bees.")
				end
			end
		end
	end
})

-- Craft items

minetest.register_craftitem("xdecor:honey", {
	description = "Raw Honeycomb",
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
