
local function is_pane(pos)
	return minetest.get_item_group(minetest.get_node(pos).name, "pane") > 0
end

local function connects_dir(pos, name, dir)
	local aside = vector.add(pos, minetest.facedir_to_dir(dir))
	if is_pane(aside) then
		return true
	end

	local ndef = minetest.reg_ns_nodes[name]
	if not ndef or not ndef.connects_to then
		return false
	end

	local list = minetest.find_nodes_in_area(aside, aside, ndef.connects_to)

	if #list > 0 then
		return true
	end

	return false
end

local function swap(pos, node, name, param2)
	if node.name == name and node.param2 == param2 then
		return
	end

	-- Use swap_node to avoid infinite callbacks.
	minetest.swap_node(pos, {name = name, param2 = param2})
end

local function update_pane(pos)
	if not is_pane(pos) then
		return
	end
	local node = minetest.get_node(pos)
	local name = node.name
	if name:sub(-5) == "_flat" then
		name = name:sub(1, -6)
	end

	local any = node.param2
	local c = {}
	local count = 0
	for dir = 0, 3 do
		c[dir] = connects_dir(pos, name, dir)
		if c[dir] then
			any = dir
			count = count + 1
		end
	end

	if count == 0 then
		swap(pos, node, name .. "_flat", any)
	elseif count == 1 then
		swap(pos, node, name .. "_flat", (any + 1) % 4)
	elseif count == 2 then
		if (c[0] and c[2]) or (c[1] and c[3]) then
			swap(pos, node, name .. "_flat", (any + 1) % 4)
		else
			swap(pos, node, name, 0)
		end
	else
		swap(pos, node, name, 0)
	end
end

--[[
minetest.register_on_placenode(function(pos, node)
	if minetest.get_item_group(node, "pane") then
		update_pane(pos)
	end
	for i = 0, 3 do
		local dir = minetest.facedir_to_dir(i)
		update_pane(vector.add(pos, dir))
	end
end)

minetest.register_on_dignode(function(pos)
	for i = 0, 3 do
		local dir = minetest.facedir_to_dir(i)
		update_pane(vector.add(pos, dir))
	end
end)
--]]

xpanes = {}
function xpanes.register_pane(name, def)
	for i = 1, 15 do
		minetest.register_alias("xpanes:" .. name .. "_" .. i, "xpanes:" .. name .. "_flat")
	end

	local on_construct = function(pos)
		update_pane(pos)
		for i = 0, 3 do
			local dir = minetest.facedir_to_dir(i)
			update_pane(vector.add(pos, dir))
		end
	end

	local after_destruct = function(pos)
		for i = 0, 3 do
			local dir = minetest.facedir_to_dir(i)
			update_pane(vector.add(pos, dir))
		end
	end

	local flatgroups = table.copy(def.groups or {})
	flatgroups.pane = 1
	minetest.register_node(":xpanes:" .. name .. "_flat", {
		description = def.description,
		drawtype = "nodebox",
		paramtype = "light",
		is_ground_content = false,
		sunlight_propagates = true,
		inventory_image = def.inventory_image,
		wield_image = def.wield_image,
		paramtype2 = "facedir",
		tiles = {def.textures[3], def.textures[3], def.textures[1]},
		groups = flatgroups,
		drop = "xpanes:" .. name .. "_flat",
		sounds = def.sounds,
		light_source = def.light_source,
		node_box = {
			type = "fixed",
			fixed = {{-1/2, -1/2, -1/32, 1/2, 1/2, 1/32}},
		},
		selection_box = {
			type = "fixed",
			fixed = {{-1/2, -1/2, -1/32, 1/2, 1/2, 1/32}},
		},
		connect_sides = { "left", "right" },

		on_construct = on_construct,
		after_destruct = after_destruct,
	})

	local groups = table.copy(def.groups or {})
	groups.pane = 1
	groups.not_in_creative_inventory = 1
	minetest.register_node(":xpanes:" .. name, {
		drawtype = "nodebox",
		paramtype = "light",
		is_ground_content = false,
		sunlight_propagates = true,
		description = def.description,
		tiles = {def.textures[3], def.textures[3], def.textures[1]},
		groups = groups,
		drop = "xpanes:" .. name .. "_flat",
		sounds = def.sounds,
		light_source = def.light_source,
		node_box = {
			type = "connected",
			fixed = {{-1/32, -1/2, -1/32, 1/32, 1/2, 1/32}},
			connect_front = {{-1/32, -1/2, -1/2, 1/32, 1/2, -1/32}},
			connect_left = {{-1/2, -1/2, -1/32, -1/32, 1/2, 1/32}},
			connect_back = {{-1/32, -1/2, 1/32, 1/32, 1/2, 1/2}},
			connect_right = {{1/32, -1/2, -1/32, 1/2, 1/2, 1/32}},
		},
		connects_to = {"group:pane", "group:stone", "group:glass", "group:brick", "group:wood", "group:tree"},

		on_construct = on_construct,
		after_destruct = after_destruct,
	})

	minetest.register_craft({
		output = "xpanes:" .. name .. "_flat " .. (def.amount or 16),
		recipe = def.recipe
	})
end

xpanes.register_pane("pane", {
	description = "Glass Pane",
	textures = {"default_glass.png","xpanes_pane_half.png","xpanes_white.png"},
	inventory_image = "default_glass.png",
	wield_image = "default_glass.png",
	sounds = default.node_sound_glass_defaults(),
	groups = utility.dig_groups("pane_glass"),
	recipe = {
		{"default:glass", "default:glass", "default:glass"},
		{"default:glass", "default:glass", "default:glass"}
	}
})
----[[
xpanes.register_pane("obsidian_glass", {
	description = "Obsidian Glass Pane",
	textures = {"default_obsidian_glass.png","xpanes_pane_half.png","xpanes_white.png"},
	inventory_image = "default_obsidian_glass.png",
	wield_image = "default_obsidian_glass.png",
	sounds = default.node_sound_glass_defaults(),
	groups = utility.dig_groups("pane_glass"),
	recipe = {
		{"default:obsidian_glass", "default:obsidian_glass", "default:obsidian_glass"},
		{"default:obsidian_glass", "default:obsidian_glass", "default:obsidian_glass"}
	}
})
--]]
xpanes.register_pane("bar", {
	description = "Iron Bars",
	textures = {"xpanes_bar.png","xpanes_bar.png","xpanes_bar_top.png"},
	inventory_image = "xpanes_bar.png",
	wield_image = "xpanes_bar.png",
	groups = utility.dig_groups("pane_metal"),
	sounds = default.node_sound_metal_defaults(),
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"}
	}
})

xpanes.register_pane("wood", {
	description = "Wood Pane",
	textures = {"doors_trapdoor.png", "xpanes_brown.png", "xpanes_brown.png"},
	inventory_image = "doors_trapdoor.png",
	wield_image = "doors_trapdoor.png",
	groups = utility.dig_groups("pane_wood"),
	sounds = default.node_sound_wood_defaults(),
	recipe = {
		{"default:wood", "default:wood"},
		{"default:wood", "default:wood"}
	}
})

xpanes.register_pane("iron", {
	description = "Wrought Iron Pane",
	textures = {"doors_trapdoor_iron.png", "xpanes_gray2.png", "xpanes_gray2.png"},
	inventory_image = "doors_trapdoor_iron.png",
	wield_image = "doors_trapdoor_iron.png",
	groups = utility.dig_groups("pane_metal"),
	sounds = default.node_sound_metal_defaults(),
	amount = 1,
	recipe = {
		{"default:iron_lump", "default:iron_lump", "default:iron_lump"},
	}
})

xpanes.register_pane("akalin", {
	description = "Akalin Glass Pane",
	textures = {"glooptest_akalin_crystal_glass.png", "xpanes_pane_half.png", "xpanes_white.png"},
	inventory_image = "glooptest_akalin_crystal_glass.png",
	wield_image = "glooptest_akalin_crystal_glass.png",
	sounds = default.node_sound_glass_defaults(),
	groups = utility.dig_groups("pane_glass"),
	recipe = {
		{"akalin:glass", "akalin:glass", "akalin:glass"},
		{"akalin:glass", "akalin:glass", "akalin:glass"}
	}
})

xpanes.register_pane("alatro", {
	description = "Alatro Glass Pane",
	textures = {"glooptest_alatro_crystal_glass.png", "xpanes_pane_half.png", "xpanes_white.png"},
	inventory_image = "glooptest_alatro_crystal_glass.png",
	wield_image = "glooptest_alatro_crystal_glass.png",
	sounds = default.node_sound_glass_defaults(),
	groups = utility.dig_groups("pane_glass"),
	recipe = {
		{"alatro:glass", "alatro:glass", "alatro:glass"},
		{"alatro:glass", "alatro:glass", "alatro:glass"}
	}
})

xpanes.register_pane("arol", {
	description = "Arol Glass Pane",
	textures = {"glooptest_arol_crystal_glass.png", "xpanes_pane_half.png", "xpanes_white.png"},
	inventory_image = "glooptest_arol_crystal_glass.png",
	wield_image = "glooptest_arol_crystal_glass.png",
	sounds = default.node_sound_glass_defaults(),
	groups = utility.dig_groups("pane_glass"),
	recipe = {
		{"arol:glass", "arol:glass", "arol:glass"},
		{"arol:glass", "arol:glass", "arol:glass"}
	}
})

xpanes.register_pane("talinite", {
	description = "Talinite Glass Pane",
	textures = {"glooptest_talinite_crystal_glass.png", "xpanes_pane_half.png", "xpanes_white.png"},
	inventory_image = "glooptest_talinite_crystal_glass.png",
	wield_image = "glooptest_talinite_crystal_glass.png",
	sounds = default.node_sound_glass_defaults(),
	groups = utility.dig_groups("pane_glass"),
	light_source = 10,
	recipe = {
		{"talinite:glass", "talinite:glass", "talinite:glass"},
		{"talinite:glass", "talinite:glass", "talinite:glass"}
	}
})

xpanes.register_pane("dk_glass", {
	description = "Clean Medieval Glass Pane",
	textures = {"darkage_glass.png", "xpanes_pane_half.png", "xpanes_white.png"},
	inventory_image = "darkage_glass.png",
	wield_image = "darkage_glass.png",
	sounds = default.node_sound_glass_defaults(),
	groups = utility.dig_groups("pane_glass"),
	recipe = {
		{"darkage:glass", "darkage:glass", "darkage:glass"},
		{"darkage:glass", "darkage:glass", "darkage:glass"}
	}
})

xpanes.register_pane("dk_mglass", {
	description = "Milky Medieval Glass Pane",
	textures = {"darkage_milk_glass.png", "xpanes_pane_half.png", "xpanes_white.png"},
	inventory_image = "darkage_milk_glass.png",
	wield_image = "darkage_milk_glass.png",
	sounds = default.node_sound_glass_defaults(),
	groups = utility.dig_groups("pane_glass"),
	recipe = {
		{"darkage:milk_glass", "darkage:milk_glass", "darkage:milk_glass"},
		{"darkage:milk_glass", "darkage:milk_glass", "darkage:milk_glass"}
	}
})

xpanes.register_pane("dk_woodframe", {
	description = "Wooden Framed Glass Pane",
	textures = {"darkage_wood_frame.png", "xpanes_pane_half.png", "xpanes_white.png"},
	inventory_image = "darkage_wood_frame.png",
	wield_image = "darkage_wood_frame.png",
	sounds = default.node_sound_glass_defaults(),
	groups = utility.dig_groups("pane_wood"),
	recipe = {
		{"darkage:wood_frame", "darkage:wood_frame", "darkage:wood_frame"},
		{"darkage:wood_frame", "darkage:wood_frame", "darkage:wood_frame"}
	}
})

xpanes.register_pane("dk_glass_round", {
	description = "Round Glass Pane",
	textures = {"darkage_glass_round.png", "xpanes_pane_half.png", "xpanes_white.png"},
	inventory_image = "darkage_glass_round.png",
	wield_image = "darkage_glass_round.png",
	sounds = default.node_sound_glass_defaults(),
	groups = utility.dig_groups("pane_glass"),
	recipe = {
		{"darkage:glass_round", "darkage:glass_round", "darkage:glass_round"},
		{"darkage:glass_round", "darkage:glass_round", "darkage:glass_round"}
	}
})

xpanes.register_pane("dk_mglass_round", {
	description = "Milky Medieval Round Glass Pane",
	textures = {"darkage_milk_glass_round.png", "xpanes_pane_half.png", "xpanes_white.png"},
	inventory_image = "darkage_milk_glass_round.png",
	wield_image = "darkage_milk_glass_round.png",
	sounds = default.node_sound_glass_defaults(),
	groups = utility.dig_groups("pane_glass"),
	recipe = {
		{"darkage:milk_glass_round", "darkage:milk_glass_round", "darkage:milk_glass_round"},
		{"darkage:milk_glass_round", "darkage:milk_glass_round", "darkage:milk_glass_round"}
	}
})

xpanes.register_pane("dk_glass_square", {
	description = "Square Glass Pane",
	textures = {"darkage_glass_square.png", "xpanes_pane_half.png", "xpanes_white.png"},
	inventory_image = "darkage_glass_square.png",
	wield_image = "darkage_glass_square.png",
	sounds = default.node_sound_glass_defaults(),
	groups = utility.dig_groups("pane_glass"),
	recipe = {
		{"darkage:glass_square", "darkage:glass_square", "darkage:glass_square"},
		{"darkage:glass_square", "darkage:glass_square", "darkage:glass_square"}
	}
})

xpanes.register_pane("dk_mglass_square", {
	description = "Milky Medieval Square Glass Pane",
	textures = {"darkage_milk_glass_square.png", "xpanes_pane_half.png", "xpanes_white.png"},
	inventory_image = "darkage_milk_glass_square.png",
	wield_image = "darkage_milk_glass_square.png",
	sounds = default.node_sound_glass_defaults(),
	groups = utility.dig_groups("pane_glass"),
	recipe = {
		{"darkage:milk_glass_square", "darkage:milk_glass_square", "darkage:milk_glass_square"},
		{"darkage:milk_glass_square", "darkage:milk_glass_square", "darkage:milk_glass_square"}
	}
})

