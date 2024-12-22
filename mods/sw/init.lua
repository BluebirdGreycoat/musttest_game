
if not minetest.global_exists("sw") then sw = {} end
sw.modpath = minetest.get_modpath("sw")
sw.worldpath = minetest.get_worldpath()
sw.have_noise = false

dofile(sw.modpath .. "/ore.lua")



-- Copied from the mapgen env.
local REALM_GROUND = 10150+200
local TAN_OF_1 = math.tan(1)

local tan = math.tan
local min = math.min
local max = math.max
local abs = math.abs
local floor = math.floor



function sw.on_generated(minp, maxp, blockseed)
	local mapgen = minetest.get_mapgen_object("gennotify")
	local data = (mapgen.custom and mapgen.custom["sw:mapgen_info"])
	if not data then return end

	-- This ugly hack is currently the best way I know of to make light correct
	-- after chunk generation.
	if data.need_mapfix then
		minetest.after(math.random(1, 100) / 50, function()
			local emin = vector.add(data.minp, {x=-16, y=-16, z=-16})
			local emax = vector.add(data.maxp, {x=16, y=16, z=16})
			mapfix.work(emin, emax)
		end)
	end

	for k = 1, #data.on_construct do
		local pos = data.on_construct[k]
		local node = minetest.get_node(pos)
		local ndef = minetest.registered_nodes[node.name]
		if ndef and ndef.on_construct then
			ndef.on_construct(pos)
		end
	end
end



local baseterrain
local continental
local mountains
local mtnchannel

local noisemap1
local noisemap2
local noisemap3
local noisemap4
local noisemap5

-- This silliness exists because devs too busy with changing names of stuff.
-- Update: ok, so it makes sense that you cant use perlins at load time because
-- the mapgen parameters might still be changing.
local function init_perlin_once()
	if not sw.have_noise then
		-- Noise replicated from the mapgen env.
		dofile(sw.modpath .. "/noise.lua")
		dofile(sw.modpath .. "/data.lua")

		baseterrain = sw.get_2d_perlin("baseterrain")
		continental = sw.get_2d_perlin("continental")
		mountains = sw.get_2d_perlin("mountains")
		mtnchannel = sw.get_2d_perlin("mtnchannel")

		noisemap1 = sw.get_3d_perlin("cavern_noise1")
		noisemap2 = sw.get_3d_perlin("cavern_noise2")
		noisemap3 = sw.get_3d_perlin("cavern_noise3")
		noisemap4 = sw.get_3d_perlin("cavern_noise4")
		noisemap5 = sw.get_3d_perlin("cavern_noise5")

		assert(mtnchannel)
		assert(noisemap1)

		sw.have_noise = true
	end
end

-- Other parts of the code need to know the ground height at a location,
-- which can vary 1000's of nodes up or down.
function sw.get_ground_y(pos3d)
	init_perlin_once()

	local pos2d = {x=pos3d.x, y=pos3d.z}

	-- Calc multiplier [0, 1] for mountain noise.
	local mtnchnl = (tan(min(1, abs(mtnchannel:get_2d(pos2d)))) / TAN_OF_1)
	-- Sharpen curve.
	mtnchnl = mtnchnl * mtnchnl * mtnchnl

	local ground_y = REALM_GROUND + floor(
		baseterrain:get_2d(pos2d) +
		continental:get_2d(pos2d) +
		(mountains:get_2d(pos2d) * mtnchnl))

	return ground_y
end

function sw.want_cavern_ambiance(pos3d)
	local y = pos3d.y
	local ground_y = sw.get_ground_y(pos3d)

	local n1 = noisemap1:get_3d(pos3d)
	local n2 = noisemap2:get_3d(pos3d)
	local n3 = noisemap3:get_3d(pos3d)
	local n4 = noisemap4:get_3d(pos3d)
	--local n5 = noisemap5:get_3d(pos3d)

	if y < (ground_y - (500 + (abs(n4) * 50))) then
		local noise1 = n1 + n2 + n3

		-- Extend cavern ambiance beyond caverns slightly (use 0.0 instead of 0.2).
		if noise1 < 0.0 then
			return true
		end
	end

	return false
end

-- Causes assertion failure because can't call 'get_perlin' at load time.
--sw.get_ground_y({x=0, y=0, z=0})



if not sw.registered then
	minetest.set_gen_notify("custom", nil, {"sw:mapgen_info"})
	minetest.register_on_generated(function(...)
		sw.on_generated(...)
	end)

	-- Register the mapgen.
	minetest.register_mapgen_script(sw.modpath .. "/mapgen.lua")

	local c = "sw:core"
	local f = sw.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	sw.registered = true
end
