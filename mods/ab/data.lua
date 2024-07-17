
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

-- Large, deep canyons.
ab.create_2d_noise("canyons", {
	offset = 0,
	scale = 1,
	spread = {x=1024, y=1024, z=1024},
	seed = 289149,
	octaves = 7,
	persist = 0.7,
	lacunarity = 1.7,
})

ab.create_3d_noise("canyonshear1", {
	offset = 0,
	scale = 10,
	spread = {x=64, y=32, z=64},
	seed = 822,
	octaves = 2,
	persist = 0.5,
	lacunarity = 2,
})

ab.create_3d_noise("canyonshear2", {
	offset = 0,
	scale = 10,
	spread = {x=64, y=32, z=64},
	seed = 513,
	octaves = 2,
	persist = 0.5,
	lacunarity = 2,
})

-- Roughen the edges of canyons.
ab.create_2d_noise("canyonpath", {
	offset = 0,
	scale = 1,
	spread = {x=16, y=16, z=16},
	seed = 489,
	octaves = 4,
	persist = 0.5,
	lacunarity = 2,
	flags = "noeased",
})

ab.create_2d_noise("canyonwidth", {
	offset = 0,
	scale = 2,
	spread = {x=1024, y=1024, z=1024},
	seed = 6628,
	octaves = 2,
	persist = 0.5,
	lacunarity = 2,
	flags = "absvalue",
})

ab.create_2d_noise("canyondepth", {
	offset = 0,
	scale = 1.5,
	spread = {x=1024, y=1024, z=1024},
	seed = 513,
	octaves = 2,
	persist = 0.5,
	lacunarity = 2,
	flags = "absvalue",
})
