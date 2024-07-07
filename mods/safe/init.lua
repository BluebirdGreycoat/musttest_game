
if not minetest.global_exists("safe") then safe = {} end
safe.modpath = minetest.get_modpath("safe")

-- Max interaction distance.
safe.INTERACTION_DISTANCE = 10

-- This color name apparently offends some woke cupcake somewhere in the world.
-- The W3C recommends partly for this reason that color names NOT be used.
-- Therefore, today is a good day to use an "offensive" color name, and offend
-- some woke cupcake somewhere in the world. CUPCAKE!
safe.MESSAGE_COLOR = minetest.get_color_escape_sequence("indianred")

local function pixel_box(x1, y1, z1, x2, y2, z2)
	return {
		x1 / 16 - 0.5,
		y1 / 16 - 0.5,
		z1 / 16 - 0.5,
		x2 / 16 - 0.5,
		y2 / 16 - 0.5,
		z2 / 16 - 0.5,
	}
end

local BRIEFCASE_CLOSED = {
	type = "fixed",
	fixed = {
		pixel_box(2, 0, 3, 14, 3, 13),
		pixel_box(6.5, 1.5, 2.5, 9.5, 2, 3),
	},
}

local BRIEFCASE_OPENED = {
	type = "fixed",
	fixed = {
		pixel_box(2, 0, 3, 14, 1.5, 13),
		pixel_box(2, 1, 12.5, 14, 11, 14),
		pixel_box(6.5, 11, 12.5, 9.5, 11.5, 13),
	},
}

local CLOSE_SAFE_TILES = {
	"safe_side.png",
	"safe_side.png",
	"safe_side.png",
	"safe_side.png",
	"safe_side.png",
	"safe_front.png",
}

local OPEN_SAFE_TILES = {
	"safe_side.png",
	"safe_side.png",
	"safe_side.png",
	"safe_side.png",
	"safe_side.png",
	"safe_front_open.png",
}

local CLOSE_BRIEFCASE_TILES = {
	"safe_briefcase_top.png",
	"safe_briefcase_bottom.png",
	"safe_briefcase_side.png",
	"safe_briefcase_side.png^[transformFX",
	"safe_briefcase_back.png",
	"safe_briefcase_front.png",
}

local OPEN_BRIEFCASE_TILES = {
	"safe_briefcase_top_open.png",
	"safe_briefcase_bottom_open.png",
	"safe_briefcase_side_open.png",
	"safe_briefcase_side_open.png^[transformFX",
	"safe_briefcase_back_open.png",
	"safe_briefcase_front_open.png",
}

function safe.briefcase_allow_item(name)
	if name:find("^memorandum:") then
		return true
	end
	if name == "default:paper" then
		return true
	end
	if minetest.get_item_group(name, "book") ~= 0 then
		return true
	end
	if minetest.get_item_group(name, "vessel") ~= 0 then
		return true
	end
	if minetest.get_item_group(name, "key") ~= 0 then
		return true
	end
end

-- Thunk to allow function to be replaced on reload.
local function BRIEFCASE_ALLOW_ITEM(name)
	return safe.briefcase_allow_item(name)
end

-- Info for node registration.
safe.safe_nodes = {
	["safe:box"] = {
		drawtype = "normal",
		desc = "Safety Deposit Box",
		tiles = CLOSE_SAFE_TILES,
		drop = "safe:box",
		groups = utility.dig_groups("machine", {immovable=1}),
		sounds = default.node_sound_metal_defaults(),
		open_node = "safe:box_open",
		close_node = "safe:box",
		common_name = "Safe",
		allow_dig = false,
		allow_item = function() return true end,
		inventory_w = 8,
		inventory_h = 4,

		-- 32 is an offensive number. The use of 32 erases my culture! I demand that
		-- 32 not be used by anyone. 32 is white, patriarchal oppression. LOL.
		inventory_size = 32,
		is_blastable = false,
	},
	["safe:box_open"] = {
		drawtype = "normal",
		desc = "Safety Deposit Box",
		tiles = OPEN_SAFE_TILES,
		drop = "safe:box",
		groups = utility.dig_groups("machine", {immovable=1}),
		sounds = default.node_sound_metal_defaults(),
		open_node = "safe:box_open",
		close_node = "safe:box",
		common_name = "Safe",
		allow_dig = false,
		allow_item = function() return true end,
		inventory_w = 8,
		inventory_h = 4,
		inventory_size = 32,
		is_blastable = false,
	},
	["safe:briefcase"] = {
		drawtype = "nodebox",
		desc = "Briefcase",
		tiles = CLOSE_BRIEFCASE_TILES,
		drop = "safe:briefcase",
		groups = utility.dig_groups("bigitem", {attached_node=3}),
		sounds = default.node_sound_wood_defaults(),
		open_node = "safe:briefcase_open",
		close_node = "safe:briefcase",
		common_name = "Briefcase",
		collision_box = BRIEFCASE_CLOSED,
		selection_box = BRIEFCASE_CLOSED,
		allow_dig = true,
		allow_item = BRIEFCASE_ALLOW_ITEM,
		inventory_w = 8,
		inventory_h = 2,
		inventory_size = 16,
		is_blastable = true,
		wield_image = "safe_briefcase_inv.png^[transformR270",
		inventory_image = "safe_briefcase_inv.png",
	},
	["safe:briefcase_open"] = {
		drawtype = "nodebox",
		desc = "Briefcase",
		tiles = OPEN_BRIEFCASE_TILES,
		drop = "safe:briefcase",
		groups = utility.dig_groups("bigitem", {attached_node=3}),
		sounds = default.node_sound_wood_defaults(),
		open_node = "safe:briefcase_open",
		close_node = "safe:briefcase",
		common_name = "Briefcase",
		collision_box = BRIEFCASE_OPENED,
		selection_box = BRIEFCASE_OPENED,
		allow_dig = true,
		allow_item = BRIEFCASE_ALLOW_ITEM,
		inventory_w = 8,
		inventory_h = 2,
		inventory_size = 16,
		is_blastable = true,
		wield_image = "safe_briefcase_inv.png^[transformR270",
		inventory_image = "safe_briefcase_inv.png",
	},
}

dofile(safe.modpath .. "/safe.lua")

if not safe.registered then
	for name, infotocopy in pairs(safe.safe_nodes) do
		-- Copy the data so we can safely modify it as needed.
		local info = table.copy(infotocopy)

		minetest.register_node(name, {
			drawtype = info.drawtype,
			description = info.desc,
			tiles = info.tiles,
			wield_image = info.wield_image,
			inventory_image = info.inventory_image,

			paramtype2 = "facedir",
			groups = info.groups,
			drop = info.drop,
			sounds = info.sounds,
			stack_max = 1,

			node_box = info.collision_box,
			collision_box = info.collision_box,
			selection_box = info.selection_box,

			_safe_common_name = info.common_name,
			_safe_open_node = info.open_node,
			_safe_close_node = info.close_node,
			_safe_allow_dig = info.allow_dig,
			_safe_allow_item = info.allow_item,
			_safe_is_known_node = true,
			_safe_inventory_size = info.inventory_size,
			_safe_inventory_w = info.inventory_w,
			_safe_inventory_h = info.inventory_h,
			_safe_is_blastable = info.is_blastable,

			on_rotate = function(...) return screwdriver.rotate_simple(...) end,
			on_construct = function(...) return safe.on_construct(...) end,
			on_destruct = function(...) return safe.on_destruct(...) end,
			on_blast = function(...) return safe.on_blast(...) end,
			on_rightclick = function(...) return safe.on_rightclick(...) end,
			after_place_node = function(...) return safe.after_place_node(...) end,
			on_punch = function(...) return safe.on_punch(...) end,
			can_dig = function(...) return safe.can_dig(...) end,
			preserve_metadata = function(...) return safe.preserve_metadata(...) end,
			_on_update_infotext = function(...) return safe.update_infotext(...) end,
		})
	end

	minetest.register_craft({
		output = "safe:box",
		recipe = {
			{'carbon_steel:block', 'default:padlock', 'carbon_steel:block'},
			{'carbon_steel:block', 'morechests:ironchest_locked_closed', 'carbon_steel:block'},
			{'carbon_steel:block', 'techcrafts:control_logic_unit', 'carbon_steel:block'},
		},
	})

	minetest.register_craft({
		output = "safe:briefcase",
		recipe = {
			{'', 'default:padlock', ''},
			{'group:leather', 'chests:chest_locked_closed', 'group:leather'},
			{'dye:black', 'techcrafts:control_logic_unit', 'dye:black'},
		},
	})

	minetest.register_on_player_receive_fields(function(...)
		return safe.on_player_receive_fields(...)
	end)

	minetest.register_on_leaveplayer(function(...)
		return safe.on_leaveplayer(...)
	end)

	local c = "safe:core"
	local f = safe.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	safe.registered = true
end
