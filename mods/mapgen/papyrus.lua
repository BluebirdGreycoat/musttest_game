
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

mapgen.generate_papyrus = function(minp, maxp, seed)
	-- Don't generate underground, don't generate in highlands.
	if maxp.y < -50 or minp.y > 300 then
		return
	end


	local pr = PseudoRandom(seed + 1596)
	local count = pr:next(1, 10)

	-- 1 in 10 chance per mapchunk.
	if count == 1 then
		local xz = {x=pr:next(minp.x, maxp.x), z=pr:next(minp.z, maxp.z)}
		local pos, posb = find_surface(xz, minp.y, maxp.y)

		-- Highlands only.
		if pos then
			if pos.y < 40 then return end
			minetest.set_node(pos, {name="default:papyrus"})
			minetest.set_node(posb, {name="default:mossycobble"})
		end
	end
end







