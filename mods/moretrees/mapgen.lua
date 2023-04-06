
if not minetest.global_exists("moretrees") then moretrees = {} end

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
	[1] = 'moretrees:sequoia_sapling',
	[2] = 'moretrees:fir_sapling',
	[3] = 'moretrees:spruce_sapling',
	[4] = 'moretrees:apple_tree_sapling',
	[5] = 'moretrees:beech_sapling',
	[6] = 'moretrees:birch_sapling',
	[7] = 'moretrees:cedar_sapling',
	[8] = 'moretrees:oak_sapling',
	[9] = 'moretrees:palm_sapling',
	[10] = 'moretrees:poplar_sapling',
	[11] = 'moretrees:rubber_tree_sapling',
	[12] = 'moretrees:willow_sapling',
	[13] = 'moretrees:date_palm_sapling',
	[14] = 'moretrees:jungletree_sapling',
}



local chose_sapling = function(pr, pos)
	local which = pr:next(1, 14)
	local name = sapling_list[which]
	minetest.set_node(pos, {name=name})
end

moretrees.generate_flowers = function(minp, maxp, seed)
	if maxp.y < -50 or minp.y > 300 then
		return
	end

	local pr = PseudoRandom(seed + 1892)
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
if not moretrees.mapgen_registered then
	minetest.register_on_generated(function(minp, maxp, seed)
		moretrees.generate_flowers(minp, maxp, seed) end)
	moretrees.mapgen_registered = true
end


