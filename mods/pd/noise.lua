
local NOISE_SCALE = 1

pd.perlins = pd.perlins or {}
pd.maps = pd.maps or {}
pd.noises = pd.noises or {}

local maps = pd.maps
local perlins = pd.perlins
local noises = pd.noises

function pd.create_2d_noise(which, data)
	local nk = which .. "_2d"
	noises[nk] = data
end

function pd.create_3d_noise(which, data)
	local nk = which .. "_3d"
	noises[nk] = data
end

-- Base terrain height.
pd.create_2d_noise("baseterrain", {
	offset = 1,
	scale = 16,
	spread = {x=16*NOISE_SCALE, y=16*NOISE_SCALE, z=16*NOISE_SCALE},
	seed = 44092,
	octaves = 2,
	persist = 0.5,
	lacunarity = 2,
})

function pd.get_2d_noise(pos, sides2D, which)
	local nk = which .. "_2d"
	local mk = which .. "_2d"
	local pk = which .. "_2d"
	local noisedata = noises[nk]
	perlins[pk] = perlins[pk] or minetest.get_perlin_map(noisedata, sides2D)
	maps[mk] = maps[mk] or {}
	perlins[pk]:get_2d_map_flat(pos, maps[mk])
	return maps[mk]
end

function ab.get_3d_noise(pos, sides3D, which)
	local nk = which .. "_3d"
	local mk = which .. "_3d"
	local pk = which .. "_3d"
	local noisedata = noises[nk]
	perlins[pk] = perlins[pk] or minetest.get_perlin_map(noisedata, sides3D)
	maps[mk] = maps[mk] or {}
	perlins[pk]:get_3d_map_flat(pos, maps[mk])
	return maps[mk]
end
