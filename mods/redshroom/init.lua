
if not minetest.global_exists("redshroom") then redshroom = {} end
redshroom.modpath = minetest.get_modpath("redshroom")

-- Localize for performance.
local math_random = math.random



local SHROOM_SCHEMATICS = {
	"redshroom_shroom1.mts",
	"redshroom_shroom2.mts",
	"redshroom_shroom3.mts",
	"redshroom_shroom4.mts",
	"redshroom_shroom5.mts",
	"redshroom_shroom6.mts",
}



function redshroom.can_grow(pos)
	-- Nether shroom does not grow in other dimensions.
	if rc.current_realm_at_pos(pos) ~= "overworld" then
		return
	end

	local p2 = vector.offset(pos, 0, 1, 0)
	local p3 = vector.offset(pos, 0, 2, 0)

	local n2 = minetest.get_node(p2)
	local n3 = minetest.get_node(p3)

	--minetest.chat_send_all('name1: ' .. n2.name)
	--minetest.chat_send_all('name2: ' .. n3.name)

	-- Cannot grow if surface node is covered.
	if n3.name ~= "air" then
		--minetest.chat_send_all('no surface')
		return
	end

	-- Must have nether soil.
	if minetest.get_item_group(n2.name, "nether_soil") == 0 then
		--minetest.chat_send_all('no soil')
		return
	end

	-- Must not be too bright.
	if (minetest.get_node_light(p3, 0.5) or 0) > 10 then
		--minetest.chat_send_all('too bright')
		return
	end

	-- Reduced chance to grow if cold/ice nearby.
	local cold = minetest.find_nodes_in_area(vector.subtract(pos, 3), vector.add(pos, 3), "group:cold")
	if #cold > math.random(0, 196) then
		--minetest.chat_send_all('too cold')
		return
	end

	--minetest.chat_send_all('can grow')
	return true
end



function redshroom.on_construct(pos)
	--minetest.chat_send_all('on_construct')
	local timer = minetest.get_node_timer(pos)
	timer:start(math.random(60*10, 60*20))
end



function redshroom.on_timer(pos, elapsed)
	--minetest.chat_send_all('on_timer')

	if redshroom.can_grow(pos) then
		redshroom.create_shroom(vector.offset(pos, 0, 2, 0))
		minetest.remove_node(pos)
		return
	end

	-- Run timer again with the same timeout.
	return true
end



function redshroom.on_bonemeal_use(pos, node, user, itemstack)
	local timer = minetest.get_node_timer(pos)

	if timer:is_started() then
		local timeout = timer:get_timeout()
		local elapsed = timer:get_elapsed()
		local remain = (timeout - elapsed)
		if remain > 0 then
			-- Plant growtime is reduced by 2 thirds.
			local newtime = (remain / 3)
			timer:set(newtime, elapsed)
		end
	end

	itemstack:take_item()
	return itemstack
end



redshroom.create_shroom_on_vmanip = function(vm, pos)
	local schempath = redshroom.modpath .. "/schematics/"
	local path = schempath .. SHROOM_SCHEMATICS[math_random(#SHROOM_SCHEMATICS)]
	minetest.place_schematic_on_vmanip(vm, vector.add(pos, {x=-2, y=0, z=-2}), path, "random", nil, false)
end



redshroom.create_shroom = function(pos)
	local schempath = redshroom.modpath .. "/schematics/"
	local path = schempath .. SHROOM_SCHEMATICS[math_random(#SHROOM_SCHEMATICS)]
	minetest.place_schematic(vector.add(pos, {x=-2, y=0, z=-2}), path, "random", nil, false)
end



if not redshroom.registered then
	minetest.register_node("redshroom:stemwhite", {
		description = "White Shroom Stem",
		tiles = {"redshroom_stemtop_white.png", "redshroom_stemtop_white.png", "redshroom_stemside_white.png"},
		drawtype = "nodebox",
		paramtype2 = "facedir",
		paramtype = "light",
		groups = utility.dig_groups("shroom", {flammable=2}),
		sounds = default.node_sound_wood_defaults(),
		on_place = minetest.rotate_node,
		node_box = {
			type = "fixed",
			fixed = basictrees.trunk_nodebox,
		},
	})

	minetest.register_node("redshroom:gills", {
		description = "Shroom Gills",
		drawtype = "plantlike",
		tiles = {"redshroom_gills.png"},
		paramtype = "light",
		groups = utility.dig_groups("plant", {flammable=2, hanging_node=1}),
		drop = "", -- Gills are destroyed when dug.
		shears_drop = true, -- obtainable via shears
		walkable = false,
		buildable_to = true,
		sounds = default.node_sound_leaves_defaults(),
		selection_box = {
			type = "fixed",
			fixed = {-0.5, 5/16, -0.5, 0.5, 0.5, 0.5},
		},
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

		on_construct = function(...)
			return redshroom.on_construct(...)
		end,

		on_timer = function(...)
			return redshroom.on_timer(...)
		end,

		_on_bonemeal_use = function(...)
			return redshroom.on_bonemeal_use(...)
		end,
	})

	minetest.register_craft({
		type = "shapeless",
		output = "default:stick 16",
		recipe = {"redshroom:stemwhite"},
	})

	minetest.register_craft({
		type = "cooking",
		output = "default:coal_lump 4",
		recipe = "redshroom:stemwhite",
		cooktime = 60,
	})

	minetest.register_node("redshroom:head2", {
		description = "Red Shroom Head",
		tiles = {"redshroom_headtop.png", "redshroom_headtop.png", "redshroom_headside1.png"},
		paramtype2 = "facedir",
		groups = utility.dig_groups("shroom", {flammable=2}),
		sounds = default.node_sound_wood_defaults(),
		on_place = minetest.rotate_node
	})

	minetest.register_node("redshroom:stem", {
		description = "Red Shroom Stem",
		tiles = {"redshroom_stemtop.png", "redshroom_stemtop.png", "redshroom_stemside.png"},
		drawtype = "nodebox",
		paramtype2 = "facedir",
		paramtype = "light",
		groups = utility.dig_groups("shroom", {flammable=2}),
		sounds = default.node_sound_wood_defaults(),
		on_place = minetest.rotate_node,
		node_box = {
			type = "fixed",
			fixed = basictrees.trunk_nodebox,
		},
	})

	minetest.register_craft({
		type = "shapeless",
		output = "default:stick 16",
		recipe = {"redshroom:stem"},
	})

	minetest.register_node("redshroom:head", {
		description = "Red Shroom Head",
		tiles = {"redshroom_headtop.png", "redshroom_headtop.png", "redshroom_headside1.png^redshroom_headside2.png"},
		paramtype2 = "facedir",
		groups = utility.dig_groups("shroom", {flammable=2}),
		sounds = default.node_sound_wood_defaults(),
		on_place = minetest.rotate_node
	})

	local c = "redshroom:core"
	local f = redshroom.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	redshroom.registered = true
end
