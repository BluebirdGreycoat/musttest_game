
camc.EXPLORE_ACTIVE = camc.EXPLORE_ACTIVE or 0
camc.EXPLORE_MODE = camc.EXPLORE_MODE or 0

local function get_random_spot()
	local valid = {}
	local blocks = city_block.blocks or {}
	local teleports = teleports.teleports or {}

	if camc.EXPLORE_MODE == 0 then
		for k = 1, #blocks, 1 do
			local b = blocks[k]
			if b.hud_beacon and b.pos then
				valid[#valid + 1] = {pos=b.pos}
			end
		end

		for k = 1, #teleports, 1 do
			local b = teleports[k]
			if b.is_recall and b.pos then
				valid[#valid + 1] = {pos=b.pos}
			end
		end
	elseif camc.EXPLORE_MODE == 1 then
		for k = 1, #blocks, 1 do
			local b = blocks[k]
			if b.vantage then
				local v = b.vantage
				if v.pos and v.yaw and v.pitch then
					valid[#valid + 1] = {
						pos = v.pos,
						yaw = v.yaw,
						pitch = v.pitch,
						name = v.name,
						owner = v.creator,
					}
				end
			end
		end
	end

	if #valid > 0 then
		return valid[math.random(1, #valid)]
	end
end

function camc.periodic_explore_update(params)
	if not params then
		params = {}
	end
	if camc.EXPLORE_ACTIVE ~= 1 then
		return
	end

	-- Belt and suspenders method of making sure only one minetest.after()
	-- chain is running at a time.
	if (params.random_key or 1) ~= camc.RANDOM_KEY then
		camc.system_response("MustTest", "Invalid explore chain.")
		return
	end

	local pcam = minetest.get_player_by_name(camc.HAWKCAM_PLAYER)
	if not pcam then
		camc.stop_exploring()
		return
	end

	local data = get_random_spot()
	if data then
		local pos, yaw, pitch = data.pos, data.yaw, data.pitch

		-- Load map so the look at code can find a good spot for the camera.
		local d = 16
		local minp = vector.add(pos, {x=-d, y=-d, z=-d})
		local maxp = vector.add(pos, {x=d, y=d, z=d})
		minetest.load_area(minp, maxp)

		camc.send_region_to_player(pcam, minp, maxp)

		-- Camera will remain where it is if this fails.
		minetest.after(2, function()
			local success = camc.look_at(pos, yaw, pitch)
			if success then
				camc.set_overlay_vantage_text(data)
			end
		end)

		-- Track how many sites we've visited during this run.
		params.sites_visited = (params.sites_visited or 0) + 1

		-- Occasionally toggle between explore and vantage touring.
		if params.sites_visited and params.sites_visited > 0 then
			if params.sites_visited % 20 == 0 then
				if camc.EXPLORE_MODE == 0 then
					camc.EXPLORE_MODE = 1
				else
					camc.EXPLORE_MODE = 0
				end
			end
		end
	end

	minetest.after(camc.RANDOM_EXPLORE_TIME_SECONDS, function()
		camc.periodic_explore_update(params)
	end)
	return true
end

function camc.start_exploring(mode)
	if camc.EXPLORE_ACTIVE == 1 and camc.EXPLORE_MODE == (mode or 0) then
		return true
	end
	local old_active = camc.EXPLORE_ACTIVE
	camc.EXPLORE_ACTIVE = 1
	camc.EXPLORE_MODE = mode or 0
	if old_active == 0 then
		local params = {random_key=math.random(1, 99999)}
		camc.RANDOM_KEY = params.random_key
		return camc.periodic_explore_update(params)
	end
	return true
end

function camc.stop_exploring()
	camc.EXPLORE_ACTIVE = 0
	camc.EXPLORE_MODE = 0
	camc.RANDOM_KEY = 0
end

function camc.is_exploring()
	return camc.EXPLORE_ACTIVE == 1
end
