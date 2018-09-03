-- Thanks to sofar for helping with that code.

local plate = {}
screwdriver = screwdriver or {}

local function door_toggle(pos_actuator, pos_door, player)
	local actuator = minetest.get_node(pos_actuator)
	local door = doors.get(pos_door)

	if actuator.name:sub(-4) == "_off" then
		minetest.set_node(pos_actuator,
			{name=actuator.name:gsub("_off", "_on"), param2=actuator.param2})
	end
	door:open(player)

	minetest.after(2, function()
		if minetest.get_node(pos_actuator).name:sub(-3) == "_on" then
			minetest.set_node(pos_actuator,
				{name=actuator.name, param2=actuator.param2})
		end
		door:close(player)
	end)
end

function plate.on_player_walk_over(pos, player)
	if not player or not player:is_player() then
		return
	end

	local minp = {x=pos.x-2, y=pos.y, z=pos.z-2}
	local maxp = {x=pos.x+2, y=pos.y, z=pos.z+2}
	local doors = minetest.find_nodes_in_area(minp, maxp, "group:door")

	for i=1, #doors do
		door_toggle(pos, doors[i], player)
	end
end

function plate.register(material, desc, def)
	xdecor.register("pressure_"..material.."_off", {
		description = desc.." Pressure Plate",
		tiles = {"xdecor_pressure_"..material..".png"},
		drawtype = "nodebox",
		node_box = xdecor.pixelbox(16, {{1, 0, 1, 14, 1, 14}}),
		groups = def.groups,
		sounds = def.sounds,
		sunlight_propagates = true,
		on_rotate = screwdriver.rotate_simple,
		on_player_walk_over = plate.on_player_walk_over
	})
	xdecor.register("pressure_"..material.."_on", {
		tiles = {"xdecor_pressure_"..material..".png"},
		drawtype = "nodebox",
		node_box = xdecor.pixelbox(16, {{1, 0, 1, 14, 0.4, 14}}),
		groups = def.groups,
		sounds = def.sounds,
		drop = "xdecor:pressure_"..material.."_off",
		sunlight_propagates = true,
		on_rotate = screwdriver.rotate_simple
	})
end

plate.register("wood", "Wooden", {
	sounds = default.node_sound_wood_defaults(),
	groups = {choppy=3, oddly_breakable_by_hand=2, flammable=2}
})

plate.register("stone", "Stone", {
	sounds = default.node_sound_stone_defaults(),
	groups = {cracky=3, oddly_breakable_by_hand=2}
})

xdecor.register("lever_off", {
	description = "Lever",
	tiles = {"xdecor_lever_off.png"},
	drawtype = "nodebox",
	node_box = xdecor.pixelbox(16, {{2, 1, 15, 12, 14, 1}}),
	groups = {cracky=3, oddly_breakable_by_hand=2},
	sounds = default.node_sound_stone_defaults(),
	sunlight_propagates = true,
	on_rotate = screwdriver.rotate_simple,
	on_rightclick = function(pos, node, clicker, itemstack)
		if not doors.get then return itemstack end
		local minp = {x=pos.x-2, y=pos.y-1, z=pos.z-2}
		local maxp = {x=pos.x+2, y=pos.y+1, z=pos.z+2}
		local doors = minetest.find_nodes_in_area(minp, maxp, "group:door")

		for i=1, #doors do
			door_toggle(pos, doors[i], clicker)
		end
		return itemstack
	end
})

xdecor.register("lever_on", {
	tiles = {"xdecor_lever_on.png"},
	drawtype = "nodebox",
	node_box = xdecor.pixelbox(16, {{2, 1, 15, 12, 14, 1}}),
	groups = {cracky=3, oddly_breakable_by_hand=2, not_in_creative_inventory=1},
	sounds = default.node_sound_stone_defaults(),
	sunlight_propagates = true,
	on_rotate = screwdriver.rotate_simple,
	drop = "xdecor:lever_off"
})

-- Recipes

minetest.register_craft({
	output = "xdecor:pressure_stone_off",
	type = "shapeless",
	recipe = {"group:stone", "group:stone"}
})

minetest.register_craft({
	output = "xdecor:pressure_wood_off",
	type = "shapeless",
	recipe = {"group:wood", "group:wood"}
})

minetest.register_craft({
	output = "xdecor:lever_off",
	recipe = {
		{"group:stick"},
		{"default:steel_ingot"}
	}
})


-- Explosive pressure plate.

local function plate_explode(pos, player)
	if not player or not player:is_player() then
		return
	end

	local pname = player:get_player_name()
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")

	if owner == pname then
		return
	end

	-- Always remove, even if protected. Prevents infinite use.
	minetest.remove_node(pos)

	-- Detonate some TNT! Usually kills player, may not necessarily cause environment damage.
  tnt.boom(vector.add(pos, {x=math.random(-2, 2), y=0, z=math.random(-2, 2)}), {
    radius = 3,
    ignore_protection = false,
    ignore_on_blast = false,
    damage_radius = 3,
    disable_drops = true,
  })
end

-- Called when a player places a booby-trap plate.
local function plate_place(pos, placer, itemstack, pt)
	local meta = minetest.get_meta(pos)
	meta:set_string("owner", placer:get_player_name())
end

xdecor.register("explosive_plate", {
	description = "Booby-Trapped Pressure Plate (Land-Mine)\n\nExplosive! Use with care.",
	tiles = {"default_cobble.png"},
	drawtype = "nodebox",
	node_box = xdecor.pixelbox(16, {{1, 0, 1, 14, 1, 14}}),
	groups = {cracky=3, oddly_breakable_by_hand=1},
	sounds = default.node_sound_stone_defaults(),
	sunlight_propagates = true,
	on_rotate = screwdriver.rotate_simple,
	after_place_node = plate_place,
	on_player_walk_over = plate_explode,
})

minetest.register_craft({
	output = "xdecor:explosive_plate",
	type = "shapeless",
	recipe = {"tnt:tnt", "xdecor:pressure_stone_off"}
})

-- Unstable pressure plate.

local function plate_break(pos, player)
	if not player or not player:is_player() then
		return
	end

	local pname = player:get_player_name()
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")

	if owner == pname then
		return
	end

	-- Check if node has air below it.
	if minetest.get_node(vector.add(pos, {x=0, y=-2, z=0})).name == "air" then
		-- Collapse ground!
		if sfn.drop_node(vector.add(pos, {x=0, y=-1, z=0})) then
			-- Always remove, even if protected. Prevents infinite use.
			minetest.remove_node(pos)
		end
	end
end

xdecor.register("break_plate", {
	description = "Booby-Trapped Pressure Plate (Block-Breaker)\n\nWill cause block below to collapse.",
	tiles = {"default_wood.png"},
	drawtype = "nodebox",
	node_box = xdecor.pixelbox(16, {{1, 0, 1, 14, 1, 14}}),
	groups = {choppy=3, oddly_breakable_by_hand=1},
	sounds = default.node_sound_wood_defaults(),
	sunlight_propagates = true,
	on_rotate = screwdriver.rotate_simple,
	after_place_node = plate_place,
	on_player_walk_over = plate_break,
})

minetest.register_craft({
	output = "xdecor:break_plate",
	type = "shapeless",
	recipe = {"doors:trapdoor", "xdecor:pressure_wood_off"}
})

