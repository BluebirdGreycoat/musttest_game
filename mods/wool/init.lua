
-- No tricks! It confuses the craft guide (and me, too).
-- This list must match the one in the "dye" mod.
local dyes = {
	{"white",      "White"     },
	{"grey",       "Grey"      },
	{"black",      "Black"     },
	{"red",        "Red"       },
	{"yellow",     "Yellow"    },
	{"green",      "Green"     },
	{"cyan",       "Cyan"      },
	{"blue",       "Blue"      },
	{"magenta",    "Magenta"   },
	{"orange",     "Orange"    },
	{"violet",     "Violet"    },
	{"brown",      "Brown"     },
	{"pink",       "Pink"      },
	{"dark_grey",  "Dark Grey" },
	{"dark_green", "Dark Green"},
}

for i = 1, #dyes, 1 do
	local name, desc = unpack(dyes[i])

	minetest.register_node("wool:" .. name, {
		description = desc .. " Wool",
		tiles = {"wool_" .. name .. ".png"},
		is_ground_content = false,
		groups = utility.dig_groups("wool", {
      flammable = 3, wool = 1,
      wool_block = 1,
			fall_damage_add_percent = -30,
    }),
		sounds = default.node_sound_defaults(),
	})

	minetest.register_craft{
		type = "shapeless",
		output = "wool:" .. name,
		recipe = {"dye:" .. name, "group:wool_block"},
	}
end

-- Backwards compatibility with jordach's 16-color wool mod
minetest.register_alias("wool:dark_blue", "wool:blue")
minetest.register_alias("wool:gold", "wool:yellow")
