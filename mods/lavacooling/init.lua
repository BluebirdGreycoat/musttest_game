
lavacooling = lavacooling or {}
lavacooling.modpath = minetest.get_modpath("lavacooling")

local fire_node = 						{name="fire:basic_flame"}
local obsidian_node = 				{name="default:obsidian"}
local cobble_node = 					{name="default:cobble"}
local dead_obsidian_node = 		{name="cavestuff:dark_obsidian"}
local rockmelt_node = 				{name="cavestuff:cobble_with_rockmelt"}
local air_node = 							{name="air"}
local basalt_node =						{name="gloopblocks:basalt"}
local basaltic_node =					{name="darkage:basaltic_rubble"}
local pumice_node =						{name="gloopblocks:pumice"}

local find = string.find
local findn = minetest.find_node_near
local random = math.random
local setn = minetest.add_node
local getn = minetest.get_node
local play = minetest.sound_play

local allnodes = minetest.registered_nodes

-- Nodename groups.
local lava_sources = {"default:lava_source", "lbrim:lava_source"}
local flowing_lava = {"default:lava_flowing", "lbrim:lava_flowing"}
local water_sources = {"default:water_source", "default:river_water_source", "cw:water_source"}
local flowing_water = {"default:water_flowing", "default:river_water_flowing", "cw:water_flowing"}
local water_group = {
	"default:water_source",
	"default:water_flowing",
	"default:river_water_source",
	"default:river_water_flowing",
	"cw:water_source",
	"cw:water_flowing",
}
local lava_group = {
	"default:lava_source",
	"default:lava_flowing",
	"lbrim:lava_source",
	"lbrim:lava_flowing",
}
local melt_group = "group:melts"
local flammable_group = "group:flammable"

-- Melt stuff around lava.
local function do_lava_melting(pos, node)
	ambiance.sound_play("lava", pos, 1.0, 32)
	local mpos = findn(pos, 1, melt_group)
	if mpos then
		local def = allnodes[getn(mpos).name] or {}
		if def._melts_to then
			setn(mpos, {name=def._melts_to})
			if math.random(1, 10) == 1 then
				sfn.drop_node(mpos)
			end
		elseif def.on_melt then
			def.on_melt(mpos, pos)
		else
			setn(mpos, rockmelt_node)
			-- Rockmelt has special falling code, so only trigger a fall if it actually could fall.
			if minetest.get_node({x=mpos.x, y=mpos.y-1, z=mpos.z}).name == "air" then
				sfn.drop_node(mpos)
			end
		end
	end
end

-- Remove flammable nodes around lava.
local function do_lava_flammables(pos, node)
	-- Consume anything flammable.
	local fpos = findn(pos, 1, flammable_group)
	if fpos then
		setn(fpos, fire_node)
	end
end

-- Cool lava sources to regular obsidian.
local function do_lavasource_cooling(pos, node)
	setn(pos, obsidian_node)
	if math.random(1, 10) == 1 then
		sfn.drop_node(pos)
	end

	play("default_cool_lava", {pos=pos, max_hear_distance=16, gain=0.25})

	-- Add flames above cooled lava.
	pos.y = pos.y + 1
	if getn(pos).name == "air" then
		setn(pos, fire_node)
	end
end

-- Flowing lava + flowing water = pumice.
local function do_flowinglava_flowingwater_cooling(pos, node)
	setn(pos, pumice_node)
	if math.random(1, 10) == 1 then
		sfn.drop_node(pos)
	end

	play("default_cool_lava", {pos=pos, max_hear_distance=16, gain=0.25})

	-- Add flames above cooled lava.
	pos.y = pos.y + 1
	if getn(pos).name == "air" then
		setn(pos, fire_node)
	end
end

-- Flowing lava + water source = basalt.
local function do_flowinglava_watersource_cooling(pos, node)
	setn(pos, basalt_node)
	if math.random(1, 10) == 1 then
		sfn.drop_node(pos)
	end

	play("default_cool_lava", {pos=pos, max_hear_distance=16, gain=0.25})

	-- Add flames above cooled lava.
	pos.y = pos.y + 1
	if getn(pos).name == "air" then
		setn(pos, fire_node)
	end
end

-- Cool rockmelt to basalt rubble.
local function do_rockmelt_cooling(pos, node)
	setn(pos, basaltic_node)
	if math.random(1, 10) == 1 then
		sfn.drop_node(pos)
	end
end

local speedmult = 0.25

minetest.register_abm({
	label = "Lava Melting",
	nodenames = lava_group,
	neighbors = melt_group,
	interval = 13,
	chance = 256, -- Don't multiply melting speed.
	catch_up = false,
	action = do_lava_melting,
})

minetest.register_abm({
	label = "Lava Burn Flammable Nodes",
	nodenames = lava_group,
	neighbors = flammable_group,
	interval = 4,
	chance = 256*speedmult,
	catch_up = false,
	action = do_lava_flammables,
})

minetest.register_abm({
	label = "Lavasource Cooling",
	nodenames = lava_sources,
	neighbors = water_group,
	interval = 7,
	chance = 256*speedmult,
	catch_up = false,
	action = do_lavasource_cooling,
})

minetest.register_abm({
	label = "Flowinglava - Flowingwater Cooling",
	nodenames = flowing_lava,
	neighbors = flowing_water,
	interval = 9,
	chance = 256*speedmult,
	catch_up = false,
	action = do_flowinglava_flowingwater_cooling,
})

minetest.register_abm({
	label = "Flowinglava - Watersource Cooling",
	nodenames = flowing_lava,
	neighbors = water_sources,
	interval = 11,
	chance = 256*speedmult,
	catch_up = false,
	action = do_flowinglava_watersource_cooling,
})

minetest.register_abm({
	label = "Rockmelt Cooling",
	nodenames = {"cavestuff:cobble_with_rockmelt"},
	neighbors = water_group,
	interval = 3,
	chance = 256*speedmult,
	catch_up = false,
	action = do_rockmelt_cooling,
})

