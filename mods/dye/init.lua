-- Other mods can use these for looping through available colors

dye = {}

-- Note: there is another color list in the "bakedclay" mod which must be same
-- as this. Also in the "wool" mod.
local dyes = {
	{"white",      "White Dye",      {dye=1}},
	{"grey",       "Grey Dye",       {dye=1}},
	{"dark_grey",  "Dark Grey Dye",  {dye=1}},
	{"black",      "Black Dye",      {dye=1}},
	{"violet",     "Violet Dye",     {dye=1}},
	{"blue",       "Blue Dye",       {dye=1}},
	{"cyan",       "Cyan Dye",       {dye=1}},
	{"dark_green", "Dark Green Dye", {dye=1}},
	{"green",      "Green Dye",      {dye=1}},
	{"yellow",     "Yellow Dye",     {dye=1}},
	{"brown",      "Brown Dye",      {dye=1}},
	{"orange",     "Orange Dye",     {dye=1}},
	{"red",        "Red Dye",        {dye=1}},
	{"magenta",    "Magenta Dye",    {dye=1}},
	{"pink",       "Pink Dye",       {dye=1}},
}

-- Define items.
for _, row in ipairs(dyes) do
	local name = row[1]
	local description = row[2]
	local groups = row[3]

	local item_name = "dye:" .. name
	local item_image = "dye_" .. name .. ".png"

	minetest.register_craftitem(item_name, {
		inventory_image = item_image,
		description = description,
		groups = groups,
	})

	minetest.register_craft({
		type = "shapeless",
		output = item_name .. " 1",
		recipe = {"group:flower,color_" .. name, "farming:mortar_pestle"},
		replacements = {{"farming:mortar_pestle", "farming:mortar_pestle"}},
	})
end

-- Manually add coal --> black dye.
minetest.register_craft({
  type = "shapeless",
  output = "dye:black",
  recipe = {"default:coal_lump", "default:clay_lump", "farming:mortar_pestle"},
	replacements = {{"farming:mortar_pestle", "farming:mortar_pestle"}},
})
  
-- Mix recipes. Table params: color1, color2, result.
local dye_recipes = {
	-- Basic RYB mixes.
	{"red",     "blue",       "violet"    },
	{"yellow",  "red",        "orange"    },
	{"yellow",  "blue",       "green"     },

	-- RYB complementary mixes.
	{"yellow",  "violet",     "dark_grey" },
	{"blue",    "orange",     "dark_grey" },

	-- CMY mixes - approximation.
	{"cyan",    "yellow",     "green"     },
	{"cyan",    "magenta",    "blue"      },
	{"yellow",  "magenta",    "red"       },

	-- Other mixes that result in a color we have.
	{"red",     "green",      "brown"     },
	{"magenta", "blue",       "violet"    },
	{"green",   "blue",       "cyan"      },
	{"pink",    "violet",     "magenta"   },

	-- Mixes with black.
	{"white",   "black",      "grey"      },
	{"grey",    "black",      "dark_grey" },
	{"green",   "black",      "dark_green"},
	{"orange",  "black",      "brown"     },

	-- Mixes with white.
	{"white",   "red",        "pink"      },
	{"white",   "dark_grey",  "grey"      },
	{"white",   "dark_green", "green"     },
}

for _, mix in ipairs(dye_recipes) do
	minetest.register_craft({
		type = "shapeless",
		output = 'dye:' .. mix[3] .. ' 2',
		recipe = {'dye:' .. mix[1], 'dye:' .. mix[2]},
	})
end
