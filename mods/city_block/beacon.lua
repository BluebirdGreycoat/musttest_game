
city_block.beacons = city_block.beacons or {}

local vector_round = vector.round
local vector_distance = vector.distance
local vector_equals = vector.equals
local vector_offset = vector.offset

local BEACONS = city_block.beacons
local BEACON_UPDATE_TIME = 1
local BEACON_DISTANCE = 1024



local function get_nearby_beacons(pos)
	pos = vector_round(pos)
	local realm = rc.current_realm_at_pos(pos)
	local blocks = city_block.blocks
	local t = {}

	for k = 1, #blocks do
		local b = blocks[k]
		if b.hud_beacon then
			local vpos = b.pos
			if vector_distance(pos, vpos) < BEACON_DISTANCE then
				if rc.current_realm_at_pos(vpos) == realm then
					t[#t + 1] = b
				end
			end
		end
	end

	return t
end

local function update_player(pname)
	local pref = minetest.get_player_by_name(pname)
	if pref then
		local pos = vector_round(pref:get_pos())
		local realm = rc.current_realm_at_pos(pos)
		local data = BEACONS[pname]
		local beacons = get_nearby_beacons(pref:get_pos())
		local t = {}

		-- Remove beacons which are now out of range.
		for k = 1, #data do
			if vector_distance(data[k].pos, pos) < BEACON_DISTANCE
				 and data[k].realm == realm then
				t[#t + 1] = data[k]
			else
				pref:hud_remove(data[k].id)
			end
		end

		local function exists(pos)
			for k = 1, #t do
				if vector_equals(t[k].pos, pos) then
					return true
				end
			end
		end

		-- Add beacons which have come into range.
		for k = 1, #beacons do
			local b = beacons[k]
			if vector_distance(b.pos, pos) < BEACON_DISTANCE then
				if not exists(b.pos) then
					local area_name = "Unknown Signal"
					if b.area_name and b.area_name ~= "" then
						area_name = b.area_name
					end
					local hud = {
						id = pref:hud_add({
							type = "waypoint",
							name = area_name,
							number = 0XFF9A33,
							world_pos = vector_offset(b.pos, 0, 1, 0),
							precision = 0,
						}),
						pos = b.pos,
						realm = rc.current_realm_at_pos(b.pos),
					}
					t[#t + 1] = hud
				end
			end
		end

		-- Assign new set of beacons to player.
		BEACONS[pname] = t
	end
end

local function disable_player(pname)
	local pref = minetest.get_player_by_name(pname)
	if pref then
		local data = BEACONS[pname]
		if data then
			for k = 1, #data do
				pref:hud_remove(data[k].id)
			end
		end
	end
	BEACONS[pname] = nil
end

local function enable_player(pname)
	local pref = minetest.get_player_by_name(pname)
	if pref then
		local beacons = get_nearby_beacons(pref:get_pos())
		local data = {}
		for k = 1, #beacons do
			local b = beacons[k]
			local area_name = "Unknown Signal"
			if b.area_name and b.area_name ~= "" then
				area_name = b.area_name
			end
			local hud = {
				id = pref:hud_add({
					type = "waypoint",
					name = area_name,
					number = 0XFF9A33,
					world_pos = vector_offset(b.pos, 0, 1, 0),
					precision = 0,
				}),
				pos = b.pos,
				realm = rc.current_realm_at_pos(b.pos),
			}
			data[#data + 1] = hud
		end
		BEACONS[pname] = data
	end
end



function city_block.on_teleport()
	city_block.really_update_beacons()
end

function city_block.really_update_beacons()
	local players = minetest.get_connected_players()

	for k = 1, #players do
		local pname = players[k]:get_player_name()
		local wield = players[k]:get_wielded_item()

		local iskey = (wield:get_name() == "passport:passport_adv")

		if BEACONS[pname] then
			if iskey then
				update_player(pname)
			else
				disable_player(pname)
			end
		else
			if iskey then
				enable_player(pname)
			end
		end
	end
end

function city_block.update_beacons()
	city_block.really_update_beacons()

	-- Do this again soon.
	minetest.after(BEACON_UPDATE_TIME, function()
		city_block.update_beacons()
	end)
end

-- Called when a player leaves the game.
function city_block.disable_beacons_for_player(pname)
	disable_player(pname)
end
