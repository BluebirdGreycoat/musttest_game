
minetest.register_node("griefer:grieferstone", {
	description = "Oerkki Stone\n\nSummons the Oerkki from darkness into light.\nAn important component of gateway portals.",
	tiles = {
		"griefer_stonetop.png",
		"griefer_stonetop.png",
		"griefer_stoneside.png",
	},
	sounds = default.node_sound_stone_defaults(),
	groups = {
    cracky = 1, level = 3,

		-- Doesn't need to be immovable, nothing special about this block.
    --immovable = 1,
  },
	drop = "default:goldblock",
	--[[
	on_construct = function(...)
		return griefer.on_stone_construct(...)
	end,
	on_timer = function(...)
		return griefer.on_stone_timer(...)
	end,
	--]]
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
