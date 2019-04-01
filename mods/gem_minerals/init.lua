--------------------------------------------------------------------------------
-- Gem Minerals Mod for Must Test Survival
-- Author: GoldFireUn
-- License of Source Code: MIT
-- License of Media: CC BY-SA 3.0
--------------------------------------------------------------------------------

gem_minerals = gem_minerals or {}
gem_minerals.modpath = minetest.get_modpath("gem_minerals")

local gems = {
	{name="ruby", desc="Ruby", hardness=20},
	{name="amethyst", desc="Amethyst", hardness=12},
	{name="sapphire", desc="Sapphire", hardness=18},
	{name="emerald", desc="Emerald", hardness=15},
}

if not gem_minerals.registered then
	for k, v in ipairs(gems) do
		local ore = "gems:" .. v.name .. "_ore"
		local block = "gems:" .. v.name .. "_block"
		local gem = "gems:" .. v.name .. "_gem"
		local raw = "gems:raw_" .. v.name

		-- Ore.
		minetest.register_node(":" .. ore, {
			description = v.desc .. " Ore",
			tiles = {"default_stone.png^gem_minerals_" .. v.name .. "_ore.png"},
			is_ground_content = true,
			groups = utility.dig_groups("hardstone"),
			sounds = default.node_sound_stone_defaults(),
			drop = "gems:raw_" .. v.name,
			silverpick_drop = true,
		})

		-- Block.
		minetest.register_node(":" .. block, {
			description = v.desc .. " Block",
			tiles = {"gem_minerals_" .. v.name .. "_block.png"},
			is_ground_content = false,
			groups = utility.dig_groups("obsidian"),
			sounds = default.node_sound_stone_defaults(),
			drop = gem .. " 8",
			silverpick_drop = block,
		})

		-- Cut Gem.
		minetest.register_craftitem(":" .. gem, {
			description = v.desc .. " Gem",
			inventory_image = "gem_minerals_" .. v.name .. "_gem.png",
		})

		-- Raw gem.
		minetest.register_craftitem(":" .. raw, {
			description = "Uncut " .. v.desc .. " Gem",
			inventory_image = "gem_minerals_raw_" .. v.name .. ".png",
		})

		-- Block craft.
		minetest.register_craft({
			output = block,
			recipe = {
				{gem, gem, gem},
				{gem, "default:stone", gem},
				{gem, gem, gem},
			}
		})

		-- Get gems back from block.
		minetest.register_craft({
			type = "shapeless",
			output = gem .. " 8",
			recipe = {block},
		})

		-- Cut raw gem.
		minetest.register_craft({
			type = "cutting",
			output = gem,
			recipe = raw,
			hardness = v.hardness,
		})
	end

	local c = "gem_minerals:core"
	local f = gem_minerals.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	gem_minerals.registered = true
end
