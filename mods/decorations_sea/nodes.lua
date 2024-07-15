
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
