
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
ARMOR_LEVEL_MULTIPLIER = 1.0

-- You can use this to increase or decrease overall armor healing,
-- eg: ARMOR_HEAL_MULTIPLIER = 0 will disable healing altogether.
ARMOR_HEAL_MULTIPLIER = 1.0

dofile(armor.modpath .. "/armor.lua")
dofile(armor.modpath .. "/stomp.lua")

if not armor.run_once then
	armor.run_once = true

	local function register_piece(name, data)
		data._armor_resist_groups = sysdmg.get_armor_resist_for(name)
		data._armor_wear_groups = sysdmg.get_armor_wear_for(name)
		data.groups = sysdmg.get_armor_groups_for(name, data.groups)
		minetest.register_tool(name, data)
	end

	-- Materials can only be loaded once, obviously.
	ARMOR_MATERIALS = {
		wood    = {item="group:wood"            , name="Wood"        , padding="farming:cotton"       , fuel=10, cook=0 , shield=true  , chestplate_name=""           , boots_name=""      , helmet_name=""      , leggings_name="Chausses"},
		steel   = {item="default:steel_ingot"   , name="Wrought Iron", padding="group:leather_padding", fuel=0 , cook=15, shield=true  , chestplate_name=""           , boots_name=""      , helmet_name=""      , leggings_name=""        },
		bronze  = {item="default:bronze_ingot"  , name="Bronze"      , padding="group:leather_padding", fuel=0 , cook=15, shield=true  , chestplate_name=""           , boots_name=""      , helmet_name=""      , leggings_name=""        },

		-- Note to self so I don't forget: diamond armor doesn't use leather in its craft ON PURPOSE!
		-- This is also true for wood armor. Leather is hard to get!
		diamond = {item="default:diamond"       , name="Diamond"     , padding="farming:cloth"        , fuel=0 , cook=0 , shield=true  , chestplate_name="Shardplate" , boots_name="Shoes" , helmet_name="Crown" , leggings_name=""        },

		gold    = {item="default:gold_ingot"    , name="Golden"      , padding="group:leather_padding", fuel=0 , cook=15, shield=true  , chestplate_name=""           , boots_name=""      , helmet_name=""      , leggings_name=""        },
		mithril = {item="moreores:mithril_ingot", name="Mithril"     , padding="group:leather_padding", fuel=0 , cook=15, shield=true  , chestplate_name=""           , boots_name=""      , helmet_name=""      , leggings_name=""        },
		carbon  = {item="carbon_steel:ingot"    , name="Carbon Steel", padding="group:leather_padding", fuel=0 , cook=15, shield=true  , chestplate_name=""           , boots_name=""      , helmet_name=""      , leggings_name=""        },

		-- Note, cotton/leather armor textures are from UncleBob, CC0.
		cotton  = {item="farming:cloth"         , name="Cloth"       , padding="farming:cotton"       , fuel=4 , cook=0 , shield=false , chestplate_name="Jerkin"     , boots_name="Shoes" , helmet_name="Cap"   , leggings_name="Chausses"},
		leather = {item="mobs:leather"          , name="Leather"     , padding="farming:cloth"        , fuel=6 , cook=0 , shield=false , chestplate_name="Jerkin"     , boots_name="Shoes" , helmet_name="Cap"   , leggings_name="Chausses"},
	}

	for key, data in pairs(ARMOR_MATERIALS) do
		local capname = "Helmet"
		if data.helmet_name ~= "" then
			capname = data.helmet_name
		end

		register_piece("3d_armor:helmet_" .. key, {
			description = data.name .. " " .. capname,
			inventory_image = "3d_armor_inv_helmet_" .. key .. ".png",
			groups = {armor_head=1},
		})

		local chestname = "Chestplate"
		if data.chestplate_name ~= "" then
			chestname = data.chestplate_name
		end

		register_piece("3d_armor:chestplate_" .. key, {
			description = data.name .. " " .. chestname,
			inventory_image = "3d_armor_inv_chestplate_" .. key .. ".png",
			groups = {armor_torso=1},
		})

		local legname = "Leggings"
		if data.leggings_name ~= "" then
			legname = data.leggings_name
		end

		register_piece("3d_armor:leggings_" .. key, {
			description = data.name .. " " .. legname,
			inventory_image = "3d_armor_inv_leggings_" .. key .. ".png",
			groups = {armor_legs=1},
		})

		local shoename = "Boots"
		if data.boots_name ~= "" then
			shoename = data.boots_name
		end

		register_piece("3d_armor:boots_" .. key, {
			description = data.name .. " " .. shoename,
			inventory_image = "3d_armor_inv_boots_" .. key .. ".png",
			groups = {armor_feet=1},
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

	-- Warning: this must be the ONLY hp-change-modifier in the entire Lua code!
	minetest.register_on_player_hpchange(function(...)
		return armor.on_player_hp_change(...) end, true)

	inventory_plus.register_button("armor", "Armor")

	local c = "armor:core"
	local f = armor.modpath .. "/init.lua"
	reload.register_file(c, f, false)
end
