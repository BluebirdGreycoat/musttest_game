
hb4 = hb4 or {}
hb4.leafscatter = hb4.leafscatter or {}

hb4.leafscatter.remove = function(pos, minp, maxp, leaf, chance)
	local sminp = {x=pos.x+minp.x, y=pos.y+minp.y, z=pos.z+minp.z}
	local smaxp = {x=pos.x+maxp.x, y=pos.y+maxp.y+1, z=pos.z+maxp.z}
	local ominp, omaxp = utility.sort_positions(sminp, smaxp)

	local random = math.random
	local getn = minetest.get_node
	local rmnode = minetest.remove_node

	for x = ominp.x, omaxp.x, 1 do
		for z = ominp.z, omaxp.z, 1 do
			for y = ominp.y, omaxp.y, 1 do
				if random(1, chance) == 1 then
					local pp = {x=x, y=y, z=z}
					local nn = getn(pp).name
					if nn == leaf then
						rmnode(pp)
					end
				end
			end
		end
	end

end

hb4.leafscatter.add = function(pos, minp, maxp, leaf, chance)
	local sminp = {x=pos.x+minp.x, y=pos.y+minp.y, z=pos.z+minp.z}
	local smaxp = {x=pos.x+maxp.x, y=pos.y+maxp.y+1, z=pos.z+maxp.z}
	local ominp, omaxp = utility.sort_positions(sminp, smaxp)

	local random = math.random
	local getn = minetest.get_node
	local setn = minetest.add_node

	local leafnear = function(p)
		local p_ = {
			{x=p.x-1, y=p.y, z=p.z},
			{x=p.x+1, y=p.y, z=p.z},
			{x=p.x, y=p.y-1, z=p.z},
			{x=p.x, y=p.y+1, z=p.z},
			{x=p.x, y=p.y, z=p.z-1},
			{x=p.x, y=p.y, z=p.z+1},
		}
		for k, v in ipairs(p_) do
			if getn(v).name == leaf then
				return true
			end
		end
	end

	for x = ominp.x, omaxp.x, 1 do
		for z = ominp.z, omaxp.z, 1 do
			for y = ominp.y, omaxp.y, 1 do
				if random(1, chance) == 1 then
					local pp = {x=x, y=y, z=z}
					local nn = getn(pp).name
					if nn == "air" then
						if leafnear(pp) then
							setn(pp, {name=leaf})
						end
					end
				end
			end
		end
	end
end
