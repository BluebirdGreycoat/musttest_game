
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

-- Sea floor glowing lights.
ww.create_2d_noise("glowveins", {
	offset = 0,
	scale = 1,
	spread = {x=64, y=64, z=64},
	seed = 162,
	octaves = 6,
	persist = 0.6,
	lacunarity = 1.7,
})

ww.create_2d_noise("seamounts", {
	offset = 0,
	scale = 1,
	spread = {x=1024, y=1024, z=1024},
	seed = 244,
	octaves = 6,
	persist = 0.6,
	lacunarity = 1.7,
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
