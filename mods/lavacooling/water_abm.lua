
-- List of realms the stone-to-mossy ABM may run in.
-- Hot nether/hell realms, and cold ones (overworld) excluded.
local REALM_LIST = {
	"channelwood",
	"jarkati",
	"midfeld",
	"waterworld",
	"ariba",
}

local DEFAULT_STONES = {
	"default:stone",
	"default:cobble",
	"default:stonebrick",
}

local MOSSY_VARIANTS = {
	"default:mossycobble",
	"default:mossystone",
	"default:mossy_stonebrick",
}

local STONE_TO_MOSSY_VARIANTS = {
	["default:cobble"] = "default:mossycobble",
	["default:stone"] = "default:mossystone",
	["default:stonebrick"] = "default:mossy_stonebrick",
}

local WATER_SOURCES = {
	"default:water_source",
	"default:water_flowing",
	"default:river_water_source",
	"default:river_water_flowing",
	"cw:water_source",
	"cw:water_flowing",
}

local LAVA_SOURCES = {
	"default:lava_source",
	"default:lava_flowing",
	"lbrim:lava_source",
	"lbrim:lava_flowing",
}

local function water_abm(pos, node)
	local altnode = STONE_TO_MOSSY_VARIANTS[node.name]
	if not altnode then return end

	-- Moss growth accelerates if there is already mossy nearby.
	if minetest.find_node_near(pos, 1, MOSSY_VARIANTS) or
			math.random(1, 20) == 1 then
		minetest.set_node(pos, {name=altnode, param2=node.param2})
	end
end

for _, realm in ipairs(REALM_LIST) do
	minetest.register_abm({
		label = "Water Turn Stone To Mossy",
		nodenames = DEFAULT_STONES,
		neighbors = WATER_SOURCES,
		without_neighbors = LAVA_SOURCES,
		interval = 5,
		chance = 512,
		catch_up = false,
		action = water_abm,
		min_y = rc.get_realm_data(realm).minp.y,
		max_y = rc.get_realm_data(realm).maxp.y,
	})
end
