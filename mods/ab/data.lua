
local NOISE_SCALE = 1

-- Base terrain height.
ab.create_2d_noise("baseterrain", {
	offset = 1,
	scale = 16,
	spread = {x=16*NOISE_SCALE, y=16*NOISE_SCALE, z=16*NOISE_SCALE},
	seed = 44092,
	octaves = 2,
	persist = 0.5,
	lacunarity = 2,
})
