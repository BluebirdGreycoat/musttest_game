
local function get_sand_place_func(data)
	local function sand_on_place(itemstack, placer, pointed_thing)
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

		local player_name = placer:get_player_name()

		if not minetest.test_protection(pos, player_name) then
			minetest.set_node(pos, {name = data.nodename})
			itemstack:take_item()
		end

		return itemstack
	end

	return sand_on_place
end



local sand_deco_info = {
	{name="Nautilus", overlay="decorations_sea_seashell_01_overlay.png", inv="decorations_sea_seashell_01.png"},
	{name="Clam Shell", overlay="decorations_sea_seashell_02_overlay.png", inv="decorations_sea_seashell_02.png"},
	{name="Conch", overlay="decorations_sea_seashell_03_overlay.png", inv="decorations_sea_seashell_03.png"},
	{name="Orange Starfish", overlay="decorations_sea_starfish_01.png", inv="decorations_sea_starfish_01.png"},
	{name="Blue Starfish", overlay="decorations_sea_starfish_02.png", inv="decorations_sea_starfish_02.png"},
}
for k = 1, 5 do
	local nodename = "decorations_sea:sand_decoration_" .. k

	minetest.register_node(nodename, {
		description = sand_deco_info[k].name,
		waving = 1,
		tiles = {
			"default_sand.png^" .. sand_deco_info[k].overlay,
			"default_sand.png",
		},
		inventory_image = sand_deco_info[k].inv,
		wield_image = sand_deco_info[k].inv,
		paramtype = "light",
		paramtype2 = "leveled",
		groups = utility.dig_groups("plant"),
		node_dig_prediction = "default:sand",
		node_placement_prediction = "",
		sounds = default.node_sound_sand_defaults({
			dig = {name = "default_dig_snappy", gain = 0.2},
			dug = {name = "default_grass_footstep", gain = 0.25},
		}),

		on_place = get_sand_place_func({
			nodename = nodename,
		}),

		after_destruct  = function(pos, oldnode)
			minetest.set_node(pos, {name = "default:sand"})
		end
	})
end
