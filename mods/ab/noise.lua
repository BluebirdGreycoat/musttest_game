
local NOISE_SCALE = 1

ab.perlins = ab.perlins or {}
ab.maps = ab.maps or {}
ab.noises = ab.noises or {}

local maps = ab.maps
local perlins = ab.perlins
local noises = ab.noises

function ab.create_2d_noise(which, data)
	local nk = which .. "_2d"
	noises[nk] = data
end

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

function ab.get_2d_noise(pos, sides2D, which)
	local nk = which .. "_2d"
	local mk = which .. "_2d"
	local pk = which .. "_2d"
	local noisedata = noises[nk]
	perlins[pk] = perlins[pk] or minetest.get_perlin_map(noisedata, sides2D)
	maps[mk] = maps[mk] or {}
	perlins[pk]:get_2d_map_flat(pos, maps[mk])
	return maps[mk]
end
