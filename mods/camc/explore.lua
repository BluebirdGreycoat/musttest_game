
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

local function send_region_to_player(player, minp, maxp)
	-- Convert node positions to mapblock positions
	local min_bp = vector.floor(vector.divide(minp, 16))
	local max_bp = vector.floor(vector.divide(maxp, 16))

	-- Send every mapblock in the region
	for x = min_bp.x, max_bp.x do
		for y = min_bp.y, max_bp.y do
			for z = min_bp.z, max_bp.z do
				player:send_mapblock(vector.new(x, y, z))
			end
		end
	end
end

function camc.periodic_explore_update()
	if camc.EXPLORE_ACTIVE ~= 1 then
		return
	end

	local pcam = minetest.get_player_by_name(camc.HAWKCAM_PLAYER)
	if not pcam then
		camc.stop_exploring()
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

	send_region_to_player(pcam, minp, maxp)

	-- Camera will remain where it is if this fails.
	camc.look_at(pos)

	minetest.after(camc.RANDOM_EXPLORE_TIME_SECONDS, function() camc.periodic_explore_update() end)
	return true
end

function camc.start_exploring()
	camc.EXPLORE_ACTIVE = 1
	return camc.periodic_explore_update()
end

function camc.stop_exploring()
	camc.EXPLORE_ACTIVE = 0
end
