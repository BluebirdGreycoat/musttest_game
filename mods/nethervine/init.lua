
if not minetest.global_exists("nethervine") then nethervine = {} end
nethervine.modpath = minetest.get_modpath("nethervine")

-- Localize for performance.
local math_random = math.random

dofile(nethervine.modpath .. "/functions.lua")



nethervine.vine_on_construct = function(pos)
	local timer = minetest.get_node_timer(pos)
	timer:start(math_random(60*3, 60*6))
end

nethervine.vine_on_timer = function(pos, elapsed)
	return nethervine.grow(pos, minetest.get_node(pos))
end

nethervine.grow = function(pos, node)
	local timer = minetest.get_node_timer(pos)

	pos.y = pos.y + 1
	local name = minetest.get_node(pos).name
	if name ~= "rackstone:dauthsand_stable" and name ~= "rackstone:nether_grit" then
		return
	end

	local have_heat = false
	if minetest.find_node_near(pos, 4, "group:flame") or
			minetest.find_node_near(pos, 5, "group:lava") then
		have_heat = true
	end
	if not have_heat then
		return
	end

	local have_minerals = false
	if minetest.find_node_near(pos, 4, "glowstone:minerals") then
		have_minerals = true
	end
	pos.y = pos.y - 1
	local height = 0
	while node.name == "nethervine:vine" and height < 4 do
		height = height - 1
		pos.y = pos.y - 1
		node = minetest.get_node(pos)
	end
	if height == 4 or node.name ~= "air" then
		return
	end

	minetest.add_node(pos, {name = "nethervine:vine"})

	if have_minerals then
		timer:start(math_random(60*1, 60*2))
	else
		timer:start(math_random(60*3, 60*6))
	end
end


function nethervine.on_grass_timer(pos, elapsed)
	-- Dry out nethergrass if too near lava.
	if minetest.find_node_near(pos, 3, "group:lava") then
		minetest.swap_node(pos, {name="nether:grass_dried"})
		return false
	end
	return nethervine.on_flora_timer(pos, elapsed)
end



local eat_function = minetest.item_eat(0)
function nethervine.eat_dried_grass(itemstack, user, pt)
	if not user or not user:is_player() then return end
	if user:get_hp() == 0 then return end
	user:set_hp(user:get_hp() + (4*500))
	return eat_function(itemstack, user, pt)
end

function nethervine.eat_grass(itemstack, user, pt)
	if not user or not user:is_player() then return end
	local pname = user:get_player_name()
	local msg = "# Server: <" .. rename.gpn(pname) .. "> ate forbidden grass. Desperate!"
  hb4.delayed_harm({name=pname, step=2, min=1*500, max=3*500, msg=msg, poison=true})
	return eat_function(itemstack, user, pt)
end



if not nethervine.registered then
	minetest.register_node("nethervine:vine", {
		description = "Wormroot",
		drawtype = "plantlike",
		tiles = {"nethervine_vine.png"},
		inventory_image = "nethervine_vine.png",
		wield_image = "nethervine_vine.png",
		paramtype = "light",
		sunlight_propagates = true,
		walkable = false,
		selection_box = {
			type = "fixed",
			fixed = {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3}
		},
		climbable = true,
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

		drop = "",
		shears_drop = true,
		flowerpot_drop = "nethervine:vine",

		-- Nethervines shall not be flammable. They often generate next to lava.
		groups = utility.dig_groups("plant", {
			hanging_node = 1,
		}),

		sounds = default.node_sound_leaves_defaults(),

		on_construct = function(...)
			return nethervine.vine_on_construct(...)
		end,

		on_timer = function(...)
			return nethervine.vine_on_timer(...)
		end,
	})

	for i = 1, 3 do
		minetest.register_node(":nether:grass_" .. i, {
			description = "Nether Grass",
			drawtype = "plantlike",
			waving = 1,
			tiles = {"nethergrass_" .. i .. ".png"},
			inventory_image = "nethergrass_3.png",
			wield_image = "nethergrass_3.png",
			paramtype = "light",
			paramtype2 = "meshoptions",
			place_param2 = 2,
			sunlight_propagates = true,
			walkable = false,
			buildable_to = true,
			drop = "nether:grass",
			flowerpot_drop = "nether:grass",
			groups = utility.dig_groups("plant", {netherflora = 1, attached_node = 1, not_in_creative_inventory = 1, grass = 1, flammable = 1}),
			sounds = default.node_sound_leaves_defaults(),
			selection_box = {
				type = "fixed",
				fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
			},
			movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

			on_construct = function(...)
				return nethervine.on_flora_construct(...)
			end,

			on_destruct = function(...)
				return nethervine.on_flora_destruct(...)
			end,

			on_timer = function(...)
				-- Call custom function which adds the conversion to dried grass.
				return nethervine.on_grass_timer(...)
			end,

			on_punch = function(...)
				return nethervine.on_flora_punch(...)
			end,
		})
	end

	-- This node is not meant to be placed in the world.
	-- Instead, placing it causes 1 of several other nodetypes to be placed instead.
	minetest.register_node(":nether:grass", {
		description = "Forbidden Grass",
		drawtype = "plantlike",
		waving = 1,
		tiles = {"nethergrass_3.png"},
		-- Use texture of a taller grass stage in inventory
		inventory_image = "nethergrass_3.png",
		wield_image = "nethergrass_3.png",
		paramtype = "light",
		paramtype2 = "meshoptions",
		place_param2 = 2,
		sounds = default.node_sound_leaves_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

		flowerpot_insert = {"nether:grass_1", "nether:grass_2", "nether:grass_3"},

		-- Zero-width selection box.
		selection_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -0.5, 0.5},
		},

		on_place = function(itemstack, placer, pt)
			-- place a random grass node
			local stack = ItemStack("nether:grass_" .. math_random(1,3))
			local ret = minetest.item_place(stack, placer, pt)
			return ItemStack("nether:grass " .. itemstack:get_count() - (1 - ret:get_count()))
		end,

		on_use = function(...)
			return nethervine.eat_grass(...)
		end,
	})

	-- Dried nethergrass has edible property!
	minetest.register_node(":nether:grass_dried", {
		description = "Saltified Forbidden Grass",
		drawtype = "plantlike",
		waving = 1,
		tiles = {"nethergrass_dried.png"},
		-- Use texture of a taller grass stage in inventory
		inventory_image = "nethergrass_dried.png",
		wield_image = "nethergrass_dried.png",
		paramtype = "light",
		paramtype2 = "meshoptions",
		place_param2 = 2,
		walkable = false,
		sounds = default.node_sound_leaves_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
		groups = utility.dig_groups("plant", {netherflora = 1, attached_node = 1, not_in_creative_inventory = 1, grass = 1, flammable = 3}),

		selection_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
		},

		on_use = function(...)
			return nethervine.eat_dried_grass(...)
		end,
	})

	-- This particular flower does not grow!
	minetest.register_node(":nether:glowflower", {
		description = "Nevermore Flower",
		drawtype = "plantlike",
		--waving = 1, -- Plant does not respond to wind.
		tiles = {"nether_glowflower.png"},
		inventory_image = "nether_glowflower.png",
		wield_image = "nether_glowflower.png",
		paramtype = "light",
		walkable = false,
		sounds = default.node_sound_leaves_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
		groups = utility.dig_groups("plant", {attached_node = 1, not_in_creative_inventory = 1, flammable = 3}),
		light_source = 10,

		drop = {
			max_items = 1,
			items = {
				{
					rarity = 3,
					tools = {"moreores:sword_silver"},
					items = {"farming:cotton 4", "farming:string"},
				},
				{
					rarity = 5,
					items = {"farming:cotton 2"},
				},
				{
					rarity = 1,
					items = {"farming:cotton"},
				},
			},
		},

		shears_drop = true, -- Drop self.
		flowerpot_drop = "nether:glowflower",

		selection_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
		},
	})

	minetest.register_craft({
		type = "fuel",
		recipe = "nethervine:vine",
		burntime = 1,
	})

	local c = "nethervine:core"
	local f = nethervine.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	nethervine.registered = true
end

