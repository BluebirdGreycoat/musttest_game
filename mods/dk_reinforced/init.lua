
local function make_new_groups(groups)
	local newgroups = --comment
	{
		level = groups.level or 1,
		snappy = groups.snappy or 0,
		choppy = groups.choppy or 0,
		cracky = groups.cracky or 0,
		crumbly = groups.crumbly or 0,
		flammable = groups.flammable or 0,
	}
	return newgroups
end

local register_reinforce = function(basename)
	local ndef = minetest.registered_nodes[basename]
	assert(type(ndef) == "table")

	-- Reinforced X.
	do
		local itemname = string.split(basename, ":")[2]
		local realname = "dk_reinforced:" .. itemname

		local reinforced = table.copy(ndef)
		reinforced.description = "Reinforced " .. ndef.description
		for i, tile in ipairs(reinforced.tiles) do
			reinforced.tiles[i] = tile .. "^darkage_reinforce.png"
		end

		-- Don't inherit groups from parent node.
		reinforced.groups = make_new_groups(reinforced.groups or {})

		minetest.register_node(realname, reinforced)

		minetest.register_craft({
			output = realname,
			recipe = {
				{"group:stick",	"", 			"group:stick"},
				{"",						basename,	""},
				{"group:stick",	"", 			"group:stick"},
			}
		})

		-- Recycling.
		minetest.register_craft({
			type = "shapeless",
			output = basename,
			recipe = {realname},
		})
	end

	-- Reinforced Window.
	do
		local itemname = string.split(basename, ":")[2]
		local realname = "dk_reinforced:" .. itemname .. "_cross"

		local reinforced = table.copy(ndef)
		reinforced.description = "Reinforced " .. ndef.description .. " Cross"
		for i, tile in ipairs(reinforced.tiles) do
			reinforced.tiles[i] = tile .. "^darkage_reinforce_window.png"
		end

		-- Don't inherit groups from parent node.
		reinforced.groups = make_new_groups(reinforced.groups or {})

		minetest.register_node(realname, reinforced)

		minetest.register_craft({
			output = realname,
			recipe = {
				{"",	"group:stick", 			""},
				{"group:stick",						basename,	"group:stick"},
				{"",	"group:stick", 			""},
			}
		})

		-- Recycling.
		minetest.register_craft({
			type = "shapeless",
			output = basename,
			recipe = {realname},
		})
	end

	-- Reinforced Slope.
	do
		local itemname = string.split(basename, ":")[2]
		local realname = "dk_reinforced:" .. itemname .. "_slope"

		local slope = table.copy(ndef)
		slope.description = "Reinforced " .. ndef.description .. " Slope"
		slope.paramtype2 = "facedir"

		-- Don't inherit groups from parent node.
		slope.groups = make_new_groups(slope.groups or {})

		local slope_tile_extend = {
			"^darkage_reinforce_right.png",
			"^darkage_reinforce_right.png",
			"^darkage_reinforce_right.png",
			"^darkage_reinforce_right.png",
			"^darkage_reinforce_left.png",
			"^darkage_reinforce_left.png",
		}
		for i = 1, 6 do
			local tile = slope.tiles[i] or ndef.tiles[1]
			slope.tiles[i] = tile .. slope_tile_extend[i]
		end 

		minetest.register_node(realname, slope)

		minetest.register_craft({
			output = realname,
			recipe = {
				{"group:stick", "", ""},
				{"", basename, ""},
				{"", "", "group:stick"},
			}
		})

		-- Recycling.
		minetest.register_craft({
			type = "shapeless",
			output = basename,
			recipe = {realname},
		})
	end

	-- Arrow bar.
	do
		local itemname = string.split(basename, ":")[2]
		local realname = "dk_reinforced:" .. itemname .. "_arrow"

		local arrow = table.copy(ndef)
		arrow.paramtype2 = "facedir"
		arrow.description = "Reinforced " .. ndef.description .. " Arrow"

		-- Don't inherit groups from parent node.
		arrow.groups = make_new_groups(arrow.groups or {})

		local arrow_tile_extend = {
			"^darkage_reinforce_bars.png",
			"^darkage_reinforce_bars.png",
			"^(darkage_reinforce_arrow.png^[transformR90)",
			"^(darkage_reinforce_arrow.png^[transformR270)",
			"^(darkage_reinforce_arrow.png^[transformR180)",
			"^darkage_reinforce_arrow.png",
		}
		for i = 1, 6 do
			local tile = arrow.tiles[i] or ndef.tiles[1]
			arrow.tiles[i] = tile .. arrow_tile_extend[i]
		end

		minetest.register_node(realname, arrow)

		minetest.register_craft({
			output = realname,
			recipe = {
				{"", "group:stick", ""},
				{"", basename, ""},
				{"group:stick", "", "group:stick"},
			}
		})

		-- Recycling
		minetest.register_craft({
			type = "shapeless",
			output = basename,
			recipe = {realname}
		})
	end

	-- Reinforced Bars.
	do
		local itemname = string.split(basename, ":")[2]
		local realname = "dk_reinforced:" .. itemname .. "_bars"

		local bars = table.copy(ndef)
		bars.description = "Reinforced " .. ndef.description .. " Bars"
		for i, tile in ipairs(bars.tiles) do
			bars.tiles[i] = tile .. "^darkage_reinforce_bars.png"
		end

		-- Don't inherit groups from parent node.
		bars.groups = make_new_groups(bars.groups or {})

		minetest.register_node(realname, bars)

		minetest.register_craft({
			output = realname,
			recipe = {
				{"group:stick", "", "group:stick"},
				{"group:stick", basename, "group:stick"},
				{"group:stick", "", "group:stick"},
			}
		})

		-- Recycling
		minetest.register_craft({
			type = "shapeless",
			output = basename,
			recipe = {realname}
		})
	end
end


register_reinforce("basictrees:tree_wood")
register_reinforce("basictrees:jungletree_wood")
register_reinforce("basictrees:aspen_wood")
register_reinforce("basictrees:pine_wood")

register_reinforce("firetree:whitewood")
register_reinforce("firetree:firewood")
register_reinforce("jungletree:jungletree_wood")

register_reinforce("moretrees:cedar_wood")
register_reinforce("moretrees:apple_tree_wood")
register_reinforce("moretrees:fir_wood")
register_reinforce("moretrees:oak_wood")
register_reinforce("moretrees:spruce_wood")
register_reinforce("moretrees:palm_wood")
register_reinforce("moretrees:rubber_tree_wood")
register_reinforce("moretrees:poplar_wood")
register_reinforce("moretrees:beech_wood")
register_reinforce("moretrees:sequoia_wood")
register_reinforce("moretrees:willow_wood")
register_reinforce("moretrees:date_palm_wood")
register_reinforce("moretrees:jungletree_wood")
register_reinforce("moretrees:birch_wood")

register_reinforce("darkage:chalk")
register_reinforce("darkage:chalked_bricks")

register_reinforce("default:clay")
register_reinforce("default:sandstone")
register_reinforce("moreblocks:tar")

register_reinforce("glowstone:glowstone")
register_reinforce("glowstone:minerals")
register_reinforce("luxore:luxore")
register_reinforce("glowstone:cobble")

