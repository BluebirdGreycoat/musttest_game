
-- Author: MustTest/BluebirdGreycoat51/GoldFireUn
-- License: MIT

if not minetest.global_exists("bone_mark") then bone_mark = {} end
bone_mark.modpath = minetest.get_modpath("bone_mark")
bone_mark.players = bone_mark.players or {}

local STEP_TIME = 3.5
local BONE_NEAR_DIST = 3
local BONE_FAR_DIST = 100
local CORPSE_MISSING_TIME = 120
local step_timer = 0



function bone_mark.add_corpse(pos, pname)
	bone_mark.players[pname] = bone_mark.players[pname] or {}
	local t = bone_mark.players[pname]
	t[#t + 1] = {
		pos = vector.round(pos),
		shown = false,
		hud = nil,
		remove = false,
		timer = 0,
	}
end



local function keep_mark(t)
	if not t.remove then
		return true
	end
end



function bone_mark.notify_hud_update_needed(pname)
	step_timer = STEP_TIME
	local pdata = bone_mark.players[pname]
	if pdata then
		-- pref should *usually* never be nil, but check for it anyway for edge cases.
		local pref = minetest.get_player_by_name(pname)
		if pref then
			for index, mdata in ipairs(pdata) do
				if mdata.hud then pref:hud_remove(mdata.hud) end
				mdata.hud = nil
				mdata.shown = false
			end
		end
	end
end



function bone_mark.on_globalstep(dtime)
	step_timer = step_timer + dtime
	if step_timer < STEP_TIME then return end
	step_timer = 0

	for pname, pdata in pairs(bone_mark.players) do
		-- pdata is an array.
		for index, mdata in ipairs(pdata) do
			-- pref should never be nil, because we remove player's data from the main
			-- player-table when they leave the game. Check anyway for edge cases.
			local pref = minetest.get_player_by_name(pname)
			if not pref then
				goto continue
			end

			local ppos = pref:get_pos()
			local node = minetest.get_node_or_nil(mdata.pos)
			local message = "Corpse"

			if node and node.name ~= "bones:bones" then
				message = "Corpse Missing"
				mdata.timer = (mdata.timer or 0) + STEP_TIME

				-- Missing bones HUD element timeout.
				if mdata.timer > CORPSE_MISSING_TIME then
					if mdata.hud then pref:hud_remove(mdata.hud) end

					mdata.hud = nil
					mdata.remove = true
				end

				-- Update HUD element right away.
				if not mdata.corpse_gone then
					if mdata.hud then pref:hud_remove(mdata.hud) end
					mdata.hud = nil
					mdata.shown = false
					mdata.corpse_gone = true
				end
			end

			local far_dist = BONE_FAR_DIST
			if passport.player_has_key(pname, pref) then
				far_dist = BONE_FAR_DIST * 10
			end
			local same_realm = rc.same_realm(mdata.pos, ppos)

			if not mdata.remove then
				local dist = vector.distance(ppos, mdata.pos)

				if not mdata.shown then
					if dist > BONE_NEAR_DIST and dist <= far_dist and same_realm then
						-- Show waypoint if player in range.

						-- Just in case, but this probably shouldn't happen.
						if mdata.hud then pref:hud_remove(mdata.hud) end

						-- http://www.shodor.org/~efarrow/trunk/html/rgbint.html
						local number = "6368886"
						local precision = 0

						if passport.player_has_key(pname, pref) then
							precision = 10
						end

						mdata.hud = pref:hud_add({
							type = "waypoint",
							name = message,
							number = number,
							world_pos = mdata.pos,
							precision = precision,
						})

						mdata.shown = true
					end
				elseif mdata.shown then
					-- Hide waypoint when player too far or too near.
					if dist > far_dist or not same_realm then
						if mdata.hud then pref:hud_remove(mdata.hud) end

						mdata.hud = nil
						mdata.shown = false
					elseif dist < BONE_NEAR_DIST and pref:get_hp() > 0 then
						-- Remove waypoint when player near enough and NOT dead.
						-- Need the HP check because otherwise waypoint would be removed
						-- right away if player doesn't press respawn quickly enough.
						if mdata.hud then pref:hud_remove(mdata.hud) end

						mdata.hud = nil
						mdata.remove = true
					end
				end
			end -- If not to be removed.

			::continue::
		end

		-- Get rid of dead ones.
		utility.array_remove(pdata, keep_mark)
	end
end



function bone_mark.on_leaveplayer(pref)
	local pname = pref:get_player_name()

	-- Skip if player doesn't have any corpse marks.
	if not bone_mark.players[pname] then
		return
	end

	local data = {}
	for k, v in ipairs(bone_mark.players[pname]) do
		if not v.remove then
			data[#data + 1] = v.pos
		end
	end

	local serialized = minetest.serialize(data)
	pref:get_meta():set_string("marked_bones", serialized)

	bone_mark.players[pname] = nil
end



-- Because leaveplayer callbacks don't get called if server shuts down while players are connected!
function bone_mark.on_shutdown()
	local players = minetest.get_connected_players()
	for k, v in ipairs(players) do
		bone_mark.on_leaveplayer(v)
	end
end



function bone_mark.on_joinplayer(pref)
	local pname = pref:get_player_name()
	bone_mark.players[pname] = nil

	local pmeta = pref:get_meta()
	local serialized = pmeta:get_string("marked_bones")

	-- Abort if no data.
	if serialized == "" then
		return
	end

	local data = minetest.deserialize(serialized)

	-- Abort if no data.
	if not data then
		return
	end

	-- Re-add player's corpse marks.
	for k, v in ipairs(data) do
		bone_mark.add_corpse(v, pname)
	end
end



if not bone_mark.registered then
	minetest.register_globalstep(function(...)
		return bone_mark.on_globalstep(...)
	end)

	minetest.register_on_joinplayer(function(...)
		return bone_mark.on_joinplayer(...)
	end)

	minetest.register_on_leaveplayer(function(...)
		return bone_mark.on_leaveplayer(...)
	end)

	minetest.register_on_shutdown(function(...)
		return bone_mark.on_shutdown(...)
	end)

	local c = "bone_mark:core"
	local f = bone_mark.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	bone_mark.registered = true
end
