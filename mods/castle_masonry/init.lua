--if not minetest.is_singleplayer() then return end

castle_masonry = {}

local MP = minetest.get_modpath(minetest.get_current_modname())
dofile(MP.."/stone_wall.lua")
dofile(MP.."/paving.lua")

local S, NS = dofile(MP.."/intllib.lua")

local read_setting = function(name, default)
	local setting = minetest.settings:get_bool(name)
	if setting == nil then return default end
	return setting
end


castle_masonry.get_material_properties = function(material)
	local composition_def
	local burn_time
	if material.composition_material ~= nil then
		composition_def = minetest.registered_nodes[material.composition_material]
		burn_time = minetest.get_craft_result({method="fuel", width=1, items={ItemStack(material.composition_material)}}).time
	else
		composition_def = minetest.registered_nodes[material.craft_material]
		burn_time = minetest.get_craft_result({method="fuel", width=1, items={ItemStack(material.craft_materia)}}).time
	end

	local tiles = material.tile
	if tiles == nil then
		tiles = composition_def.tile
	elseif type(tiles) == "string" then
		tiles = {tiles}
	end

	local desc = material.desc
	if desc == nil then
		desc = composition_def.description
	end

	return composition_def, burn_time, tiles, desc
end









