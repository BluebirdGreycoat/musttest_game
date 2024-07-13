
local NOISE_SCALE = 1

-- Base terrain height.
ab.create_2d_noise("baseterrain", {
	offset = 0,
	scale = 16,
	spread = {x=512, y=512, z=512},
	seed = 58219,
	octaves = 8,
	persist = 0.6,
	lacunarity = 1.7,
})
