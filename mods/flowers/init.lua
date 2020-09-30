-- Minetest 0.4 mod: default
-- See README.txt for licensing and other information.
-- Mod is reloadable.


-- Namespace for functions

flowers = flowers or {}
flowers.modpath = minetest.get_modpath("flowers")

-- Localize for performance.
local math_random = math.random

flowers.flora_mintime = 60*3
flowers.flora_maxtime = 60*30

function flowers.flora_density_for_surface(pos)
	local cold = 0
	if minetest.find_node_near(pos, 2, {
		"group:snow",
		"group:snowy",
		"group:ice",
		"group:cold",
	}) then
		cold = -2
	end

	-- Heat makes plants grow denser.
	local heat = 0
	if minetest.find_node_near(pos, 3, "group:melt_around") then
		heat = 1
	end

	-- Minerals improve flower growth.
	local minerals = 0
	if minetest.find_node_near(pos, 3, "glowstone:minerals") then
		minerals = 1
	end

	-- The presence of water increases the flower density.
	local water = 0
	if minetest.find_node_near(pos, 3, "group:water") then
		water = 1
	end

	-- Lush grass is better for flora than other grasses.
	if minetest.get_node(pos).name == "moregrass:darkgrass" then
		return 4 + water + minerals + heat + cold
	end

	-- Default flower density.
	return 3 + water + minerals + heat + cold
end

function flowers.surface_can_spawn_flora(pos)
	local name = minetest.get_node(pos).name
	if minetest.get_item_group(name, "soil") ~= 0 then
		-- Including desert sand, or else flora placed there would never turn to dry shrubs.
		return true
	end
	return false
end

function flowers.on_flora_construct(pos)
	if flowers.surface_can_spawn_flora({x=pos.x, y=pos.y-1, z=pos.z}) then
		minetest.get_node_timer(pos):start(math_random(flowers.flora_mintime, flowers.flora_maxtime))
	end
end

function flowers.on_flora_destruct(pos)
	-- Notify nearby flora.
	local minp = vector.subtract(pos, 4)
	local maxp = vector.add(pos, 4)
	local flora = minetest.find_nodes_in_area_under_air(minp, maxp, "group:flora")
	if flora and #flora > 0 then
		for i=1, #flora do
			minetest.get_node_timer(flora[i]):start(math_random(flowers.flora_mintime, flowers.flora_maxtime))
		end
	end
end

function flowers.on_flora_timer(pos, elapsed)
	--minetest.chat_send_player("MustTest", "Flora timer @ " .. minetest.pos_to_string(pos) .. "!")

	local node = minetest.get_node(pos)
	if flowers.flower_spread(pos, node) then
		minetest.get_node_timer(pos):start(math_random(flowers.flora_mintime, flowers.flora_maxtime))
	else
		-- Else timer should stop, cannot grow anymore.
		minetest.get_node_timer(pos):stop()
	end
end

function flowers.on_flora_punch(pos, node, puncher, pt)
	if flowers.surface_can_spawn_flora({x=pos.x, y=pos.y-1, z=pos.z}) then
		minetest.get_node_timer(pos):start(math_random(flowers.flora_mintime, flowers.flora_maxtime))
	end
end


--
-- Flowers
--

if not flowers.registered then
	-- Aliases for original flowers mod

	minetest.register_alias("flowers:flower_rose", "flowers:rose")
	minetest.register_alias("flowers:flower_tulip", "flowers:tulip")
	minetest.register_alias("flowers:flower_dandelion_yellow", "flowers:dandelion_yellow")
	minetest.register_alias("flowers:flower_geranium", "flowers:geranium")
	minetest.register_alias("flowers:flower_viola", "flowers:viola")
	minetest.register_alias("flowers:flower_dandelion_white", "flowers:dandelion_white")


	-- Flower registration

	local function add_simple_flower(name, desc, box, f_groups)
		-- Common flowers' groups
		f_groups.flower = 1
		f_groups.flora = 1
		f_groups.attached_node = 1

		-- Flowers are supposed to be flammable! [MustTest]
		f_groups.flammable = 3

		minetest.register_node(":flowers:" .. name, {
			description = desc,
			drawtype = "plantlike",
			waving = 1,
			tiles = {"flowers_" .. name .. ".png"},
			inventory_image = "flowers_" .. name .. ".png",
			wield_image = "flowers_" .. name .. ".png",
			sunlight_propagates = true,
			paramtype = "light",
			walkable = false,
			buildable_to = true,
			--stack_max = 99,
			groups = utility.dig_groups("plant", f_groups),
			sounds = default.node_sound_leaves_defaults(),
			selection_box = {
				type = "fixed",
				fixed = box
			},
			movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

			on_construct = function(...)
				return flowers.on_flora_construct(...)
			end,

			on_destruct = function(...)
				return flowers.on_flora_destruct(...)
			end,

			on_timer = function(...)
				return flowers.on_flora_timer(...)
			end,

			on_punch = function(...)
				return flowers.on_flora_punch(...)
			end,
		})
	end

	flowers.datas = {
		{
			"rose",
			"Red Rose",
			{-2 / 16, -0.5, -2 / 16, 2 / 16, 5 / 16, 2 / 16},
			{color_red = 1, flammable = 1}
		},
		{
			"rose_white",
			"White Rose",
			{-2 / 16, -0.5, -2 / 16, 2 / 16, 5 / 16, 2 / 16},
			{color_white = 1, flammable = 1}
		},
		{
			"tulip",
			"Orange Tulip",
			{-2 / 16, -0.5, -2 / 16, 2 / 16, 3 / 16, 2 / 16},
			{color_orange = 1, flammable = 1}
		},
		{
			"dandelion_yellow",
			"Yellow Dandelion",
			{-4 / 16, -0.5, -4 / 16, 4 / 16, -2 / 16, 4 / 16},
			{color_yellow = 1, flammable = 1}
		},
		{
			"chrysanthemum_green",
			"Green Chrysanthemum",
			{-4 / 16, -0.5, -4 / 16, 4 / 16, -1 / 16, 4 / 16},
			{color_green = 1, flammable = 1}
		},
		{
			"geranium",
			"Blue Geranium",
			{-2 / 16, -0.5, -2 / 16, 2 / 16, 2 / 16, 2 / 16},
			{color_blue = 1, flammable = 1}
		},
		{
			"viola",
			"Viola",
			{-5 / 16, -0.5, -5 / 16, 5 / 16, -1 / 16, 5 / 16},
			{color_violet = 1, flammable = 1}
		},
		{
			"dandelion_white",
			"White Dandelion",
			{-5 / 16, -0.5, -5 / 16, 5 / 16, -2 / 16, 5 / 16},
			{color_white = 1, flammable = 1}
		},
		{
			"tulip_black",
			"Black Tulip",
			{-2 / 16, -0.5, -2 / 16, 2 / 16, 3 / 16, 2 / 16},
			{color_black = 1, flammable = 1}
		},
                {
			"zinnia_red",
			"Red Zinnia",
			{-2 / 16, -0.5, -2 / 16, 2 / 16, 3 / 16, 2 / 16},
			{color_red = 1, flammable = 1}
		},
                {
			"lupine_purple",
			"Purple Lupine",
			{-2 / 16, -0.5, -2 / 16, 2 / 16, 5 / 16, 2 / 16},
			{color_violet = 1, flammable = 1}
		},
                  {
			"jack",
			"Jack in the Pulpit",
			{-2 / 16, -0.5, -2 / 16, 2 / 16, 5 / 16, 2 / 16},
			{color_dark_green = 1, flammable = 1}
		},
                {
			"poppy_orange",
			"Orange Poppy",
			{-2 / 16, -0.5, -2 / 16, 2 / 16, 5 / 16, 2 / 16},
			{color_orange = 1, flammable = 1}
		},
                {
			"daylily",
			"Daylily",
			{-2 / 16, -0.5, -2 / 16, 2 / 16, 5 / 16, 2 / 16},
			{color_yellow = 1, flammable = 1}
		},
                {
			"iris_black",
			"Black Iris",
			{-2 / 16, -0.5, -2 / 16, 2 / 16, 5 / 16, 2 / 16},
			{color_black = 1, flammable = 1}
		},
                {
			"forgetmenot",
			"Forget-Me-Not",
			{-2 / 16, -0.5, -2 / 16, 2 / 16, 5 / 16, 2 / 16},
			{color_cyan = 1, flammable = 1}
		},
                {
			"snapdragon",
			"Snapdragon",
			{-2 / 16, -0.5, -2 / 16, 2 / 16, 5 / 16, 2 / 16},
			{color_magenta = 1, flammable = 1}
		},
                {
			"bluebell",
			"Bluebell",
			{-2 / 16, -0.5, -2 / 16, 2 / 16, 5 / 16, 2 / 16},
			{color_blue = 1, flammable = 1}
		},
                {
			"foxglove_pink",
			"Pink Foxglove",
			{-2 / 16, -0.5, -2 / 16, 2 / 16, 5 / 16, 2 / 16},
			{color_pink = 1, flammable = 1}
		},
	}
        

	for _,item in pairs(flowers.datas) do
		add_simple_flower(unpack(item))
	end

	flowers.registered = true
end


-- Flower spread
-- Public function to enable override by mods

function flowers.flower_spread(pos, node)
	pos.y = pos.y - 1
	local under = minetest.get_node(pos)
	pos.y = pos.y + 1
  
  -- Replace flora with dry shrub in desert sand and silver sand,
	-- as this is the only way to generate them.
	-- However, preserve grasses in sand dune biomes.
	if minetest.get_item_group(under.name, "sand") == 1 and
			under.name ~= "default:sand" then
		minetest.add_node(pos, {name = "default:dry_shrub"})
		return false
	end

	if minetest.get_item_group(under.name, "soil") == 0 then
		return false
	end

	local light = minetest.get_node_light(pos) or 0
	if light < 13 then
		-- Is this just a daytime thing?
		if (minetest.get_node_light(pos, 0.5) or 0) < 13 then
			return false
		else
			return true -- Keep trying.
		end
	end

	local density = flowers.flora_density_for_surface({x=pos.x, y=pos.y-1, z=pos.z})
	local pos0 = vector.subtract(pos, 4)
	local pos1 = vector.add(pos, 4)
	if #minetest.find_nodes_in_area(pos0, pos1, "group:flora") > density then
		return false -- Max flora reached.
	end

	local soils = minetest.find_nodes_in_area_under_air(pos0, pos1, "group:soil")
	if #soils > 0 then
		local seedling = soils[math_random(1, #soils)]
		local seedling_above = {x=seedling.x, y=seedling.y+1, z=seedling.z}

		local light = minetest.get_node_light(seedling_above) or 0
		if light < 13 then
			-- Is this just a daytime thing?
			if (minetest.get_node_light(seedling_above, 0.5) or 0) < 13 then
				return false
			else
				return true -- Keep trying.
			end
		end

		-- Desert sand is in the soil group.
		if minetest.get_node(seedling).name == "default:desert_sand" then
			return false
		end

		minetest.add_node(seedling_above, {name = node.name, param2 = node.param2})
		return true
	end

	return false
end



-- Indexed array.
flowers.mushroom_surfaces = {
	"default:dirt",
	"rackstone:dauthsand",
	"group:soil",
	"group:tree",

	-- We disable these because they are much too common.
	-- Mushroom farms would be too easy to make, especially during a cave survival challenge.
	--"group:cavern_soil",
	--"darkage:silt",
	--"darkage:mud",
}

flowers.mushroom_nodes = {
	"flowers:mushroom_red",
	"flowers:mushroom_brown",
	"cavestuff:mycena",
	"cavestuff:fungus",
}

flowers.mushroom_mintime = 60*3
flowers.mushroom_maxtime = 60*30

function flowers.surface_can_spawn_mushroom(pos)
	local name = minetest.get_node(pos).name
	local nodes = flowers.mushroom_surfaces
	for i=1, #nodes do
		if string.find(nodes[i], "^group:") then
			local group = string.sub(nodes[i], 7)
			if minetest.get_item_group(name, group) ~= 0 then
				return true
			end
		elseif nodes[i] == name then
			return true
		end
	end
	return false
end

function flowers.on_mushroom_construct(pos)
	if flowers.surface_can_spawn_mushroom({x=pos.x, y=pos.y-1, z=pos.z}) then
		minetest.get_node_timer(pos):start(math_random(flowers.mushroom_mintime, flowers.mushroom_maxtime))
	end
end

function flowers.on_mushroom_destruct(pos)
	-- Notify nearby mushrooms.
	local minp = {x=pos.x-2, y=pos.y-2, z=pos.z-2}
	local maxp = {x=pos.x+2, y=pos.y+1, z=pos.z+2}
	local mushrooms = minetest.find_nodes_in_area_under_air(minp, maxp, flowers.mushroom_nodes)
	if mushrooms and #mushrooms > 0 then
		for i=1, #mushrooms do
			minetest.get_node_timer(mushrooms[i]):start(math_random(flowers.mushroom_mintime, flowers.mushroom_maxtime))
		end
	end
end

function flowers.on_mushroom_timer(pos, elapsed)
	--minetest.chat_send_player("MustTest", "Mushroom timer @ " .. minetest.pos_to_string(pos) .. "!")

	local node = minetest.get_node(pos)
	if flowers.mushroom_spread(pos, node) then
		minetest.get_node_timer(pos):start(math_random(flowers.mushroom_mintime, flowers.mushroom_maxtime))
	else
		-- Else timer should stop, cannot grow anymore.
		minetest.get_node_timer(pos):stop()
	end
end

function flowers.on_mushroom_punch(pos, node, puncher, pt)
	if flowers.surface_can_spawn_mushroom({x=pos.x, y=pos.y-1, z=pos.z}) then
		minetest.get_node_timer(pos):start(math_random(flowers.mushroom_mintime, flowers.mushroom_maxtime))
	end
end



if not flowers.reg2 then
	--
	-- Mushrooms
	--

	local eat_mushroom = minetest.item_eat(1)
	local function mushroom_poison(pname, step)
		local msg = "# Server: <" .. rename.gpn(pname) .. "> ate a mushroom. Desperate!"
		hb4.delayed_harm({name=pname, step=step, min=1, max=1, msg=msg, poison=true})
	end

	minetest.register_node("flowers:mushroom_red", {
		description = "Red Mushroom",
		tiles = {"flowers_mushroom_red.png"},
		inventory_image = "flowers_mushroom_red.png",
		wield_image = "flowers_mushroom_red.png",
		drawtype = "plantlike",
		paramtype = "light",
		sunlight_propagates = true,
		walkable = false,
		buildable_to = true,
		groups = utility.dig_groups("plant", {attached_node = 1, flammable = 1}),
		sounds = default.node_sound_leaves_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

		on_use = function(itemstack, user, pointed_thing)
			if not user or not user:is_player() then return end
			minetest.after(1, mushroom_poison, user:get_player_name(), 5)
			return eat_mushroom(itemstack, user, pointed_thing)
		end,

		selection_box = {
			type = "fixed",
			fixed = {-0.3, -0.5, -0.3, 0.3, 0, 0.3}
		},

		on_construct = function(...)
			return flowers.on_mushroom_construct(...)
		end,

		on_destruct = function(...)
			return flowers.on_mushroom_destruct(...)
		end,

		on_timer = function(...)
			return flowers.on_mushroom_timer(...)
		end,

		on_punch = function(...)
			return flowers.on_mushroom_punch(...)
		end,
	})

	minetest.register_node("flowers:mushroom_brown", {
		description = "Brown Mushroom",
		tiles = {"flowers_mushroom_brown.png"},
		inventory_image = "flowers_mushroom_brown.png",
		wield_image = "flowers_mushroom_brown.png",
		drawtype = "plantlike",
		paramtype = "light",
		sunlight_propagates = true,
		walkable = false,
		buildable_to = true,
		groups = utility.dig_groups("plant", {attached_node = 1, flammable = 1}),
		sounds = default.node_sound_leaves_defaults(),
		on_use = minetest.item_eat(1),
		selection_box = {
			type = "fixed",
			fixed = {-0.3, -0.5, -0.3, 0.3, 0, 0.3}
		},
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

		on_construct = function(...)
			return flowers.on_mushroom_construct(...)
		end,

		on_destruct = function(...)
			return flowers.on_mushroom_destruct(...)
		end,

		on_timer = function(...)
			return flowers.on_mushroom_timer(...)
		end,

		on_punch = function(...)
			return flowers.on_mushroom_punch(...)
		end,
	})

	flowers.reg2 = true
end



-- Called by the bonemeal mod.
-- Returns 'true' or 'false' to indicate if a mushroom was spawned.
function flowers.mushroom_spread(pos, node)
	if minetest.get_node_light(pos, nil) == 15 then
		minetest.remove_node(pos)
		return false
	end
	local minp = {x=pos.x-2, y=pos.y-2, z=pos.z-2}
	local maxp = {x=pos.x+2, y=pos.y+1, z=pos.z+2}
	local dirt = minetest.find_nodes_in_area_under_air(minp, maxp, flowers.mushroom_surfaces)
	if not dirt or #dirt == 0 then
		return false
	end
	local randp = dirt[math_random(1, #dirt)]
	local airp = {x=randp.x, y=randp.y+1, z=randp.z}
	local airn = minetest.get_node_or_nil(airp)
	if not airn or airn.name ~= "air" then
		return false
	end
	-- Mushrooms grow in nether regardless of light level.
	if pos.y < -25000 then
		minetest.add_node(airp, {name = node.name})
		return true
	end
	-- Otherwise, check light-level before growing.
	if minetest.get_node_light(pos, 0.5) <= 7 and
		minetest.get_node_light(airp, 0.5) <= 7 then
		minetest.add_node(airp, {name = node.name})
		return true
	end
	return false
end




if not flowers.reg3 then
	-- These old mushroom related nodes can be simplified now.
	minetest.register_alias("flowers:mushroom_spores_brown", "flowers:mushroom_brown")
	minetest.register_alias("flowers:mushroom_spores_red", "flowers:mushroom_red")
	minetest.register_alias("flowers:mushroom_fertile_brown", "flowers:mushroom_brown")
	minetest.register_alias("flowers:mushroom_fertile_red", "flowers:mushroom_red")
	minetest.register_alias("mushroom:brown_natural", "flowers:mushroom_brown")
	minetest.register_alias("mushroom:red_natural", "flowers:mushroom_red")


	--
	-- Waterlily
	--

	minetest.register_node("flowers:waterlily", {
		description = "Waterlily",
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",

		-- Horizontal rotation only!
		on_rotate = screwdriver.rotate_simple,

		tiles = {"flowers_waterlily.png", "flowers_waterlily_bottom.png"},
		inventory_image = "flowers_waterlily.png",
		wield_image = "flowers_waterlily.png",
		liquids_pointable = true,
		walkable = false,
		buildable_to = true,
		sunlight_propagates = true,
		floodable = true,

		-- Lily does not count as flora, it has special handling.
		groups = utility.dig_groups("plant", {flower = 1, flammable = 1}),

		sounds = default.node_sound_leaves_defaults(),
		node_placement_prediction = "",
		node_box = {
			type = "fixed",
			fixed = {-0.5, -31 / 64, -0.5, 0.5, -15 / 32, 0.5},
		},
		selection_box = {
			type = "fixed",
			fixed = {-0.5, -31 / 64, -0.5, 0.5, -15 / 32, 0.5},
		},

		on_place = function(itemstack, placer, pointed_thing)
			local pos = pointed_thing.above
			local node = minetest.get_node(pointed_thing.under).name
			local def = minetest.reg_ns_nodes[node]
			local player_name = placer:get_player_name()

			-- Lilies are placeable in any water.
			-- They only grow further in regular water sources.

			if def and def.liquidtype == "source" and
					minetest.get_item_group(node, "water") > 0 then
				if not minetest.is_protected(pos, player_name) then
					minetest.add_node(pos, {name = "flowers:waterlily",
						param2 = math_random(0, 3)})
					--if not minetest.setting_getbool("creative_mode") then
						itemstack:take_item()
					--end
				else
					minetest.chat_send_player(player_name, "# Server: Position is protected.")
					minetest.record_protection_violation(pos, player_name)
				end
			end

			return itemstack
		end,

		on_construct = function(...)
			return flowers.on_lily_construct(...)
		end,

		on_destruct = function(...)
			return flowers.on_lily_destruct(...)
		end,

		on_timer = function(...)
			return flowers.on_lily_timer(...)
		end,

		on_punch = function(...)
			return flowers.on_lily_punch(...)
		end,
	})

  minetest.register_node("flowers:lilyspawner", {
    drawtype = "airlike",
    description = "Lily Spawner (Please Report to Admin)",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    pointable = false,
    groups = {immovable = 1},
    climbable = false,
    buildable_to = true,
    floodable = true,
    drop = "",

		on_construct = function(...)
			flowers.on_lily_construct(...)
		end,

    on_timer = function(pos, elapsed)
			-- Always remove node, even if spawn unsuccessful.
			minetest.remove_node(pos)
			if minetest.find_node_near(pos, 3, "group:melt_around") then
				flowers.lily_spread(pos)
			end
    end,

    on_finish_collapse = function(pos, node)
      minetest.remove_node(pos)
    end,

    on_collapse_to_entity = function(pos, node)
      -- Do nothing.
    end,
  })

	flowers.reg3 = true
end

-- Make mod reloadable.
if not flowers.reg4 then
	local c = "flowers:core"
	local f = flowers.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	flowers.reg4 = true
end



function flowers.create_lilyspawner_near(pos)
	local water = minetest.find_node_near(pos, 3, "default:water_source")
	if water then
		water.y = water.y + 1
		if minetest.get_node(water).name == "air" then
			if not minetest.find_node_near(pos, 2, "group:cold") then
				minetest.add_node(water, {name="flowers:lilyspawner"})
				return true
			end
		end
	end
	return false
end

function flowers.lily_density_for_pos(pos)
	local cold = 0
	if minetest.find_node_near(pos, 2, {
		"group:snow",
		"group:snowy",
		"group:ice",
		"group:cold",
	}) then
		cold = -6
	end

	-- Heat makes lilies grow denser.
	local heat = 0
	if minetest.find_node_near(pos, 3, "group:melt_around") then
		heat = 1
	end

	-- Minerals improve lily growth.
	local minerals = 0
	if minetest.find_node_near(pos, 3, "glowstone:minerals") then
		minerals = 1
	end

	-- Calc lily density.
	return 7 + minerals + heat + cold
end

flowers.lily_mintime = 60*2
flowers.lily_maxtime = 60*15

function flowers.surface_can_spawn_lily(pos)
	local name = minetest.get_node(pos).name
	if name == "default:water_source" then
		return true
	end
	return false
end

-- This is called for both lily and lilyspawner.
function flowers.on_lily_construct(pos)
	if flowers.surface_can_spawn_lily({x=pos.x, y=pos.y-1, z=pos.z}) then
		minetest.get_node_timer(pos):start(math_random(flowers.lily_mintime, flowers.lily_maxtime))
	end
end

function flowers.on_lily_destruct(pos)
	-- Notify nearby lilies.
	local minp = vector.subtract(pos, 4)
	local maxp = vector.add(pos, 4)
	local lilies = minetest.find_nodes_in_area(minp, maxp, "flowers:waterlily")
	if lilies and #lilies > 0 then
		for i=1, #lilies do
			minetest.get_node_timer(lilies[i]):start(math_random(flowers.lily_mintime, flowers.lily_maxtime))
		end
	end
end

function flowers.on_lily_timer(pos, elapsed)
	--minetest.chat_send_player("MustTest", "Lily timer @ " .. minetest.pos_to_string(pos) .. "!")

	if flowers.lily_spread(pos) then
		minetest.get_node_timer(pos):start(math_random(flowers.lily_mintime, flowers.lily_maxtime))
	else
		-- Else timer should stop, cannot grow anymore.
		minetest.get_node_timer(pos):stop()
	end
end

function flowers.on_lily_punch(pos, node, puncher, pt)
	if flowers.surface_can_spawn_lily({x=pos.x, y=pos.y-1, z=pos.z}) then
		minetest.get_node_timer(pos):start(math_random(flowers.lily_mintime, flowers.lily_maxtime))
	end
end

-- This is called from lilyspawner and lily.
function flowers.lily_spread(pos)
	if not flowers.surface_can_spawn_lily({x=pos.x, y=pos.y-1, z=pos.z}) then
		return false
	end

	local light = minetest.get_node_light(pos) or 0
	if light < 13 then
		-- Is this just a daytime thing?
		if (minetest.get_node_light(pos, 0.5) or 0) < 13 then
			return false
		else
			return true -- Keep trying.
		end
	end

	local density = flowers.lily_density_for_pos(pos)
	local pos0 = vector.subtract(pos, 4)
	local pos1 = vector.add(pos, 4)
	if #minetest.find_nodes_in_area(pos0, pos1, "flowers:waterlily") > density then
		return false -- Max lilies reached.
	end

	local water = minetest.find_nodes_in_area_under_air(pos0, pos1, "default:water_source")
	if #water > 0 then
		local growpos = water[math_random(1, #water)]
		growpos.y = growpos.y + 1

		local light = minetest.get_node_light(growpos) or 0
		if light < 13 then
			-- Is this just a daytime thing?
			if (minetest.get_node_light(growpos, 0.5) or 0) < 13 then
				return false
			else
				return true -- Keep trying.
			end
		end

		minetest.add_node(growpos, {name="flowers:waterlily", param2=math_random(0, 3)})
		return true
	end

	return false
end
