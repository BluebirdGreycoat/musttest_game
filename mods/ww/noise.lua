
ww.perlins = ww.perlins or {}
ww.maps = ww.maps or {}
ww.noises = ww.noises or {}

local maps = ww.maps
local perlins = ww.perlins
local noises = ww.noises

function ww.create_2d_noise(which, data)
	local nk = which .. "_2d"
	noises[nk] = data
end

function ww.create_3d_noise(which, data)
	local nk = which .. "_3d"
	noises[nk] = data
end

function ww.get_2d_noise(pos, sides2D, which)
	local nk = which .. "_2d"
	local mk = which .. "_2d"
	local pk = which .. "_2d"
	local noisedata = noises[nk]
	perlins[pk] = perlins[pk] or minetest.get_perlin_map(noisedata, sides2D)
	maps[mk] = maps[mk] or {}
	perlins[pk]:get_2d_map_flat(pos, maps[mk])
	return maps[mk]
end

function ww.get_3d_noise(pos, sides3D, which)
	local nk = which .. "_3d"
	local mk = which .. "_3d"
	local pk = which .. "_3d"
	local noisedata = noises[nk]
	perlins[pk] = perlins[pk] or minetest.get_perlin_map(noisedata, sides3D)
	maps[mk] = maps[mk] or {}
	perlins[pk]:get_3d_map_flat(pos, maps[mk])
	return maps[mk]
end
