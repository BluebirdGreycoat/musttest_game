-- mods/default/craftitems.lua

if not minetest.global_exists("default") then default = {} end

-- To be called by "stick" items to force infotext/formspec node updates.
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

	-- Update names in infotext.
	local node = minetest.get_node(pt.under)
	local ndef = minetest.registered_items[node.name]

	if not ndef then
		return
	end

	if ndef._on_update_infotext then
		ndef._on_update_infotext(pt.under)
	end

	if ndef._on_update_formspec then
		ndef._on_update_formspec(pt.under)
	end

	if ndef._on_update_entity then
		ndef._on_update_entity(pt.under)
	end
end

minetest.register_craftitem("default:stick", {
	description = "Stick\n\nCan be used to test protection.\nAlso updates infotext names.",
	inventory_image = "default_stick.png",
	groups = {stick = 1, flammable = 2},
	on_use = default.strike_protection,
})

minetest.register_craftitem("default:paper", {
	description = "Paper",
	inventory_image = "default_paper.png",
    groups = {flammable = 3},
})

minetest.register_craftitem("default:padlock", {
	description = "Lock",
	inventory_image = "lock_item.png",
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
	groups = {gem = 1, crystal = 1},
})

-- 'default_adamant_shard.png' texture by 'WintersKnight94', CC0 1.0 Universal
minetest.register_craftitem("default:adamant_shard", {
	description = "Adamant Shard",
	inventory_image = "default_adamant_shard.png",
	groups = {gem = 1, crystal = 1},
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














