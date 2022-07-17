
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
	after_destruct = function(pos)
		minetest.after(0, ambiance.recheck_nearby_sound_beacons, {x=pos.x, y=pos.y, z=pos.z}, 16)
		obsidian_gateway.after_damage_gate(pos)
		jail.notify_jail_destruct(pos)
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
