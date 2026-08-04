
camc.EXPLORE_ACTIVE = camc.EXPLORE_ACTIVE or 0

local function get_random_spot()
	local valid = {}
	local blocks = city_block.blocks or {}
	local teleports = teleports.teleports or {}

	for k = 1, #blocks, 1 do
		local b = blocks[k]
		if b.hud_beacon and b.pos then
			valid[#valid + 1] = b.pos
		end
	end

	for k = 1, #teleports, 1 do
		local b = teleports[k]
		if b.is_recall and b.pos then
			valid[#valid + 1] = b.pos
		end
	end

	if #valid > 0 then
		return valid[math.random(1, #valid)]
	end
end

function camc.periodic_explore_update()
	if camc.EXPLORE_ACTIVE ~= 1 then
		return
	end

	local pos = get_random_spot()
	if not pos then
		camc.stop_exploring()
		return
	end

	-- Load map so the look at code can find a good spot for the camera.
	local d = 16
	local minp = vector.add(pos, {x=-d, y=-d, z=-d})
	local maxp = vector.add(pos, {x=d, y=d, z=d})
	minetest.load_area(minp, maxp)

	-- Camera will remain where it is if this fails.
	camc.look_at(pos)

	minetest.after(camc.RANDOM_EXPLORE_TIME_SECONDS, camc.periodic_explore_update)
	return true
end

function camc.start_exploring()
	camc.EXPLORE_ACTIVE = 1
	return camc.periodic_explore_update()
end

function camc.stop_exploring()
	camc.EXPLORE_ACTIVE = 0
end
