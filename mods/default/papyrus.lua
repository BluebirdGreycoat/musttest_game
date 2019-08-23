
papyrus = papyrus or {}
papyrus.modpath = minetest.get_modpath("default")
papyrus.steptime = {min=60, max=60*6}
papyrus.plantname = "default:papyrus"
papyrus.maxheight = 5
papyrus.minlight = 13

-- Should return a random height for an individual plant to grow.
function papyrus.random_height()
	return math.floor(math.random(math.random(2, 3), math.random(3, 5)))
end

function papyrus.is_dirt_name(name)
	if name == "default:dirt_with_grass" or name == "default:dirt" or name == "moregrass:darkgrass" then
		return true
	end
end

function papyrus.has_dirt(pos)
	local p = vector.add(pos, {x=0, y=-1, z=0})
	local name = minetest.get_node(p).name
	-- Must be on dirt or grass.
	if papyrus.is_dirt_name(name) then
		return true
	end
end

function papyrus.can_grow(pos)
	-- Must have dirt nearby.
	if not papyrus.has_dirt(pos) then
		return
	end
	-- Must have water nearby.
	local p = vector.add(pos, {x=0, y=-1, z=0})
	if not minetest.find_node_near(p, 3, {"group:water"}) then
		return
	end
	return true
end

-- Obtain growth height from soil, initializing it if not done yet.
function papyrus.get_grow_height(pos)
	local meta = minetest.get_meta({x=pos.x, y=pos.y-1, z=pos.z})
	local maxh = meta:get_int("papyrus_height")
	if maxh == 0 then
		maxh = papyrus.random_height()
		meta:set_int("papyrus_height", maxh)
	end
	return maxh
end

-- Should be called when plant is dug.
function papyrus.reset_grow_height_and_timer(pos)
	-- Find soil node below plant.
	local p = vector.new(pos)
	local name = minetest.get_node(p).name
	local d = 0
	while not papyrus.is_dirt_name(name) and d < papyrus.maxheight do
		-- All except bottom-most node must be plant.
		if name ~= papyrus.plantname then
			return
		end
		p.y = p.y - 1
		d = d + 1
		name = minetest.get_node(p).name
	end
	-- Must be on dirt or grass.
	if papyrus.is_dirt_name(name) then
		local meta = minetest.get_meta(p)
		local maxh = papyrus.random_height()
		meta:set_int("papyrus_height", maxh)
	else
		return
	end
	-- Restart timer for plant directly above soil.
	p.y = p.y + 1
	if minetest.get_node(p).name ~= papyrus.plantname then
		return
	end
	local min = papyrus.steptime.min
	local max = papyrus.steptime.max
	minetest.get_node_timer(p):start(math.random(min, max))
end

-- Attempt to grow papyrus.
-- Return 0 means nothing to report.
-- 10 means plant has reached max height.
function papyrus.grow(pos, node)
	-- Check if we can grow.
	if not papyrus.can_grow(pos) then
		return 0
	end

	if minetest.find_node_near(pos, 2, "group:cold") then
		return 12
	end

	-- Get how high we can grow.
	local maxh = papyrus.get_grow_height(pos)
	-- Find current height of plant.
	local height = 0
	while node.name == papyrus.plantname and height < maxh do
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
  if minetest.get_node_light(pos) < papyrus.minlight then
		return 0
	end
	-- Grow!
	minetest.set_node(pos, {name = papyrus.plantname})
	return 0
end

function papyrus.on_construct(pos)
	-- Only the ground-level plant piece should have nodetimer.
	-- If plant is not placed on soil, it will never have nodetimer.
	if papyrus.has_dirt(pos) then
		local min = papyrus.steptime.min
		local max = papyrus.steptime.max
		minetest.get_node_timer(pos):start(math.random(min, max))
	end
end

function papyrus.on_destruct(pos)
	papyrus.reset_grow_height_and_timer(pos)
end

function papyrus.on_timer(pos, elapsed)
	--minetest.chat_send_all("# Server: Plant timer @ " .. minetest.pos_to_string(pos) .. "!")
	local node = minetest.get_node(pos)
	local result = papyrus.grow(pos, node)
	-- Plant has reached max height.
	if result == 10 then return end
	-- Plant cannot grow because of ice.
	if result == 12 then return end
	return true
end

function papyrus.after_dig_node(pos, node, metadata, digger)
	default.dig_up(pos, node, digger)
	-- No return value.
end

if not papyrus.run_once then
	local c = "papyrus:core"
	local f = papyrus.modpath .. "/papyrus.lua"
	reload.register_file(c, f, false)

	papyrus.run_once = true
end
