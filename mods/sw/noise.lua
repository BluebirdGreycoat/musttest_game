
local NOISE_SCALE = 1

sw.noises = sw.noises or {}
local noises = sw.noises

function sw.create_2d_noise(which, data)
	local nk = which .. "_2d"
	noises[nk] = data
end

-- Base terrain height.
sw.create_2d_noise("baseterrain", {
	offset = 1,
	scale = 16,
	spread = {x=16*NOISE_SCALE, y=16*NOISE_SCALE, z=16*NOISE_SCALE},
	seed = 44092,
	octaves = 2,
	persist = 0.5,
	lacunarity = 2,
})

sw.maps = sw.maps or {}
local perlins = {}

function sw.get_2d_noise(pos, sides2D, which)
	local nk = which .. "_2d"
	local mk = which .. "_2d"
	local noisedata = noises[nk]
	assert(noisedata)
	print(dump(noisedata))
	perlins[which] = perlins[which] or minetest.get_perlin_map(noisedata, sides2D)
	sw.maps[mk] = sw.maps[mk] or {}
	perlins[which]:get_2d_map_flat(pos, sw.maps[mk])
	return sw.maps[mk]
end
