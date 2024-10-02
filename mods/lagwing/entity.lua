
local entity = {
	initial_properties = {
		visual = "mesh",
		mesh = "lagwing_main.b3d",
		visual_size = {x=1, y=1},
		collisionbox = {-1, -1, -1, 1, 1, 1},
		physical = true,
		textures = {"lagwing_main.png"},
		is_visible = true,
		static_save = true,
	},

	on_activate = function(...)
		return lagwing.on_activate(...)
	end,

	on_deactivate = function(...)
		return lagwing.on_deactivate(...)
	end,

	on_punch = function(...)
		return lagwing.on_punch(...)
	end,

	on_death = function(...)
		return lagwing.on_death(...)
	end,

	on_rightclick = function(...)
		return lagwing.on_rightclick(...)
	end,

	get_staticdata = function(...)
		return lagwing.get_staticdata(...)
	end,

	on_blast = function(...)
		return lagwing.on_blast(...)
	end,

	on_step = function(...)
		return lagwing.on_step(...)
	end,

	on_attach_child = function(...)
		return lagwing.on_attach_child(...)
	end,

	on_detach_child = function(...)
		return lagwing.on_detach_child(...)
	end,

	on_detach = function(...)
		return lagwing.on_detach(...)
	end,
}

minetest.register_entity("lagwing:entity", entity)
