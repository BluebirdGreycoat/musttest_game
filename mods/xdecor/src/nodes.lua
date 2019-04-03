screwdriver = screwdriver or {}

local function register_pane(name, desc, def)
	xpanes.register_pane(name, {
		description = desc,
		tiles = {"xdecor_"..name..".png"},
		drawtype = "airlike",
		paramtype = "light",
		textures = {"xdecor_"..name..".png", "xdecor_"..name..".png", "xpanes_space.png"},
		inventory_image = "xdecor_"..name..".png",
		wield_image = "xdecor_"..name..".png",
		groups = def.groups,
		sounds = def.sounds or default.node_sound_defaults(),
		recipe = def.recipe
	})
end

register_pane("bamboo_frame", "Bamboo Frame", {
	groups = utility.dig_groups("pane_wood", {pane=1, flammable=2}),
	recipe = {{"default:papyrus", "default:papyrus", "default:papyrus"},
		  {"default:papyrus", "farming:cotton",  "default:papyrus"},
		  {"default:papyrus", "default:papyrus", "default:papyrus"}}
})

register_pane("chainlink", "Chain Link Mesh", {
	groups = utility.dig_groups("pane_metal", {pane=1}),
	recipe = {{"default:steel_ingot", "", "default:steel_ingot"},
		  {"", "default:steel_ingot", ""},
		  {"default:steel_ingot", "", "default:steel_ingot"}},
	sounds = default.node_sound_metal_defaults(),
})

register_pane("rusty_bar", "Rusty Iron Bars", {
	sounds = default.node_sound_stone_defaults(),
	groups = utility.dig_groups("pane_metal", {pane=1}),
	recipe = {{"", "default:dirt", ""},
		  {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		  {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"}},
	sounds = default.node_sound_metal_defaults(),
})

register_pane("wood_frame", "Wood Frame", {
	sounds = default.node_sound_wood_defaults(),
	groups = utility.dig_groups("pane_wood", {pane=1, flammable=2}),
	recipe = {{"group:wood", "group:stick", "group:wood"},
		  {"group:stick", "group:stick", "group:stick"},
		  {"group:wood", "group:stick", "group:wood"}}
})

xdecor.register("baricade", {
	description = "Baricade",
	drawtype = "plantlike",
	paramtype2 = "facedir",
	inventory_image = "xdecor_baricade.png",
	tiles = {"xdecor_baricade.png"},
	groups = utility.dig_groups("wood", {flammable=2}),
	damage_per_second = 4,
	selection_box = xdecor.nodebox.slab_y(0.3),
	collision_box = xdecor.pixelbox(2, {{0, 0, 1, 2, 2, 0}})
})

xdecor.register("barrel", {
	description = "Barrel",
	tiles = {"xdecor_barrel_top.png", "xdecor_barrel_top.png", "xdecor_barrel_sides.png"},
	on_place = minetest.rotate_node,
	groups = utility.dig_groups("wood", {flammable=2}),
	sounds = default.node_sound_wood_defaults(),
	nostairs = true,
})

local function register_storage(name, desc, def)
	xdecor.register(name, {
		description = desc,
		inventory = {size=def.inv_size or 24},
		infotext = desc,
		tiles = def.tiles,
		node_box = def.node_box,
		on_rotate = def.on_rotate,
		on_place = def.on_place,
		groups = def.groups or utility.dig_groups("furniture", {flammable=2}),
		sounds = default.node_sound_wood_defaults(),
	})
end

register_storage("cabinet", "Wooden Cabinet", {
	on_rotate = screwdriver.rotate_simple,
	tiles = {"xdecor_cabinet_sides.png", "xdecor_cabinet_sides.png",
		 "xdecor_cabinet_sides.png", "xdecor_cabinet_sides.png",
		 "xdecor_cabinet_sides.png", "xdecor_cabinet_front.png"}
})

register_storage("cabinet_half", "Half Wooden Cabinet", {
	inv_size = 8,
	node_box = xdecor.nodebox.slab_y(0.5, 0.5),
	on_rotate = screwdriver.rotate_simple,
	tiles = {"xdecor_cabinet_sides.png", "xdecor_cabinet_sides.png",
		 "xdecor_half_cabinet_sides.png", "xdecor_half_cabinet_sides.png",
		 "xdecor_half_cabinet_sides.png", "xdecor_half_cabinet_front.png"}
})

register_storage("empty_shelf", "Empty Shelf", {
	on_rotate = screwdriver.rotate_simple,
	tiles = {"default_wood.png", "default_wood.png", "default_wood.png",
		 "default_wood.png", "default_wood.png^xdecor_empty_shelf.png"}
})

register_storage("multishelf", "Multi Shelf", {
	on_rotate = screwdriver.rotate_simple,
	tiles = {"default_wood.png", "default_wood.png", "default_wood.png",
		 "default_wood.png", "default_wood.png^xdecor_multishelf.png"},
})

xdecor.register("candle", {
	description = "Candle",
	light_source = 8,
	drawtype = "torchlike",
	inventory_image = "xdecor_candle_inv.png",
	wield_image = "xdecor_candle_wield.png",
	paramtype2 = "wallmounted",
	walkable = false,
	groups = utility.dig_groups("item", {attached_node=1}),
	tiles = {{name = "xdecor_candle_floor.png",
			animation = {type="vertical_frames", length=1.5}},
		{name = "xdecor_candle_floor.png",
			animation = {type="vertical_frames", length=1.5}},
		{name = "xdecor_candle_wall.png",
			animation = {type="vertical_frames", length=1.5}}
	},
	selection_box = {
		type = "wallmounted",
		wall_top = {-0.25, -0.5, -0.25, 0.25, 0.1, 0.25},
		wall_bottom = {-0.25, -0.5, -0.25, 0.25, 0.1, 0.25},
		wall_side = {-0.5, -0.35, -0.15, -0.15, 0.4, 0.15}
	}
})

xdecor.register("chair", {
	description = "Chair",
	tiles = {"xdecor_wood.png"},
	sounds = default.node_sound_wood_defaults(),
	groups = utility.dig_groups("furniture", {flammable=2}),
	on_rotate = screwdriver.rotate_simple,
	node_box = xdecor.pixelbox(16, {
		{3,  0, 11,   2, 16, 2}, {11, 0, 11,  2, 16, 2},
		{5,  9, 11.5, 6,  6, 1}, {3,  0,  3,  2,  6, 2},
		{11, 0,  3,   2,  6, 2}, {3,  6,  3, 10, 2, 8}
	}),
	--can_dig = xdecor.sit_dig,
	--on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
	--	pos.y = pos.y + 0  -- Sitting position
	--	xdecor.sit(pos, node, clicker, pointed_thing)
	--	return itemstack
	--end
})

xdecor.register("cobweb", {
	description = "Cobweb",
	drawtype = "plantlike",
	tiles = {"xdecor_cobweb.png"},
	inventory_image = "xdecor_cobweb.png",
	liquid_viscosity = 8,
	liquidtype = "source",
	liquid_alternative_flowing = "xdecor:cobweb",
	liquid_alternative_source = "xdecor:cobweb",
	liquid_renewable = false,
	liquid_range = 0,
	walkable = false,
	selection_box = {type = "regular"},
	groups = utility.dig_groups("plant", {flammable=3}),
	sounds = default.node_sound_leaves_defaults(),

	drop = "farming:cotton 5",
	shears_drop = true,
})

-- Only permit colors the Minetest client understands.
local curtain_colors = {
	"red",
	"blue",
	"green",
	"yellow",
	"cyan",
	"magenta",
	"pink",
	"black",
	"white",
	"grey",
	"orange",
	"brown",
	"violet",
}

for _, c in pairs(curtain_colors) do
	xdecor.register("curtain_"..c, {
		description = c:gsub("^%l", string.upper).." Curtain",
		walkable = false,
		tiles = {"wool_white.png"},
		color = c,
		inventory_image = "wool_white.png^[colorize:"..c..
			":170^xdecor_curtain_open_overlay.png^[makealpha:255,126,126",
		wield_image = "wool_white.png^[colorize:"..c..":170",
		drawtype = "signlike",
		paramtype2 = "colorwallmounted",
		groups = utility.dig_groups("item", {flammable=3}),
		selection_box = {type="wallmounted"},
		on_rightclick = function(pos, node, _, itemstack)
			minetest.set_node(pos, {name="xdecor:curtain_open_"..c, param2=node.param2})
			return itemstack
		end
	})

	xdecor.register("curtain_open_"..c, {
		tiles = {"wool_white.png^xdecor_curtain_open_overlay.png^[makealpha:255,126,126"},
		color = c,
		drawtype = "signlike",
		paramtype2 = "colorwallmounted",
		walkable = false,
		groups = utility.dig_groups("item", {flammable=3, not_in_creative_inventory=1}),
		selection_box = {type="wallmounted"},
		drop = "xdecor:curtain_"..c,
		on_rightclick = function(pos, node, _, itemstack)
			minetest.set_node(pos, {name="xdecor:curtain_"..c, param2=node.param2})
			return itemstack
		end
	})

	minetest.register_craft({
		output = "xdecor:curtain_"..c.." 4",
		recipe = {{"", "wool:"..c, ""},
			  {"", "wool:"..c, ""}}
	})
end

xdecor.register("cushion", {
	description = "Cushion",
	tiles = {"xdecor_cushion.png"},
	groups = utility.dig_groups("furniture", {flammable=3, fall_damage_add_percent=-50}),
	on_place = minetest.rotate_node,
	node_box = xdecor.nodebox.slab_y(0.5),
	--can_dig = xdecor.sit_dig,
	--on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
	--	pos.y = pos.y + 0  -- Sitting position
	--	xdecor.sit(pos, node, clicker, pointed_thing)
	--	return itemstack
	--end
})

xdecor.register("cushion_block", {
	description = "Cushion Block",
	tiles = {"xdecor_cushion.png"},
	groups = utility.dig_groups("furniture", {flammable=3, fall_damage_add_percent=-75, not_in_creative_inventory=1})
})

local function door_access(name)
	return name:find("prison")
end

local xdecor_doors = {
	japanese = { recipe = {
		{"group:wood", "default:paper"},
		{"default:paper", "group:wood"},
		{"group:wood", "default:paper"}}, groups=utility.dig_groups("door_wood") },
	prison = { recipe = {
		{"xpanes:bar_flat", "xpanes:bar_flat",},
		{"xpanes:bar_flat", "xpanes:bar_flat",},
		{"xpanes:bar_flat", "xpanes:bar_flat"}}, groups=utility.dig_groups("door_metal") },
	rusty_prison = { recipe = {
		{"xpanes:rusty_bar_flat", "xpanes:rusty_bar_flat",},
		{"xpanes:rusty_bar_flat", "xpanes:rusty_bar_flat",},
		{"xpanes:rusty_bar_flat", "xpanes:rusty_bar_flat"}}, groups=utility.dig_groups("door_metal") },
	screen = { recipe = {
		{"group:wood", "group:wood"},
		{"xpanes:chainlink_flat", "xpanes:chainlink_flat"},
		{"group:wood", "group:wood"}}, groups=utility.dig_groups("door_wood") },
	slide = { recipe = {
		{"default:paper", "default:paper"},
		{"default:paper", "default:paper"},
		{"group:wood", "group:wood"}}, groups=utility.dig_groups("door_wood") },
	woodglass = { recipe = {
		{"default:glass", "default:glass"},
		{"group:wood", "group:wood"},
		{"group:wood", "group:wood"}}, groups=utility.dig_groups("door_wood") },
	stone = { recipe = {
		{"default:stone", "default:stone"},
		{"default:stone", "default:stone"},
		{"default:stone", "default:stone"}}, groups=utility.dig_groups("door_stone") },
}

for name, entry in pairs(xdecor_doors) do
	local recipe = entry.recipe
	local groups = entry.groups
	groups.door = 1
	if not doors.register then break end
	doors.register(name.."_door", {
		tiles = {{name = "xdecor_"..name.."_door.png", backface_culling=true}},
		description = name:gsub("%f[%w]%l", string.upper):gsub("_", " ").." Door",
		inventory_image = "xdecor_"..name.."_door_inv.png",
		protected = door_access(name),
		groups = groups,
		recipe = recipe,
	})
end

xdecor.register("xchest", {
	description = "Void Chest\n\nHas a (small) shared inventory with other Void Chests.",
	tiles = {"xdecor_enderchest_top.png", "xdecor_enderchest_top.png",
		 "xdecor_enderchest_side.png", "xdecor_enderchest_side.png",
		 "xdecor_enderchest_side.png", "xdecor_enderchest_front.png"},
	groups = utility.dig_groups("chest"),
	sounds = default.node_sound_stone_defaults(),
	on_rotate = screwdriver.rotate_simple,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", [[ size[8,6]
				list[current_player;xchest;0,0;8,1;]
				list[current_player;main;0,2;8,4;]
				listring[current_player;xchest]
				listring[current_player;main] ]]
				..xbg..default.get_hotbar_bg(0,2))
		meta:set_string("infotext", "Void Chest")
	end
})

minetest.register_on_joinplayer(function(player)
	local inv = player:get_inventory()
	inv:set_size("xchest", 8)
end)

xdecor.register("ivy", {
	description = "Ivy",
	drawtype = "signlike",
	walkable = false,
	climbable = true,
	groups = utility.dig_groups("plant", {flora=1, attached_node=1, plant=1, flammable=3}),
	paramtype2 = "wallmounted",
	selection_box = {type="wallmounted"},
	tiles = {"xdecor_ivy.png"},
	inventory_image = "xdecor_ivy.png",
	wield_image = "xdecor_ivy.png",
	sounds = default.node_sound_leaves_defaults()
})

xdecor.register("lantern", {
	description = "Lantern",
	light_source = 13,
	drawtype = "plantlike",
	inventory_image = "xdecor_lantern_inv.png",
	wield_image = "xdecor_lantern_inv.png",
	paramtype2 = "wallmounted",
	walkable = false,
	groups = utility.dig_groups("item", {attached_node=1}),
	tiles = {{name="xdecor_lantern.png", animation={type="vertical_frames", length=1.5}}},
	selection_box = xdecor.pixelbox(16, {{4, 0, 4, 8, 16, 8}})
})

for _, l in pairs({"iron", "wooden"}) do
	xdecor.register(l.."_lightbox", {
		description = l:gsub("^%l", string.upper).." Light Box",
		tiles = {"xdecor_"..l.."_lightbox.png"},
		groups = utility.dig_groups("bigitem"),
		light_source = 13,
		sounds = default.node_sound_glass_defaults()
	})
end

for _, f in pairs({"dandelion_white", "dandelion_yellow", "geranium",
		"rose", "tulip", "viola"}) do
	xdecor.register("potted_"..f, {
		description = "Potted "..f:gsub("%f[%w]%l", string.upper):gsub("_", " "),
		walkable = false,
		groups = utility.dig_groups("item", {flammable=3}),
		tiles = {"xdecor_"..f.."_pot.png"},
		inventory_image = "xdecor_"..f.."_pot.png",
		drawtype = "plantlike",
		sounds = default.node_sound_leaves_defaults(),
		selection_box = xdecor.nodebox.slab_y(0.3)
	})

	minetest.register_craft({
		output = "xdecor:potted_"..f,
		recipe = {{"default:clay_brick", "flowers:"..f,
			   "default:clay_brick"}, {"", "default:clay_brick", ""}}
	})
end

local painting_box = {
	type = "wallmounted",
	wall_top = {-0.4375, 0.4375, -0.3125, 0.4375, 0.5, 0.3125},
	wall_bottom = {-0.4375, -0.5, -0.3125, 0.4375, -0.4375, 0.3125},
	wall_side = {-0.5, -0.3125, -0.4375, -0.4375, 0.3125, 0.4375}
}

xdecor.register("painting_1", {
	description = "Painting",
	tiles = {"xdecor_painting_1.png"},
	inventory_image = "xdecor_painting_empty.png",
	wield_image = "xdecor_painting_empty.png",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	groups = utility.dig_groups("item", {flammable=2, attached_node=1}),
	sounds = default.node_sound_wood_defaults(),
	node_box = painting_box,
	node_placement_prediction = "",
	walkable = false,

	on_place = function(itemstack, placer, pointed_thing)
		local num = math.random(4)
		local leftover = minetest.item_place_node(
			ItemStack("xdecor:painting_"..num), placer, pointed_thing)
		if leftover:get_count() == 0 and
				not minetest.setting_getbool("creative_mode") then
			itemstack:take_item()
		end
		return itemstack
	end,
})

for i = 2, 4 do
	xdecor.register("painting_"..i, {
		tiles = {"xdecor_painting_"..i..".png"},
		paramtype2 = "wallmounted",
		drop = "xdecor:painting_1",
		sunlight_propagates = true,
		groups = utility.dig_groups("item", {flammable=2,
			  attached_node=1, not_in_creative_inventory=1}),
		sounds = default.node_sound_wood_defaults(),
		node_box = painting_box,
		walkable = false,
	})
end

xdecor.register("stonepath", {
	description = "Garden Stone Path",
	tiles = {"default_stone.png"},
	groups = utility.dig_groups("bigitem"),
	on_rotate = screwdriver.rotate_simple,
	sounds = default.node_sound_stone_defaults(),
	sunlight_propagates = true,
	node_box = xdecor.pixelbox(16, {
		{8, 0,  8, 6, .5, 6}, {1,  0, 1, 6, .5, 6},
		{1, 0, 10, 5, .5, 5}, {10, 0, 2, 4, .5, 4}
	}),
	selection_box = xdecor.nodebox.slab_y(0.05),
	on_construct = function(pos)
		local node = minetest.get_node(pos)
		node.param2 = math.random(1, 3)
		minetest.swap_node(pos, node)
	end,
	movement_speed_multiplier = default.NORM_SPEED,
})

local function register_hard_node(name, desc, def)
	def = def or {}
	xdecor.register(name, {
		description = desc,
		tiles = {"xdecor_"..name..".png"},
		groups = def.groups or utility.dig_groups("hardstone"),
		sounds = def.sounds or default.node_sound_stone_defaults(),
	})
end

register_hard_node("cactusbrick", "Cactus Brick")
register_hard_node("coalstone_tile", "Coal Stone Tile")
register_hard_node("desertstone_tile", "Desert Stone Tile")
register_hard_node("hard_clay", "Hardened Clay")
register_hard_node("moonbrick", "Moon Brick")
register_hard_node("stone_tile", "Clean Stone Tile")
register_hard_node("stone_rune", "Rune Stone")
register_hard_node("packed_ice", "Packed Ice", {
	groups = utility.dig_groups("hardice", {puts_out_fire=1, slippery=3}),
	sounds = default.node_sound_glass_defaults(),
})
register_hard_node("wood_tile", "Wooden Tile", {
	groups = utility.dig_groups("hardwood", {wood=1, flammable=2}),
	sounds = default.node_sound_wood_defaults()
})

xdecor.register("table", {
	description = "Table",
	tiles = {"xdecor_wood.png"},
	groups = utility.dig_groups("furniture", {flammable=2}),
	sounds = default.node_sound_wood_defaults(),
	node_box = xdecor.pixelbox(16, {
		{0, 14, 0, 16, 2, 16}, {5.5, 0, 5.5, 5, 14, 6}
	})
})

xdecor.register("tatami", {
	description = "Tatami",
	tiles = {"xdecor_tatami.png"},
	wield_image = "xdecor_tatami.png",
	groups = utility.dig_groups("bigitem", {flammable=3}),
	sunlight_propagates = true,
	node_box = xdecor.nodebox.slab_y(0.0625)
})

xdecor.register("trampoline", {
	description = "Trampoline",
	tiles = {"xdecor_trampoline.png", "mailbox_blank16.png", "xdecor_trampoline_sides.png"},
	groups = utility.dig_groups("furniture", {fall_damage_add_percent=-80, bouncy=90}),
	node_box = xdecor.nodebox.slab_y(0.5),
	sounds = {footstep = {name="xdecor_bouncy", gain=0.8}}
})

xdecor.register("tv", {
	description = "Television",
	light_source = 11,
	groups = utility.dig_groups("furniture"),
	on_rotate = screwdriver.rotate_simple,
	tiles = {"xdecor_television_left.png^[transformR270",
		 "xdecor_television_left.png^[transformR90",
		 "xdecor_television_left.png^[transformFX",
		 "xdecor_television_left.png", "xdecor_television_back.png",
		{name="xdecor_television_front_animated.png",
		 animation = {type="vertical_frames", length=80.0}} }
})

xdecor.register("woodframed_glass", {
	description = "Wood Framed Glass",
	drawtype = "glasslike_framed",
	sunlight_propagates = true,
	tiles = {"xdecor_woodframed_glass.png", "xdecor_woodframed_glass_detail.png"},
	groups = utility.dig_groups("glass"),
	sounds = default.node_sound_glass_defaults(),
	silverpick_drop = true,

	drop = {
		max_items = 2,
		items = {
			{
				items = {"vessels:glass_fragments", "default:stick 2"},
				rarity = 1,
			},
		}
	},
})
