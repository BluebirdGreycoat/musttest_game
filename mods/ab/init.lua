
if not minetest.global_exists("ab") then ab = {} end
ab.modpath = minetest.get_modpath("ab")
ab.worldpath = minetest.get_worldpath()

local REALM_START = 21150
local REALM_END = 23450
local REALM_GROUND = 21150+2000

local abs = math.abs
local min = math.min
local max = math.max
local floor = math.floor

dofile(ab.modpath .. "/ore.lua")
dofile(ab.modpath .. "/decorations.lua")



function ab.on_generated(minp, maxp, blockseed)
	local mapgen = minetest.get_mapgen_object("gennotify")
	local data = (mapgen.custom and mapgen.custom["ab:mapgen_info"])
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
end



local noisemap1
local noisemap2
local noisemap3
local noisemap4
local noisemap5

-- Can't construct mapgen perlin at mod load time, MG parameters can still change.
local function init_perlin_once()
	if not ab.have_noise then
		-- Noise replicated from the mapgen env.
		dofile(ab.modpath .. "/noise.lua")
		dofile(ab.modpath .. "/data.lua")

		noisemap1 = ab.get_3d_perlin("cavern_noise1")
		noisemap2 = ab.get_3d_perlin("cavern_noise2")
		noisemap3 = ab.get_3d_perlin("cavern_noise3")
		noisemap4 = ab.get_3d_perlin("cavern_noise4")
		noisemap5 = ab.get_3d_perlin("cavern_noise5")

		assert(noisemap1)

		ab.have_noise = true
	end
end

function ab.want_cavern_ambiance(pos3d)
	init_perlin_once()

	local y = pos3d.y
	local ground_y = REALM_GROUND

	local n1 = noisemap1:get_3d(pos3d)
	local n2 = noisemap2:get_3d(pos3d)
	local n3 = noisemap3:get_3d(pos3d)
	local n4 = noisemap4:get_3d(pos3d)
	--local n5 = noisemap5:get_3d(pos3d)

	if y < (ground_y - (350 + (abs(n4) * 50))) then
		local noise1 = n1 + n2 + n3
		if noise1 < 0.0 then
			return true
		end
	end

	return false
end



if not ab.registered then
	minetest.set_gen_notify("custom", nil, {"ab:mapgen_info"})
	minetest.register_on_generated(function(...)
		ab.on_generated(...)
	end)

	-- Register the mapgen.
	minetest.register_mapgen_script(ab.modpath .. "/mapgen.lua")

	local c = "ab:core"
	local f = ab.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	ab.registered = true
end
