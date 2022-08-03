
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

mapgen.generate_dry_shrubs = function(minp, maxp, seed)
	-- Don't generate underground, don't generate in highlands.
	if maxp.y < -50 or minp.y > 50 then
		return
	end


	local pr = PseudoRandom(seed + 819423)
	local count = pr:next(1, 20)
	for j=1, count, 1 do
		local xz = {x=pr:next(minp.x, maxp.x), z=pr:next(minp.z, maxp.z)}
		local pos, posb = find_surface(xz, minp.y, maxp.y)
		if pos then
			local name = "default:dry_shrub"
			if math.random(1, 2) == 1 then
				name = "default:dry_shrub2"
			end
			minetest.set_node(pos, {name=name})

			if pr:next(1, 20) == 1 then
				minetest.set_node(posb, {name="default:mossycobble"})
			else
				minetest.set_node(posb, {name="default:cobble"})
			end
		end
	end
end
