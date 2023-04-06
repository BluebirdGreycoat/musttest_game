
if not minetest.global_exists("basictrees") then basictrees = {} end

local find_surface = function(xz, b, t)
	for j=t, b, -1 do
		local pos = {x=xz.x, y=j, z=xz.z}
		local n = minetest.get_node(pos).name
		if snow.is_snow(n) then
			local pb = {x=pos.x, y=pos.y-1, z=pos.z}
			local nb = minetest.get_node(pb).name
			if nb == "default:stone" then
				return pos, pb -- Position, position below.
			else
				break
			end
		elseif n == "default:stone" then
			break
		end
	end
end



local sapling_list = {
	'basictrees:acacia_sapling',
	'basictrees:aspen_sapling',
	'basictrees:jungletree_sapling',
	'basictrees:pine_sapling',
	'basictrees:tree_sapling',
}



local chose_sapling = function(pr, pos)
	local which = pr:next(1, #sapling_list)
	local name = sapling_list[which]
	minetest.set_node(pos, {name=name})
end

basictrees.generate_flowers = function(minp, maxp, seed)
	if maxp.y < -50 or minp.y > 300 then
		return
	end

	local pr = PseudoRandom(seed + 18923)
	local count = pr:next(1, 4)
	if count == 1 then
		local xz = {x=pr:next(minp.x, maxp.x), z=pr:next(minp.z, maxp.z)}
		local pos, posb = find_surface(xz, minp.y, maxp.y)

		-- Highlands only.
		if pos then
			if pos.y < 10 then return end
			chose_sapling(pr, pos)
			minetest.set_node(posb, {name="default:mossycobble"})
		end
	end
end



-- Register mapgen once only. Function is reloadable.
if not basictrees.mapgen_registered then
	minetest.register_on_generated(function(minp, maxp, seed)
		basictrees.generate_flowers(minp, maxp, seed) end)
	basictrees.mapgen_registered = true
end


