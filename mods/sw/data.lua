
local NOISE_SCALE = 1

-- Base terrain height.
sw.create_2d_noise("baseterrain", {
	offset = 500,
	scale = 500,
	spread = {x=3000, y=3000, z=3000},
	seed = 44092,
	octaves = 8,
	persist = 0.5,
	lacunarity = 2,
})

sw.create_3d_noise("shear1", {
	offset = 0,
	scale = 10,
	spread = {x=64, y=8, z=64},
	seed = 2718,
	octaves = 2,
	persist = 0.5,
	lacunarity = 2,
})

sw.create_3d_noise("shear2", {
	offset = 0,
	scale = 10,
	spread = {x=64, y=8, z=64},
	seed = 8281,
	octaves = 2,
	persist = 0.5,
	lacunarity = 2,
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
