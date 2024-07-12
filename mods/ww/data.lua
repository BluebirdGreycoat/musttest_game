
local NOISE_SCALE = 1

-- Base terrain height.
ww.create_2d_noise("seafloor", {
	offset = 8,
	scale = 16,
	spread = {x=64, y=64, z=64},
	seed = 44092,
	octaves = 6,
	persist = 0.6,
	lacunarity = 1.8,
})

ww.create_2d_noise("floorchannel", {
	offset = 0,
	scale = 1,
	spread = {x=128, y=128, z=128},
	seed = 5811,
	octaves = 8,
	persist = 0.6,
	lacunarity = 1.8,
})

ww.create_3d_noise("shear1", {
	offset = 0,
	scale = 10,
	spread = {x=64, y=8, z=64},
	seed = 173,
	octaves = 2,
	persist = 0.5,
	lacunarity = 2,
	flags = "eased",
})

ww.create_3d_noise("shear2", {
	offset = 0,
	scale = 10,
	spread = {x=64, y=8, z=64},
	seed = 682,
	octaves = 2,
	persist = 0.5,
	lacunarity = 2,
	flags = "eased",
})
