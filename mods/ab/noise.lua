
ab.perlin_maps = ab.perlin_maps or {}
sw.perlins = sw.perlins or {}
ab.maps = ab.maps or {}
ab.noises = ab.noises or {}

local maps = ab.maps
local perlin_maps = ab.perlin_maps
local perlins = sw.perlins
local noises = ab.noises

function ab.create_2d_noise(which, data)
	local nk = which .. "_2d"
	noises[nk] = data
end

function ab.create_3d_noise(which, data)
	local nk = which .. "_3d"
	noises[nk] = data
end

function ab.get_2d_noise(pos, sides2D, which)
	local nk = which .. "_2d"
	local mk = which .. "_2d"
	local pk = which .. "_2d"
	local noisedata = noises[nk]
	perlin_maps[pk] = perlin_maps[pk] or minetest.get_perlin_map(noisedata, sides2D)
	perlins[pk] = perlins[pk] or minetest.get_perlin(noisedata)
	maps[mk] = maps[mk] or {}
	perlin_maps[pk]:get_2d_map_flat(pos, maps[mk])
	return maps[mk], perlins[pk]
end

function ab.get_3d_noise(pos, sides3D, which)
	local nk = which .. "_3d"
	local mk = which .. "_3d"
	local pk = which .. "_3d"
	local noisedata = noises[nk]
	perlin_maps[pk] = perlin_maps[pk] or minetest.get_perlin_map(noisedata, sides3D)
	perlins[pk] = perlins[pk] or minetest.get_perlin(noisedata)
	maps[mk] = maps[mk] or {}
	perlin_maps[pk]:get_3d_map_flat(pos, maps[mk])
	return maps[mk], perlins[pk]
end
