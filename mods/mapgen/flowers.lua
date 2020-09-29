
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

local flowers_list = {
	'flowers:rose',
        'flowers:rose_white',
        'flowers:zinnia_red',
	'flowers:tulip',
	'flowers:dandelion_yellow',
	'flowers:chrysanthemum_green',
	'flowers:geranium',
	'flowers:viola',
        "flowers:lupine_purple",
	'flowers:dandelion_white',
	'flowers:tulip_black',
	"flowers:delphinium",
	"flowers:lupine_blue",
	"flowers:thistle",
	"flowers:lazarus",
	"flowers:mannagrass",
}

local chose_flower = function(pr, pos)
	if flowers and flowers.datas then -- Only if flowers mod exists.
		local which = pr:next(1, #flowers_list)
		local name = flowers_list[which]
		minetest.set_node(pos, {name=name})
	end
end

mapgen.generate_flowers = function(minp, maxp, seed)
	-- Don't generate underground, don't generate in highlands.
	if maxp.y < -50 or minp.y > 300 then
		return
	end


	local pr = PseudoRandom(seed + 1892)
	local count = pr:next(1, 3)

	-- 1 in 3 chance per mapchunk.
	if count == 1 then
		local xz = {x=pr:next(minp.x, maxp.x), z=pr:next(minp.z, maxp.z)}
		local pos, posb = find_surface(xz, minp.y, maxp.y)

		-- Highlands only.
		if pos then
			if pos.y < 40 then return end

			chose_flower(pr, pos)

			-- Natural-grown flowers always appear on mossy cobble.
			--minetest.chat_send_player("MustTest", "# Server: Placed flower @ " .. rc.pos_to_namestr(pos) .. "!")
			minetest.set_node(posb, {name="default:mossycobble"})
		end
	end
end
