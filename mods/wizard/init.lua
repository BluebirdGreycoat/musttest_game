
if not minetest.global_exists("wizard") then wizard = {} end
wizard.modpath = minetest.get_modpath("wizard")



function wizard.on_construct(pos)
end



function wizard.on_destruct(pos)
end



function wizard.on_pre_fall(pos)
end



function wizard.on_blast(pos)
end



function wizard.on_collapse_to_entity(pos, node)
end



function wizard.on_finish_collapse(pos, node)
end



function wizard.on_rightclick(pos, node, user, itemstack, pt)
end



function wizard.allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, user)
end



function wizard.on_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, user)
end



function wizard.allow_metadata_inventory_put(pos, listname, index, stack, user)
end



function wizard.on_metadata_inventory_put(pos, listname, index, stack, user)
end



function wizard.allow_metadata_inventory_take(pos, listname, index, stack, user)
end



function wizard.on_metadata_inventory_take(pos, listname, index, stack, user)
end



function wizard.after_place_node(pos, user, itemstack, pt)
end



function wizard.on_punch(pos, node, user, pt)
end



function wizard.on_timer(pos, elapsed)
end



function wizard.can_dig(pos, user)
end



function wizard.on_rotate(pos, node, user, mode, new_param2)
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

	-- Register mod reloadable.
	local c = "wizard:core"
	local f = wizard.modpath .. "/init.lua"
	reload.register_file(c, f, false)
end
