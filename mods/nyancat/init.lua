
-- Localize for performance.
local math_floor = math.floor
local math_random = math.random
local math_min = math.min
local math_max = math.max
local set_node = minetest.set_node
local vector_round = vector.round
local hash_pos = minetest.hash_node_position



minetest.register_node("nyancat:nyancat", {
	description = "Glowing Rosestone Seed",
	tiles = {"nyancat_side.png^[transformR90", "nyancat_side.png^[transformR90",
		"nyancat_side.png",
		"nyancat_side.png", "nyancat_side.png", "nyancat_side.png"},
	paramtype2 = "facedir",
	groups = utility.dig_groups("nyan"),
	is_ground_content = false,
	legacy_facedir_simple = true,
	light_source = 10,
	sounds = default.node_sound_glass_defaults(),
	silverpick_drop = true,
	drop = "default:glass",
})

minetest.register_node("nyancat:nyancat_rainbow", {
	description = "Glowing Rosestone Tail",
	tiles = {
		"nyancat_rainbow.png^[transformR90",
		"nyancat_rainbow.png^[transformR90",
		"nyancat_rainbow.png"
	},
	paramtype2 = "facedir",
	groups = utility.dig_groups("nyan"),
	is_ground_content = false,
	light_source = 10,
	sounds = default.node_sound_glass_defaults(),
})

nyancat = {}

local crystal_directions = {
	{x=1,   y=0,    z=0},
	{x=-1,  y=0,    z=0},
	{x=0,   y=0,    z=1},
	{x=0,   y=0,    z=-1},

	-- Duplicate entries increase the chance that this direction is taken.
	{x=0,   y=-1,   z=0},
	{x=0,   y=-1,   z=0},
	{x=0,   y=1,   z=0},
	{x=0,   y=1,   z=0},
}

local generate_crystal -- Forward declaration needed for recursion.
generate_crystal = function(pos, rec_, tot_, has_)
	local rec = rec_ or 0
	local tot = tot_ or math_random(3, 10)
	local has = has_ or {}

	local key = hash_pos(pos)
	local gud = false

	if not has[key] then
		if rec == 0 then
			set_node(pos, {name="nyancat:nyancat"})
			has[key] = true
			gud = true
		else
			set_node(pos, {name="nyancat:nyancat_rainbow", param2=math_random(0, 3)})
			has[key] = true
			gud = true
		end
	end

	-- Do not generate crystal larger than max num blocks.
	if rec >= tot then return end

	local d1 = crystal_directions[math_random(1, #crystal_directions)]
	local p1 = {x=pos.x+d1.x, y=pos.y+d1.y, z=pos.z+d1.z}

	-- Recursive call.
	if gud then
		generate_crystal(p1, rec+1, tot, has)
	else
		generate_crystal(p1, rec+0, tot, has)
	end
end

nyancat.place = function(pos, count)
	minetest.chat_send_all('generating rosestone at ' .. minetest.pos_to_string(pos) .. ' with ' .. count .. ' blocks')
  generate_crystal(vector_round(pos), nil, count)
end

function nyancat.generate(minp, maxp, seed)
	local height_min = -25000 -- Don't generate nyan cats in the nether.
	local height_max = -32
	if maxp.y < height_min or minp.y > height_max then
		return
	end
	local y_min = math_max(minp.y, height_min)
	local y_max = math_min(maxp.y, height_max)
	local volume = (maxp.x - minp.x + 1) * (y_max - y_min + 1) * (maxp.z - minp.z + 1)
	local pr = PseudoRandom(seed + 9324342)
	local max_num_nyancats = math_floor(volume / (16 * 16 * 16))
	for i = 1, max_num_nyancats do
		if pr:next(0, 1000) == 0 then
			local x0 = pr:next(minp.x, maxp.x)
			local y0 = pr:next(minp.y, maxp.y)
			local z0 = pr:next(minp.z, maxp.z)
			local p0 = {x = x0, y = y0, z = z0}
			nyancat.place(p0, pr:next(3, 16))
		end
	end
end

minetest.register_on_generated(function(minp, maxp, seed)
	nyancat.generate(minp, maxp, seed)
end)

-- Legacy
minetest.register_alias("default:nyancat", "nyancat:nyancat")
minetest.register_alias("default:nyancat_rainbow", "nyancat:nyancat_rainbow")
minetest.register_alias("nyancat", "nyancat:nyancat")
minetest.register_alias("nyancat_rainbow", "nyancat:nyancat_rainbow")
default.make_nyancat = nyancat.place
default.generate_nyancats = nyancat.generate
