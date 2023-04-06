
if not minetest.global_exists("cactus") then cactus = {} end
cactus.modpath = minetest.get_modpath("default")
cactus.steptime = {min=60, max=60*6}
cactus.plantname = "default:cactus"
cactus.maxheight = 5
cactus.minlight = 13

-- Localize for performance.
local math_floor = math.floor
local math_random = math.random

-- Should return a random height for an individual plant to grow.
function cactus.random_height()
	return math_floor(math_random(math_random(2, 3), math_random(3, 5)))
end

function cactus.is_sand_name(name)
	if minetest.get_item_group(name, "sand") ~= 0 then
		return true
	end
end

function cactus.has_sand(pos)
	local p = vector.add(pos, {x=0, y=-1, z=0})
	local name = minetest.get_node(p).name
	-- Must be on sand or grass.
	if cactus.is_sand_name(name) then
		return true
	end
end

function cactus.can_grow(pos)
	-- Must have sand nearby.
	if not cactus.has_sand(pos) then
		return
	end
	local positions = {
		{x=pos.x+1, y=pos.y, z=pos.z},
		{x=pos.x-1, y=pos.y, z=pos.z},
		{x=pos.x, y=pos.y, z=pos.z+1},
		{x=pos.x, y=pos.y, z=pos.z-1},
	}
	local air = 0
	for k, v in ipairs(positions) do
		if minetest.get_node(v).name == "air" then
			air = air + 1
		end
	end
	-- If cactus is tightly packed (not enough air) then cannot grow.
	if air < 2 then
		return
	end
	-- No check for water.
	return true
end

-- Obtain growth height from soil, initializing it if not done yet.
function cactus.get_grow_height(pos)
	local meta = minetest.get_meta({x=pos.x, y=pos.y-1, z=pos.z})
	local maxh = meta:get_int("cactus_height")
	if maxh == 0 then
		maxh = cactus.random_height()
		meta:set_int("cactus_height", maxh)
	end
	return maxh
end

-- Should be called when plant is dug.
function cactus.reset_grow_height_and_timer(pos)
	-- Find soil node below plant.
	local p = vector.new(pos)
	local name = minetest.get_node(p).name
	local d = 0
	while not cactus.is_sand_name(name) and d < cactus.maxheight do
		-- All except bottom-most node must be plant.
		if name ~= cactus.plantname then
			return
		end
		p.y = p.y - 1
		d = d + 1
		name = minetest.get_node(p).name
	end
	-- Must be on sand.
	if cactus.is_sand_name(name) then
		local meta = minetest.get_meta(p)
		local maxh = cactus.random_height()
		meta:set_int("cactus_height", maxh)
	else
		return
	end
	-- Restart timer for plant directly above soil.
	p.y = p.y + 1
	if minetest.get_node(p).name ~= cactus.plantname then
		return
	end
	local min = cactus.steptime.min
	local max = cactus.steptime.max
	minetest.get_node_timer(p):start(math_random(min, max))
end

-- Attempt to grow cactus.
-- Return 0 means nothing to report.
-- 10 means plant has reached max height.
-- 11 means plant is rotated wrong.
-- 12 means plant cannot grow because of ice.
function cactus.grow(pos, node)
	-- Check if we can grow.
	if not cactus.can_grow(pos) then
		return 0
	end
	if node.param2 >= 4 then
		return 11
	end

	if minetest.find_node_near(pos, 2, "group:cold") then
		return 12
	end

	-- Get how high we can grow.
	local maxh = cactus.get_grow_height(pos)
	-- Find current height of plant.
	local height = 0
	while node.name == cactus.plantname and height < maxh do
		height = height + 1
		pos.y = pos.y + 1
		node = minetest.get_node(pos)
	end
	if height >= maxh then
		-- Plant has reached max height.
		return 10
	end
	-- Check if we have room to grow some more.
	if node.name ~= "air" then
		return 0
	end
	-- Check if we have enough light.
  if minetest.get_node_light(pos) < cactus.minlight then
		return 0
	end
	-- Grow!
	minetest.add_node(pos, {name = cactus.plantname})
	return 0
end

function cactus.on_construct(pos)
	-- Only the ground-level plant piece should have nodetimer.
	-- If plant is not placed on soil, it will never have nodetimer.
	if cactus.has_sand(pos) then
		local min = cactus.steptime.min
		local max = cactus.steptime.max
		minetest.get_node_timer(pos):start(math_random(min, max))
	end
end

function cactus.on_destruct(pos)
	cactus.reset_grow_height_and_timer(pos)
end

function cactus.on_timer(pos, elapsed)
	--minetest.chat_send_all("# Server: Plant timer @ " .. minetest.pos_to_string(pos) .. "!")
	local node = minetest.get_node(pos)
	local result = cactus.grow(pos, node)
	-- Plant has reached max height.
	if result == 10 then return end
	-- Plant is rotated wrong.
	if result == 11 then return end
	-- Plant cannot grow because of ice.
	if result == 12 then return end
	return true
end

function cactus.after_dig_node(pos, node, metadata, digger)
	if node.param2 >= 4 then
		return
	end
	default.dig_up(pos, node, digger)
	-- No return value.
end

if not cactus.run_once then
	local c = "cactus:core"
	local f = cactus.modpath .. "/cactus.lua"
	reload.register_file(c, f, false)

	cactus.run_once = true
end
