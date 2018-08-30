-- mods/default/craftitems.lua

default = default or {}
function default.strike_protection(itemstack, user, pt)
	if not user or not user:is_player() then
		return
	end

	if pt.type ~= "node" then
		return
	end

	local pname = user:get_player_name()

	if minetest.test_protection(pt.under, pname) then
		ambiance.sound_play("default_metal_footstep", pt.under, 1.0, 20)
	else
		ambiance.sound_play("default_wood_footstep", pt.under, 1.0, 20)
	end
end

minetest.register_craftitem("default:stick", {
	description = "Stick\n\nCan be used to test protection.",
	inventory_image = "default_stick.png",
	groups = {stick = 1, flammable = 2},
	on_use = default.strike_protection,
})

minetest.register_craftitem("default:paper", {
	description = "Paper",
	inventory_image = "default_paper.png",
    groups = {flammable = 3},
})

minetest.register_craftitem("default:coal_lump", {
	description = "Coal Lump",
	inventory_image = "default_coal_lump.png",
	groups = {coal = 1, flammable = 1}
})

minetest.register_craftitem("default:iron_lump", {
	description = "Iron Lump",
	inventory_image = "default_iron_lump.png",
})

minetest.register_craftitem("default:copper_lump", {
	description = "Copper Lump",
	inventory_image = "default_copper_lump.png",
})

minetest.register_craftitem("default:mese_crystal", {
	description = "Mese Crystal",
	inventory_image = "default_mese_crystal.png",
})

minetest.register_craftitem("default:gold_lump", {
	description = "Gold Lump",
	inventory_image = "default_gold_lump.png",
})

minetest.register_craftitem("default:diamond", {
	description = "Diamond",
	inventory_image = "default_diamond.png",
})

minetest.register_craftitem("default:clay_lump", {
	description = "Clay Lump",
	inventory_image = "default_clay_lump.png",
})

minetest.register_craftitem("default:steel_ingot", {
	description = "Wrought Iron Ingot",
	inventory_image = "default_steel_ingot.png",
  groups = {ingot = 1},
})

minetest.register_craftitem("default:copper_ingot", {
	description = "Copper Ingot",
	inventory_image = "default_copper_ingot.png",
    groups = {ingot = 1},
})

minetest.register_craftitem("default:bronze_ingot", {
	description = "Bronze Ingot",
	inventory_image = "default_bronze_ingot.png",
    groups = {ingot = 1},
})

minetest.register_craftitem("default:gold_ingot", {
	description = "Gold Ingot",
	inventory_image = "default_gold_ingot.png",
    groups = {ingot = 1},
})

minetest.register_craftitem("default:mese_crystal_fragment", {
	description = "Mese Crystal Fragment",
	inventory_image = "default_mese_crystal_fragment.png",
})

minetest.register_craftitem("default:clay_brick", {
	description = "Clay Brick",
	inventory_image = "default_clay_brick.png",
})

minetest.register_craftitem("default:obsidian_shard", {
	description = "Obsidian Shard",
	inventory_image = "default_obsidian_shard.png",
})

minetest.register_craftitem("default:flint", {
	description = "Flint",
	inventory_image = "default_flint.png"
})














