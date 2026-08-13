
if not minetest.global_exists("falling") then falling = {} end
falling.modpath = minetest.get_modpath("falling")
reload.install_simple_signals(falling)

-- Core reloadable logic.
dofile(falling.modpath .. "/functions.lua")
dofile(falling.modpath .. "/entity.lua")
dofile(falling.modpath .. "/react.lua")

if not falling.run_once then
	minetest.register_entity(":__builtin:falling_node", {
		initial_properties = {
			visual = "wielditem",
			visual_size = {x = 0.667, y = 0.667},
			textures = {},
			physical = true,
			is_visible = false,
			collide_with_objects = false,
			collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		},

		node = {},
		meta = {},

		set_node = function(self, node, meta)
			falling.set_node(self, node, meta)
		end,

		get_staticdata = function(self)
			return falling.get_staticdata(self)
		end,

		on_activate = function(self, staticdata)
			falling.on_activate(self, staticdata)
		end,

		on_step = function(self, dtime, moveresult)
			falling.on_step(self, dtime, moveresult)
		end,
	})

	local c = "falling:core"
	local f = falling.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	falling.run_once = true
end
