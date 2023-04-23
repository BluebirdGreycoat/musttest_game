
-- Realistic Torch mod by TenPlus1

real_torch = {}

-- Localize for performance.
local math_random = math.random

-- check for timer settings or use defaults
-- torches stay lit for 6 - 7 hours of real time
real_torch.min_duration = tonumber(minetest.settings:get("torch_min_duration")) or (60*60*6)  --10--1200
real_torch.max_duration = tonumber(minetest.settings:get("torch_min_duration")) or (60*60*7)  --20--1800


-- check which torch(es) are available in minetest version
if minetest.registered_nodes["torches:torch_ceiling"] then

	dofile(minetest.get_modpath("real_torch") .. "/3d.lua")
	dofile(minetest.get_modpath("real_torch") .. "/3dk.lua")
else
	dofile(minetest.get_modpath("real_torch") .. "/2d.lua")
end


-- start timer on any already placed torches
--[[
minetest.register_lbm({
	name = "real_torch:convert_torch_to_node_timer",
	nodenames = {"torches:torch_floor", "torches:torch_wall", "torches:torch_ceiling"},
	action = function(pos)
		if not minetest.get_node_timer(pos):is_started() then
			minetest.get_node_timer(pos):start(
				math_random(real_torch.min_duration, real_torch.max_duration))
		end
	end
})
minetest.register_lbm({
	name = "real_torch:convert_kalite_torch_to_node_timer",
	nodenames = {"torches:kalite_torch_floor", "torches:kalite_torch_wall", "torches:kalite_torch_ceiling"},
	action = function(pos)
		if not minetest.get_node_timer(pos):is_started() then
			minetest.get_node_timer(pos):start(
				math_random(real_torch.min_duration*5, real_torch.max_duration*6))
		end
	end
})
--]]

function real_torch.start_timer(pos)
	minetest.get_node_timer(pos):start(math_random(real_torch.min_duration, real_torch.max_duration))
end
function real_torch.start_kalite_timer(pos)
	minetest.get_node_timer(pos):start(math_random(real_torch.min_duration*5, real_torch.max_duration*6))
	--minetest.get_node_timer(pos):start(math_random(5, 10))
end


-- creative check
local creative_mode_cache = minetest.settings:get_bool("creative_mode")
function is_creative(name)
	return creative_mode_cache or minetest.check_player_privs(name, {creative = true})
end


-- Note: this is also called by the tinderbox mod.
function real_torch.relight(itemstack, user, pointed_thing)
	if not pointed_thing or pointed_thing.type ~= "node" then
		return
	end

	local pos = pointed_thing.under
	local nod = minetest.get_node(pos)
	local rep = false

	if nod.name == "real_torch:torch" then
		nod.name = "torches:torch_floor"
		rep = true

	elseif nod.name == "real_torch:torch_wall" then
		nod.name = "torches:torch_wall"
		rep = true

	elseif nod.name == "real_torch:torch_ceiling" then
		nod.name = "torches:torch_ceiling"
		rep = true

	elseif nod.name == "real_torch:kalite_torch" then
		nod.name = "torches:kalite_torch_floor"
		rep = true

	elseif nod.name == "real_torch:kalite_torch_wall" then
		nod.name = "torches:kalite_torch_wall"
		rep = true

	elseif nod.name == "real_torch:kalite_torch_ceiling" then
		nod.name = "torches:kalite_torch_ceiling"
		rep = true
	end

	if rep then
		minetest.add_node(pos, {name = nod.name, param2 = nod.param2})

		if not is_creative(user:get_player_name()) then
			itemstack:take_item()
		end
	end

	return itemstack
end


-- coal powder
minetest.override_item("dusts:coal", {
	-- punching unlit torch with coal powder relights
	on_use = function(...)
		return real_torch.relight(...)
	end,
})

-- use coal powder as furnace fuel
minetest.register_craft({
	type = "fuel",
	recipe = "dusts:coal",
	burntime = 1,
})

minetest.register_craft({
  type = "fuel",
  recipe = "real_torch:torch",
  burntime = 1,
})

minetest.register_craft({
  type = "fuel",
  recipe = "real_torch:kalite_torch",
  burntime = 1,
})

-- add coal powder to burnt out torch to relight
minetest.register_craft({
	type = "shapeless",
	output = "torches:torch_floor",
	recipe = {"real_torch:torch", "dusts:coal"},
})
minetest.register_craft({
	type = "shapeless",
	output = "torches:kalite_torch_floor",
	recipe = {"real_torch:kalite_torch", "kalite:dust"},
})

-- 4x burnt out torches = 1x stick
minetest.register_craft({
	type = "shapeless",
	output = "default:stick",
	recipe = {"real_torch:torch", "real_torch:torch", "real_torch:torch", "real_torch:torch"},
})
minetest.register_craft({
	type = "shapeless",
	output = "default:stick",
	recipe = {"real_torch:kalite_torch", "real_torch:kalite_torch", "real_torch:kalite_torch", "real_torch:kalite_torch"},
})




-- particle effects
local function add_effects(pos, radius)

	minetest.add_particle({
		pos = pos,
		velocity = vector.new(),
		acceleration = vector.new(),
		expirationtime = 0.4,
		size = radius * 10,
		collisiondetection = false,
		vertical = false,
		texture = "tnt_boom.png",
		glow = 15,
	})

	minetest.add_particlespawner({
		amount = 16,
		time = 0.5,
		minpos = vector.subtract(pos, radius / 2),
		maxpos = vector.add(pos, radius / 2),
		minvel = {x = -2, y = -2, z = -2},
		maxvel = {x = 2, y = 2, z = 2},
		minacc = vector.new(),
		maxacc = vector.new(),
		minexptime = 1,
		maxexptime = 2.5,
		minsize = radius * 3,
		maxsize = radius * 5,
		texture = "tnt_smoke.png",
	})

	minetest.sound_play("tnt_explode", {pos = pos, gain = 0.1, max_hear_distance = 5}, true)
end


-- override tnt:gunpowder to explode when used on torch,
-- will also re-light torches and cause player damage when used on lit torch.
if minetest.get_modpath("tnt") then

minetest.override_item("tnt:gunpowder", {

	on_use = function(itemstack, user, pointed_thing)
		if not user or not user:is_player() then return end
		local pname = user:get_player_name() or ""

		if not pointed_thing or pointed_thing.type ~= "node" then
			return
		end

		local pos = pointed_thing.under
		local nod = minetest.get_node(pos)

		local rep = false

		if nod.name == "real_torch:torch" then
			nod.name = "torches:torch_floor"
			rep = true

		elseif nod.name == "real_torch:torch_wall" then
			nod.name = "torches:torch_wall"
			rep = true

		elseif nod.name == "real_torch:torch_ceiling" then
			nod.name = "torches:torch_ceiling"
			rep = true

		elseif nod.name == "real_torch:kalite_torch" then
			nod.name = "torches:kalite_torch_floor"
			rep = true

		elseif nod.name == "real_torch:kalite_torch_wall" then
			nod.name = "torches:kalite_torch_wall"
			rep = true

		elseif nod.name == "real_torch:kalite_torch_ceiling" then
			nod.name = "torches:kalite_torch_ceiling"
			rep = true
		end

		if rep then

			minetest.add_node(pos, {name = nod.name, param2 = nod.param2})

			add_effects(pos, 1)

			if not is_creative(user:get_player_name()) then
				itemstack:take_item()
			end

			return itemstack
		end

		if nod.name == "torches:torch_floor"
		or nod.name == "torches:torch_wall"
		or nod.name == "torches:torch_ceiling"
		or nod.name == "torches:kalite_torch_floor"
		or nod.name == "torches:kalite_torch_wall"
		or nod.name == "torches:kalite_torch_ceiling" then

			-- must execute outside callback!
			minetest.after(0, function()
				local user = minetest.get_player_by_name(pname)
				if not user or not user:is_player() then return end
				utility.damage_player(user, "heat", 2*500)
			end)

			add_effects(pos, 1)

			if not is_creative(user:get_player_name()) then
				itemstack:take_item()
			end
		end

		return itemstack
	end,
})
end
