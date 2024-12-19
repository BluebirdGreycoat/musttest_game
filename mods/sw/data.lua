
local NOISE_SCALE = 1

-- Given scale, octaves, and persistence,
-- get the max value the perlin noise can have.
local function calc(scale, oct, perc)
	local acc = scale
	for k = 1, oct - 1 do
		-- Get amplitude of *previous* octave multiplied by persist.
		local fac = math.ceil((scale/(2^(k-1)))*perc)
		acc = acc + fac
	end
	return acc
end

-- Get the *actual* in-engine scale value in order to achive desired max scale.
local function doit(scale, oct, perc)
	local a = calc(scale, oct, perc)
	return math.floor((scale / a) * scale)
end

-- Base terrain large scale.
sw.create_2d_noise("continental", {
	offset = 1500,
	scale = doit(1500, 3, 0.5),
	spread = {x=8000, y=8000, z=8000},
	seed = 48984,
	octaves = 3,
	persist = 0.5,
	lacunarity = 2,
})

-- Base terrain medium scale, more hilly.
sw.create_2d_noise("baseterrain", {
	offset = 500,
	scale = doit(500, 8, 0.5),
	spread = {x=3000, y=3000, z=3000},
	seed = 44092,
	octaves = 8,
	persist = 0.5,
	lacunarity = 2,
})

-- Very steep mountain terrain.
sw.create_2d_noise("mountains", {
	offset = 300,
	scale = doit(300, 8, 0.7),
	spread = {x=512, y=512, z=512},
	seed = 44092,
	octaves = 8,
	persist = 0.7,
	lacunarity = 1.7,
})

-- Determines whether mountains will rise up from the land.
sw.create_2d_noise("mtnchannel", {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = 8813,
	octaves = 3,
	persist = 0.5,
	lacunarity = 2.0,
})

sw.create_3d_noise("shear1", {
	offset = 0,
	scale = 16,
	spread = {x=64, y=32, z=64},
	seed = 2718,
	octaves = 3,
	persist = 0.5,
	lacunarity = 2,
	flags = "eased",
})

sw.create_3d_noise("shear2", {
	offset = 0,
	scale = 16,
	spread = {x=64, y=32, z=64},
	seed = 8281,
	octaves = 3,
	persist = 0.5,
	lacunarity = 2,
	flags = "eased",
})

sw.create_3d_noise("softener", {
	offset = 0,
	scale = 2,
	spread = {x=64, y=64, z=64},
	seed = 183,
	octaves = 4,
	persist = 0.5,
	lacunarity = 2,
})

--------------------------------------------------------------------------------
sw.create_3d_noise("cavern_noise1", {
	offset = 0,
	scale = 1,
	spread = {x=200, y=60, z=200},
	seed = 88812,
	octaves = 6,
	persist = 0.5,
	lacunarity = 1.5,
})

sw.create_3d_noise("cavern_noise2", {
	offset = 0,
	scale = 1,
	spread = {x=100, y=60, z=100},
	seed = 88813,
	octaves = 5,
	persist = 0.6,
	lacunarity = 1.5,
})

sw.create_3d_noise("cavern_noise3", {
	offset = 0.5,
	scale = 1,
	spread = {x=500, y=500, z=500},
	seed = 88814,
	octaves = 4,
	persist = 0.7,
	lacunarity = 1.5,
})

sw.create_3d_noise("cavern_noise4", {
	offset = 0,
	scale = 1,
	spread = {x=74, y=62, z=74},
	seed = 88815,
	octaves = 3,
	persist = 0.8,
	lacunarity = 1.5,
})

sw.create_3d_noise("cavern_noise5", {
	offset = 0,
	scale = 1,
	spread = {x=8, y=16, z=8},
	seed = 888166,
	octaves = 2,
	persist = 0.5,
	lacunarity = 1.5,
})
