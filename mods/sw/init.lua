
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
local abs = math.abs
local floor = math.floor



function sw.on_generated(minp, maxp, blockseed)
	local mapgen = minetest.get_mapgen_object("gennotify")
	local data = (mapgen.custom and mapgen.custom["sw:mapgen_info"])
	if not data then return end

	-- This ugly hack is currently the best way I know of to make light correct
	-- after chunk generation.
	minetest.after(math.random(1, 100) / 50, function()
		local emin = vector.add(data.minp, {x=-16, y=-16, z=-16})
		local emax = vector.add(data.maxp, {x=16, y=16, z=16})
		mapfix.work(emin, emax)
	end)
end



local baseterrain
local continental
local mountains
local mtnchannel

function sw.get_ground_y(pos3d)
	-- This silliness exists because devs too busy with changing names of stuff.
	if not sw.have_noise then
		-- Noise replicated from the mapgen env.
		dofile(sw.modpath .. "/noise.lua")
		dofile(sw.modpath .. "/data.lua")

		baseterrain = sw.get_2d_perlin("baseterrain")
		continental = sw.get_2d_perlin("continental")
		mountains = sw.get_2d_perlin("mountains")
		mtnchannel = sw.get_2d_perlin("mtnchannel")

		assert(mtnchannel)

		sw.have_noise = true
	end

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
