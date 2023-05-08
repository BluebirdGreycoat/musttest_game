
minetest.register_node("griefer:grieferstone", {
	description = "Oerkki Stone",
	tiles = {
		"griefer_stonetop.png",
		"griefer_stonetop.png",
		"griefer_stoneside.png",
	},
	sounds = default.node_sound_stone_defaults(),
	groups = utility.dig_groups("obsidian"),
	drop = "default:goldblock",
	silverpick_drop = true,
	--[[
	on_construct = function(...)
		return griefer.on_stone_construct(...)
	end,
	on_timer = function(...)
		return griefer.on_stone_timer(...)
	end,
	--]]

	on_destruct = function(pos)
		obsidian_gateway.on_damage_gate(pos)
  end,

	after_destruct = function(pos)
		minetest.after(0, ambiance.recheck_nearby_sound_beacons, {x=pos.x, y=pos.y, z=pos.z}, 16)
		jail.notify_jail_destruct(pos)
	end,

	on_collapse_to_entity = function(pos, node)
		minetest.add_item(pos, {name="default:goldblock"})
	end,
})



minetest.register_craft({
	output = 'griefer:grieferstone',
	recipe = {
		{'default:obsidian', 'default:obsidian', 'default:obsidian'},
		{'default:obsidian', 'default:goldblock', 'default:obsidian'},
		{'default:obsidian', 'default:obsidian', 'default:obsidian'},
	}
})



minetest.register_alias("mobs_monster:oerkki_stone", "griefer:grieferstone")



-- Spawner for Naraxen Oerkkis. Not to be obtainable, system use only.
minetest.register_node("griefer:naraxen", {
	description = "Oerkki Stone",
	tiles = {
		"griefer_stonetop.png",
		"griefer_stonetop.png",
		"griefer_stoneside.png",
	},
	sounds = default.node_sound_stone_defaults(),
	groups = utility.dig_groups("obsidian"),
	drop = "default:goldblock",
	silverpick_drop = "griefer:grieferstone",

  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="griefer:grieferstone"})
  end,

	on_collapse_to_entity = function(pos, node)
		minetest.add_item(pos, {name="default:goldblock"})
	end,
})
