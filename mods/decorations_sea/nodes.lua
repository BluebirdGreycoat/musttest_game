
local function coral_on_place(itemstack, placer, pointed_thing)
	if pointed_thing.type ~= "node" or not placer then
		return itemstack
	end

	local player_name = placer:get_player_name()
	local pos_under = pointed_thing.under
	local pos_above = pointed_thing.above
	local node_under = minetest.get_node(pos_under)
	local def_under = minetest.registered_nodes[node_under.name]

	if def_under and def_under.on_rightclick and not placer:get_player_control().sneak then
		return def_under.on_rightclick(pos_under, node_under, placer, itemstack, pointed_thing) or itemstack
	end

	local water_group = minetest.get_item_group(minetest.get_node(pos_above).name, "water")
	if node_under.name ~= "default:coral_skeleton" or water_group == 0 then
		return itemstack
	end

	if minetest.test_protection(pos_under, player_name) or minetest.test_protection(pos_above, player_name) then
		return itemstack
	end

	node_under.name = itemstack:get_name()
	minetest.set_node(pos_under, node_under)

	itemstack:take_item()
	return itemstack
end



local plant_coral_info = {
	{name="Fire Coral"},
	{name="Pink Sea Fan"},
	{name="Green Staghorn"},
	{name="Purple Sea Fan"},
	{name="Sun Coral"},
}
for k = 1, 5 do
	local tex = "decorations_sea_coral_0" .. k .. ".png"

	minetest.register_node("decorations_sea:plant_coral_" .. k, {
		description = plant_coral_info[k].name,
		drawtype = "plantlike_rooted",
		waving = 1,
		paramtype = "light",
		tiles = {"default_coral_skeleton.png"},
		special_tiles = {{name = tex, tileable_vertical = true}},
		inventory_image = tex,
		wield_image = tex,
		groups = utility.dig_groups("plant"),
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
				{-4/16, 0.5, -4/16, 4/16, 1.5, 4/16},
			},
		},
		node_dig_prediction = "default:coral_skeleton",
		node_placement_prediction = "",
		sounds = default.node_sound_stone_defaults({
			dig = {name = "default_dig_snappy", gain = 0.2},
			dug = {name = "default_grass_footstep", gain = 0.25},
		}),

		on_place = coral_on_place,

		after_destruct  = function(pos, oldnode)
			minetest.set_node(pos, {name = "default:coral_skeleton"})
		end,
	})
end



local node_coral_info = {
	{name="Blue Ridge Coral"},
	{name="Orange Rock Coral"},
	{name="Rose Coral"},
	{name="Purple Staghorn"},
	{name="Oxblood Coral"},
	{name="Yellow Emerald Coral"},
	{name="Red Vanhorn"},
	{name="Green Polyps"},
}
for k = 1, 8 do
	local tex = "decorations_sea_coral_node_0" .. k .. ".png"

	minetest.register_node("decorations_sea:node_coral_" .. k, {
		description = node_coral_info[k].name,
		tiles = {tex},
		groups = utility.dig_groups("cobble"),
		drop = "default:coral_skeleton",
		silverpick_drop = true,
		sounds = default.node_sound_stone_defaults(),
	})
end



local function get_deco_place_func(data)
	local function deco_on_place(itemstack, placer, pointed_thing)
		-- Call on_rightclick if the pointed node defines it
		if pointed_thing.type == "node" and placer and not placer:get_player_control().sneak then
			local node_ptu = minetest.get_node(pointed_thing.under)
			local def_ptu = minetest.registered_nodes[node_ptu.name]
			if def_ptu and def_ptu.on_rightclick then
				return def_ptu.on_rightclick(pointed_thing.under, node_ptu, placer, itemstack, pointed_thing)
			end
		end

		local pos = pointed_thing.under
		if minetest.get_node(pos).name ~= "default:sand" then
			return itemstack
		end

		local height = math.random(data.min_height, data.max_height)
		local pos_top = {x = pos.x, y = pos.y + height, z = pos.z}
		local node_top = minetest.get_node(pos_top)
		local def_top = minetest.registered_nodes[node_top.name]
		local player_name = placer:get_player_name()

		if def_top and def_top.liquidtype == "source" and minetest.get_item_group(node_top.name, "water") > 0 then
			if not minetest.test_protection(pos, player_name) and not minetest.test_protection(pos_top, player_name) then
				minetest.set_node(pos, {name = data.nodename, param2 = height * 16})
				itemstack:take_item()
			end
		end

		return itemstack
	end

	return deco_on_place
end



local sand_plant_info = {
	{name="Giant Kelp", min_height=3, max_height=14, box={-2/16, 0.5, -2/16, 2/16, 3.5, 2/16}},
	{name="Red Dulse", min_height=3, max_height=6, box={-2/16, 0.5, -2/16, 2/16, 3.5, 2/16}},
	{name="Sea Lettuce", min_height=3, max_height=6, box={-2/16, 0.5, -2/16, 2/16, 3.5, 2/16}},
	{name="Sea Grass", min_height=1, max_height=1, box={-4/16, 0.5, -4/16, 4/16, 1.5, 4/16}},
	{name="Sea Fern", min_height=1, max_height=1, box={-4/16, 0.5, -4/16, 4/16, 1.5, 4/16}},
	{name="Seaweed", min_height=1, max_height=1, box={-4/16, 0.5, -4/16, 4/16, 1.5, 4/16}},
}
for k = 1, 6 do
	local tex = "decorations_sea_seagrass_0" .. k .. ".png"
	local nodename = "decorations_sea:sand_with_seagrass_" .. k

	minetest.register_node(nodename, {
		description = sand_plant_info[k].name,
		drawtype = "plantlike_rooted",
		waving = 1,
		tiles = {"default_sand.png"},
		special_tiles = {{name = tex, tileable_vertical = true}},
		inventory_image = tex,
		wield_image = tex,
		paramtype = "light",
		paramtype2 = "leveled",
		groups = utility.dig_groups("plant", {flammable = 2}),
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
				sand_plant_info[k].box,
			},
		},
		node_dig_prediction = "default:sand",
		node_placement_prediction = "",
		sounds = default.node_sound_sand_defaults({
			dig = {name = "default_dig_snappy", gain = 0.2},
			dug = {name = "default_grass_footstep", gain = 0.25},
		}),

		on_place = get_deco_place_func({
			min_height = sand_plant_info[k].min_height,
			max_height = sand_plant_info[k].max_height,
			nodename = nodename,
		}),

		after_destruct  = function(pos, oldnode)
			minetest.set_node(pos, {name = "default:sand"})
		end
	})
end
