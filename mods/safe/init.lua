
if not minetest.global_exists("safe") then safe = {} end
safe.modpath = minetest.get_modpath("safe")

-- This color name apparently offends some woke cupcake somewhere in the world.
-- The W3C recommends partly for this reason that color names NOT be used.
-- Therefore, today is a good day to use an "offensive" color name, and offend
-- some woke cupcake somewhere in the world. CUPCAKE!
safe.MESSAGE_COLOR = minetest.get_color_escape_sequence("indianred")

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

-- Info for node registration.
safe.safe_nodes = {
	["safe:box"] = {
		desc = "Safety Deposit Box",
		tiles = CLOSE_SAFE_TILES,
		drop = "safe:box",
		groups = utility.dig_groups("machine", {immovable=1}),
		sounds = default.node_sound_metal_defaults(),
		open_node = "safe:box_open",
		close_node = "safe:box",
		common_name = "Safe",
	},
	["safe:box_open"] = {
		desc = "Safety Deposit Box",
		tiles = OPEN_SAFE_TILES,
		drop = "safe:box",
		groups = utility.dig_groups("machine", {immovable=1}),
		sounds = default.node_sound_metal_defaults(),
		open_node = "safe:box_open",
		close_node = "safe:box",
		common_name = "Safe",
	},
}

dofile(safe.modpath .. "/safe.lua")

if not safe.registered then
	for name, infotocopy in pairs(safe.safe_nodes) do
		-- Copy the data so we can safely modify it as needed.
		local info = table.copy(infotocopy)

		minetest.register_node(name, {
			description = info.desc,
			tiles = info.tiles,

			paramtype2 = "facedir",
			groups = info.groups,
			drop = info.drop,
			sounds = info.sounds,
			stack_max = 1,

			_safe_common_name = info.common_name,
			_safe_open_node = info.open_node,
			_safe_close_node = info.close_node,

			on_rotate = function(...) return screwdriver.rotate_simple(...) end,
			on_construct = function(...) return safe.on_construct(...) end,
			on_destruct = function(...) return safe.on_destruct(...) end,
			on_blast = function(...) return safe.on_blast(...) end,
			on_rightclick = function(...) return safe.on_rightclick(...) end,
			after_place_node = function(...) return safe.after_place_node(...) end,
			on_punch = function(...) return safe.on_punch(...) end,
			can_dig = function(...) return safe.can_dig(...) end,
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
