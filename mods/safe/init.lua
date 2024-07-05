
if not minetest.global_exists("safe") then safe = {} end
safe.modpath = minetest.get_modpath("safe")

dofile(safe.modpath .. "/safe.lua")

if not safe.registered then
	for name, info in pairs({
		["safe:box"] = {front_tex="safe_front.png"},
		["safe:box_open"] = {front_tex="safe_front_open.png"},
	}) do
		minetest.register_node(name, {
			description = "Safety Deposit Box",
			tiles = {
				"safe_side.png",
				"safe_side.png",
				"safe_side.png",
				"safe_side.png",
				"safe_side.png",
				info.front_tex,
			},

			paramtype2 = "facedir",
			groups = utility.dig_groups("machine", {immovable=1}),
			drop = "safe:box",
			sounds = default.node_sound_metal_defaults(),
			stack_max = 1,

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
