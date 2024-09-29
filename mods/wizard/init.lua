
if not minetest.global_exists("wizard") then wizard = {} end
wizard.modpath = minetest.get_modpath("wizard")

dofile(wizard.modpath .. "/node.lua")
dofile(wizard.modpath .. "/banish.lua")
dofile(wizard.modpath .. "/track.lua")
dofile(wizard.modpath .. "/gag.lua")
dofile(wizard.modpath .. "/punish.lua")
dofile(wizard.modpath .. "/summon.lua")

function wizard.damage_player(pname, amount)
	minetest.after(0, function()
		local pref = minetest.get_player_by_name(pname)
		if pref and pref:get_hp() > 0 then
			utility.damage_player(pref, "electrocute", amount * 500)
		end
	end)
end

function wizard.runeslab_particles(pos)
	local image = "nether_particle_anim3.png"
	local color = "dark_grey"
	local d = 0.5
	minetest.add_particlespawner({
		amount = 5,
		time = 1.1,
		minpos = {x=pos.x-d, y=pos.y-d, z=pos.z-d},
		maxpos = {x=pos.x+d, y=pos.y+d, z=pos.z+d},
		minvel = {x=0, y=-d, z=0},
		maxvel = {x=0, y=d, z=0},
		minacc = {x=0, y=0, z=0},
		maxacc = {x=0, y=0, z=0},
		minexptime = 1.5,
		maxexptime = 2.5,
		minsize = 1,
		maxsize = 1.5,
		collisiondetection = true,
		collision_removal = true,
		texture = image .. "^[colorize:" .. color .. ":alpha",
		vertical = false,

		animation = {
			type = "vertical_frames",
			aspect_w = 7,
			aspect_h = 7,

			-- Disabled for now due to causing older clients to hang.
			--length = -1,
			length = 1.0,
		},

		glow = 14,
	})
end

if not wizard.registered then
	wizard.registered = true

	minetest.register_node("wizard:stone", {
		description = "Wizard Stone (You Hacker)",
		tiles = {"default_obsidian.png"},
		on_rotate = function(...) return wizard.on_rotate(...) end,

		groups = utility.dig_groups("obsidian", {stone=1, immovable=1}),
		drop = "",
		sounds = default.node_sound_stone_defaults(),
		crushing_damage = 20*500,
		node_dig_prediction = "",

		on_construct = function(...) return wizard.on_construct(...) end,
		on_destruct = function(...) return wizard.on_destruct(...) end,
		on_blast = function(...) return wizard.on_blast(...) end,
		on_collapse_to_entity = function(...) return wizard.on_collapse_to_entity(...) end,
		on_finish_collapse = function(...) return wizard.on_finish_collapse(...) end,
		on_rightclick = function(...) return wizard.on_rightclick(...) end,
		allow_metadata_inventory_move = function(...) return wizard.allow_metadata_inventory_move(...) end,
		allow_metadata_inventory_put = function(...) return wizard.allow_metadata_inventory_put(...) end,
		allow_metadata_inventory_take = function(...) return wizard.allow_metadata_inventory_take(...) end,
		on_metadata_inventory_move = function(...) return wizard.on_metadata_inventory_move(...) end,
		on_metadata_inventory_put = function(...) return wizard.on_metadata_inventory_put(...) end,
		on_metadata_inventory_take = function(...) return wizard.on_metadata_inventory_take(...) end,
		after_place_node = function(...) return wizard.after_place_node(...) end,
		on_punch = function(...) return wizard.on_punch(...) end,
		on_timer = function(...) return wizard.on_timer(...) end,
		can_dig = function(...) return wizard.can_dig(...) end,
		_on_update_infotext = function(...) return wizard.update_infotext(...) end,
		_on_update_formspec = function(...) return wizard.update_formspec(...) end,
		_on_update_entity = function(...) return wizard.update_entity(...) end,
		_on_pre_fall = function(...) return wizard.on_pre_fall(...) end,
	})

	dofile(wizard.modpath .. "/staffs.lua")

	-- Register mod reloadable.
	local c = "wizard:core"
	local f = wizard.modpath .. "/init.lua"
	reload.register_file(c, f, false)
end
