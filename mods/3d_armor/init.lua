
if not minetest.global_exists("armor") then armor = {} end
armor.modname = armor.modname or minetest.get_current_modname()
armor.modpath = minetest.get_modpath(armor.modname)
armor.worldpath = minetest.get_worldpath()

-- Increase this if you get initialization glitches when a player first joins.
ARMOR_INIT_DELAY = 1

-- Number of initialization attempts.
-- Use in conjunction with ARMOR_INIT_DELAY if initialization problems persist.
ARMOR_INIT_TIMES = 1

-- Increase this if armor is not getting into bones due to server lag.
ARMOR_BONES_DELAY = 1

-- How often player armor/wield items are updated.
ARMOR_UPDATE_TIME = 1

-- You can use this to increase or decrease overall armor effectiveness,
-- eg: ARMOR_LEVEL_MULTIPLIER = 0.5 will reduce armor level by half.
ARMOR_LEVEL_MULTIPLIER = 0.5

-- You can use this to increase or decrease overall armor healing,
-- eg: ARMOR_HEAL_MULTIPLIER = 0 will disable healing altogether.
ARMOR_HEAL_MULTIPLIER = 0.5

dofile(armor.modpath .. "/armor.lua")

if not armor.run_once then
	armor.run_once = true

	-- Materials can only be loaded once, obviously.
	ARMOR_MATERIALS = {
		wood = "group:wood",
		steel = "default:steel_ingot",
		bronze = "default:bronze_ingot",
		diamond = "default:diamond",
		gold = "default:gold_ingot",
		mithril = "moreores:mithril_ingot",
		carbon = "carbon_steel:ingot",
	}

	if ARMOR_MATERIALS.wood then
		minetest.register_tool("3d_armor:helmet_wood", {
			description = "Wood Helmet",
			inventory_image = "3d_armor_inv_helmet_wood.png",
			groups = {armor_head=5, armor_heal=0, armor_use=2000},
			wear = 0,

			_armor_wear_from_fall = 0.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_crush = 3.0,
			_armor_wear_from_heat = 3.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 0.0,

			_armor_resist_groups = {fleshy=5},
		})

		minetest.register_tool("3d_armor:chestplate_wood", {
			description = "Wood Chestplate",
			inventory_image = "3d_armor_inv_chestplate_wood.png",
			groups = {armor_torso=10, armor_heal=0, armor_use=2000},
			wear = 0,

			_armor_wear_from_fall = 0.5,
			_armor_wear_from_punch = 1.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_heat = 3.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 0.0,
			_armor_wear_from_boom = 4.0,
		})

		minetest.register_tool("3d_armor:leggings_wood", {
			description = "Wood Leggings",
			inventory_image = "3d_armor_inv_leggings_wood.png",
			groups = {armor_legs=5, armor_heal=0, armor_use=2000},
			wear = 0,

			_armor_wear_from_fall = 1.25,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_heat = 3.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
		})

		minetest.register_tool("3d_armor:boots_wood", {
			description = "Wood Boots",
			inventory_image = "3d_armor_inv_boots_wood.png",
			groups = {armor_feet=5, armor_heal=0, armor_use=2000},
			wear = 0,

			_armor_wear_from_fall = 1.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_heat = 3.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 2.0,
		})
	end

	if ARMOR_MATERIALS.steel then
		minetest.register_tool("3d_armor:helmet_steel", {
			description = "Wrought Iron Helmet",
			inventory_image = "3d_armor_inv_helmet_steel.png",
			groups = {armor_head=10, armor_heal=0, armor_use=500},
			wear = 0,

			_armor_wear_from_fall = 0.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_crush = 3.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 0.0,
		})

		minetest.register_tool("3d_armor:chestplate_steel", {
			description = "Wrought Iron Chestplate",
			inventory_image = "3d_armor_inv_chestplate_steel.png",
			groups = {armor_torso=15, armor_heal=0, armor_use=500},
			wear = 0,

			_armor_wear_from_fall = 0.5,
			_armor_wear_from_punch = 1.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 0.0,
			_armor_wear_from_boom = 4.0,
		})

		minetest.register_tool("3d_armor:leggings_steel", {
			description = "Wrought Iron Leggings",
			inventory_image = "3d_armor_inv_leggings_steel.png",
			groups = {armor_legs=15, armor_heal=0, armor_use=500},
			wear = 0,

			_armor_wear_from_fall = 1.25,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
		})

		minetest.register_tool("3d_armor:boots_steel", {
			description = "Wrought Iron Boots",
			inventory_image = "3d_armor_inv_boots_steel.png",
			groups = {armor_feet=10, armor_heal=0, armor_use=500},
			wear = 0,

			_armor_wear_from_fall = 1.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 2.0,
		})
	end

	if ARMOR_MATERIALS.carbon then
		minetest.register_tool("3d_armor:helmet_carbon", {
			description = "Carbon Steel Helmet",
			inventory_image = "3d_armor_inv_helmet_carbon.png",
			groups = {armor_head=12, armor_heal=0, armor_use=200},
			wear = 0,

			_armor_wear_from_fall = 0.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_crush = 3.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 0.0,
		})

		minetest.register_tool("3d_armor:chestplate_carbon", {
			description = "Carbon Steel Chestplate",
			inventory_image = "3d_armor_inv_chestplate_carbon.png",
			groups = {armor_torso=17, armor_heal=0, armor_use=200},
			wear = 0,

			_armor_wear_from_fall = 0.5,
			_armor_wear_from_punch = 1.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 0.0,
			_armor_wear_from_boom = 4.0,
		})

		minetest.register_tool("3d_armor:leggings_carbon", {
			description = "Carbon Steel Leggings",
			inventory_image = "3d_armor_inv_leggings_carbon.png",
			groups = {armor_legs=17, armor_heal=0, armor_use=200},
			wear = 0,

			_armor_wear_from_fall = 1.25,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
		})

		minetest.register_tool("3d_armor:boots_carbon", {
			description = "Carbon Steel Boots",
			inventory_image = "3d_armor_inv_boots_carbon.png",
			groups = {armor_feet=12, armor_heal=0, armor_use=200},
			wear = 0,

			_armor_wear_from_fall = 1.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 2.0,
		})
	end

	if ARMOR_MATERIALS.bronze then
		minetest.register_tool("3d_armor:helmet_bronze", {
			description = "Bronze Helmet",
			inventory_image = "3d_armor_inv_helmet_bronze.png",
			groups = {armor_head=10, armor_heal=6, armor_use=250},
			wear = 0,

			_armor_wear_from_fall = 0.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_crush = 3.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 0.0,
		})

		minetest.register_tool("3d_armor:chestplate_bronze", {
			description = "Bronze Chestplate",
			inventory_image = "3d_armor_inv_chestplate_bronze.png",
			groups = {armor_torso=15, armor_heal=6, armor_use=250},
			wear = 0,

			_armor_wear_from_fall = 0.5,
			_armor_wear_from_punch = 1.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 0.0,
			_armor_wear_from_boom = 4.0,
		})

		minetest.register_tool("3d_armor:leggings_bronze", {
			description = "Bronze Leggings",
			inventory_image = "3d_armor_inv_leggings_bronze.png",
			groups = {armor_legs=15, armor_heal=6, armor_use=250},
			wear = 0,

			_armor_wear_from_fall = 1.25,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
		})

		minetest.register_tool("3d_armor:boots_bronze", {
			description = "Bronze Boots",
			inventory_image = "3d_armor_inv_boots_bronze.png",
			groups = {armor_feet=10, armor_heal=6, armor_use=250},
			wear = 0,

			_armor_wear_from_fall = 1.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 2.0,
		})
	end

	if ARMOR_MATERIALS.diamond then
		minetest.register_tool("3d_armor:helmet_diamond", {
			description = "Diamond Helmet",
			inventory_image = "3d_armor_inv_helmet_diamond.png",
			groups = {armor_head=15, armor_heal=12, armor_use=100},
			wear = 0,

			_armor_wear_from_fall = 0.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_crush = 3.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 0.0,
		})

		minetest.register_tool("3d_armor:chestplate_diamond", {
			description = "Diamond Chestplate",
			inventory_image = "3d_armor_inv_chestplate_diamond.png",
			groups = {armor_torso=20, armor_heal=12, armor_use=100},
			wear = 0,

			_armor_wear_from_fall = 0.5,
			_armor_wear_from_punch = 1.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 0.0,
			_armor_wear_from_boom = 4.0,
		})

		minetest.register_tool("3d_armor:leggings_diamond", {
			description = "Diamond Leggings",
			inventory_image = "3d_armor_inv_leggings_diamond.png",
			groups = {armor_legs=20, armor_heal=12, armor_use=100},
			wear = 0,

			_armor_wear_from_fall = 1.25,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
		})

		minetest.register_tool("3d_armor:boots_diamond", {
			description = "Diamond Boots",
			inventory_image = "3d_armor_inv_boots_diamond.png",
			groups = {armor_feet=15, armor_heal=12, armor_use=100},
			wear = 0,

			_armor_wear_from_fall = 1.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 2.0,
		})
	end

	if ARMOR_MATERIALS.gold then
		minetest.register_tool("3d_armor:helmet_gold", {
			description = "Gold Helmet",
			inventory_image = "3d_armor_inv_helmet_gold.png",
			groups = {armor_head=10, armor_heal=6, armor_use=250},
			wear = 0,

			_armor_wear_from_fall = 0.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_crush = 3.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 0.0,
		})

		minetest.register_tool("3d_armor:chestplate_gold", {
			description = "Gold Chestplate",
			inventory_image = "3d_armor_inv_chestplate_gold.png",
			groups = {armor_torso=15, armor_heal=6, armor_use=250},
			wear = 0,

			_armor_wear_from_fall = 0.5,
			_armor_wear_from_punch = 1.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 0.0,
			_armor_wear_from_boom = 4.0,
		})

		minetest.register_tool("3d_armor:leggings_gold", {
			description = "Gold Leggings",
			inventory_image = "3d_armor_inv_leggings_gold.png",
			groups = {armor_legs=15, armor_heal=6, armor_use=250},
			wear = 0,

			_armor_wear_from_fall = 1.25,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
		})

		minetest.register_tool("3d_armor:boots_gold", {
			description = "Gold Boots",
			inventory_image = "3d_armor_inv_boots_gold.png",
			groups = {armor_feet=10, armor_heal=6, armor_use=250},
			wear = 0,

			_armor_wear_from_fall = 1.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 2.0,
		})
	end

	if ARMOR_MATERIALS.mithril then
		minetest.register_tool("3d_armor:helmet_mithril", {
			description = "Mithril Helmet",
			inventory_image = "3d_armor_inv_helmet_mithril.png",
			groups = {armor_head=20, armor_heal=12, armor_use=50},
			wear = 0,

			_armor_wear_from_fall = 0.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_crush = 3.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 0.0,
		})

		minetest.register_tool("3d_armor:chestplate_mithril", {
			description = "Mithril Chestplate",
			inventory_image = "3d_armor_inv_chestplate_mithril.png",
			groups = {armor_torso=25, armor_heal=12, armor_use=50},
			wear = 0,

			_armor_wear_from_fall = 0.5,
			_armor_wear_from_punch = 1.5,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 0.0,
			_armor_wear_from_boom = 4.0,
		})

		minetest.register_tool("3d_armor:leggings_mithril", {
			description = "Mithril Leggings",
			inventory_image = "3d_armor_inv_leggings_mithril.png",
			groups = {armor_legs=25, armor_heal=12, armor_use=50},
			wear = 0,

			_armor_wear_from_fall = 0.8,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
		})

		minetest.register_tool("3d_armor:boots_mithril", {
			description = "Mithril Boots",
			inventory_image = "3d_armor_inv_boots_mithril.png",
			groups = {armor_feet=20, armor_heal=12, armor_use=50},
			wear = 0,

			_armor_wear_from_fall = 0.9,
			_armor_wear_from_drown = 0.0,
			_armor_wear_from_poison = 0.0,
			_armor_wear_from_hunger = 0.0,
			_armor_wear_from_ground = 2.0,
		})
	end

	-- Register Player Model
	default.player_register_model("3d_armor_character.b3d", {
		animation_speed = 30,
		textures = {
			armor.default_skin..".png",
			"3d_armor_trans.png",
			"3d_armor_trans.png",
		},
		animations = {
			stand = {x=0, y=79},
			lay = {x=162, y=166},
			walk = {x=168, y=187},
			mine = {x=189, y=198},
			walk_mine = {x=200, y=219},
			sit = {x=81, y=160},
		},
	})

	-- Register Callbacks
	minetest.register_on_player_receive_fields(function(...)
		return armor.on_player_receive_fields(...) end)

	minetest.register_on_joinplayer(function(...)
		return armor.on_joinplayer(...) end)

	minetest.register_on_player_hpchange(function(...)
		return armor.on_player_hp_change(...) end, true)

	inventory_plus.register_button("armor", "Armor")

	local c = "armor:core"
	local f = armor.modpath .. "/init.lua"
	reload.register_file(c, f, false)
end
