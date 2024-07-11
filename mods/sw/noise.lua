
local NOISE_SCALE = 1

sw.perlins = sw.perlins or {}
sw.maps = sw.maps or {}
sw.noises = sw.noises or {}

local maps = sw.maps
local perlins = sw.perlins
local noises = sw.noises

function sw.create_2d_noise(which, data)
	local nk = which .. "_2d"
	noises[nk] = data
end

function sw.create_3d_noise(which, data)
	local nk = which .. "_3d"
	noises[nk] = data
end

function sw.get_2d_noise(pos, sides2D, which)
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