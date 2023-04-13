
-- Anticheat module.
-- This file is reloadable.
if not minetest.global_exists("gdac") then gdac = {} end
gdac.session_violations = gdac.session_violations or {}
gdac.modpath = minetest.get_modpath("gdac")

-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round
local math_random = math.random



dofile(gdac.modpath .. "/position_logger.lua")
dofile(gdac.modpath .. "/anti_servspam.lua")
dofile(gdac.modpath .. "/autokick.lua")



function gdac.player_is_admin(playerorname)
	if minetest.is_singleplayer() then
		return false
	end

	--do return false end

	local pref = playerorname
	if type(pref) == "string" then
		pref = minetest.get_player_by_name(pref)
	end
	if pref then
		return minetest.check_player_privs(pref, {server=true})
	end
end



-- Per-player data.
gdac.players = gdac.players or {}



-- Settings. These can only be changed before startup.
-- Note: all disabled due to performance issues! Revealed by profiling. Do NOT enable.
gdac.cheats_logfile = "cheats.txt"
gdac.detect_mining_hacks = false
gdac.block_mining_hacks = false
gdac.detect_long_range_interact = false -- This has too many false positives.
gdac.detect_fly = false
gdac.detect_clip = false



-- Settings. These can be changed after startup.
gdac.name_of_admin = "MustTest"
gdac.interact_range_limit = 6.5
gdac.fly_timeout_min = 8
gdac.fly_timeout_max = 32
gdac.clip_timeout_min = 8
gdac.clip_timeout_max = 32



-- Logging function.
gdac.log = function(message)
	if gdac.logfile then
	gdac.logfile:write(message .. "\r\n")
	gdac.logfile:flush()
	end
	local admin = minetest.get_player_by_name(gdac.name_of_admin)
	if admin and admin:is_player() then
		minetest.chat_send_player(gdac.name_of_admin, "# Server: " .. message)
	end
end



gdac.add_session_violation = function(name)
	-- "Table index is nil" means nil name was passed to this function.
	if gdac.session_violations[name] == nil then gdac.session_violations[name] = 0 end
	gdac.session_violations[name] = gdac.session_violations[name] + 1
end



local floor = math.floor
local round = function(num)
	local digits = 1
	local shift = 10 ^ digits
	return floor(num * shift + 0.5 ) / shift
end



-- This function is responsible for checking if the digger is hacking.
gdac.check_mined_invisible = function(pos, nodename, digger)
	-- What do we do if a non-player dug something? Probably a bug elsewhere in the code!
	if not digger or not digger:is_player() then return false end

	local pt = {x=pos.x, y=pos.y+1, z=pos.z}
	local pb = {x=pos.x, y=pos.y-1, z=pos.z}
	local p1 = {x=pos.x+1, y=pos.y, z=pos.z}
	local p2 = {x=pos.x-1, y=pos.y, z=pos.z}
	local p3 = {x=pos.x, y=pos.y, z=pos.z+1}
	local p4 = {x=pos.x, y=pos.y, z=pos.z-1}

	if minetest.get_node(pt).name == 'air' or
		minetest.get_node(pb).name == 'air' or
		minetest.get_node(p1).name == 'air' or
		minetest.get_node(p2).name == 'air' or
		minetest.get_node(p3).name == 'air' or
		minetest.get_node(p4).name == 'air' then
		return true -- The block was visible, so mining it was legal.
	else
		local nodes = {
			minetest.get_node(pt).name,
			minetest.get_node(pb).name,
			minetest.get_node(p1).name,
			minetest.get_node(p2).name,
			minetest.get_node(p3).name,
			minetest.get_node(p4).name,
		}

		-- Block dug is surrounded on all sides by non-air nodes. But check if any of
		-- these nodes are actually not full blocks.
		for k, v in pairs(nodes) do
			local vt = minetest.reg_ns_nodes[v]
			if not vt then
				-- Either a stairs node, or unknown/ignore.
				return true
			end
			if vt then
				if not vt.walkable or vt.climbable then
					return true -- Could be ladder, torch, etc.
				end
				if vt.drawtype and vt.drawtype ~= "normal" then
					return true -- Probably not a full block.
				end
			end
		end

		-- LOL wut? Mining a block that can't possibly be seen!
		local pname = digger:get_player_name()

		gdac.add_session_violation(pname)
		gdac.log("Almost certainly a cheater: <" .. pname ..
			"> dug '" .. nodename .. "' at (" .. pos.x .. "," .. pos.y .. "," .. pos.z ..
			"), which was NOT EXPOSED. SV: " ..
			gdac.session_violations[pname] .. ".")
		return false -- Can't dig.
	end
end



local check_fly = function(pos)
	if minetest.get_node(vector.add(pos, {x=0, y=-1, z=0})).name ~= "air" then
		return false
	end

	--local p = vector_round(pos)
	-- Check up to 2 meters below player, and 1 meter all around.
	-- Fly cheaters tend to be pretty blatent in their cheating,
	-- and I want to avoid logging players who do a lot of jumping.
	local minp = {x=pos.x-1, y=pos.y-2, z=pos.z-1}
	local maxp = {x=pos.x+1, y=pos.y+0, z=pos.z+1}

	local tb = minetest.find_nodes_in_area(minp, maxp, "air")
	if #tb >= 27 then
		-- If all nodes under player are air, then player is not supported.
		return true
	end

	return false
end



local check_fly_again
check_fly_again = function(name, old_pos)
	local player = minetest.get_player_by_name(name)
	if player and player:is_player() then
		if player:get_hp() <= 0 then return end -- Player is dead!
		local new_pos = player:get_pos()
		local still_cheating = check_fly(new_pos)
		if still_cheating == true then
			local y1 = new_pos.y
			local y2 = old_pos.y
			local d = y2 - y1
			if d < 0.1 then -- If distance is negative or *close to it* then player probably is not falling.
				-- If player hasn't moved they may have just glitched accidentally.
				if vector_distance(new_pos, old_pos) > 0.5 then
					gdac.add_session_violation(name)
					gdac.log("Possible flier? <" .. name ..
						"> caught flying at " .. minetest.pos_to_string(vector_round(new_pos)) .. ". SV: " ..
						gdac.session_violations[name] .. ".")
				end

				-- Still cheating? Check again. This will cause log spam if player cheats continuously, so will be more visible.
				minetest.after(1, check_fly_again, name, new_pos)
			end
		end
	end
end



gdac.antifly_globalstep = function(dtime)
	local players = minetest.get_connected_players()
	for k, v in ipairs(players) do
		if not minetest.check_player_privs(v, {fly=true}) and
				v:get_hp() > 0 then -- Dead players tend to trigger this.
			local name = v:get_player_name()
			local data = gdac.players[name]
			assert(data ~= nil)
			local check = false -- Do we need to check?
			local cheat = false -- Have we detected a possible cheat?

			-- Check timer and timeout.
			local flytimer = data.flytimer
			local flytimeout = data.flytimeout
			flytimer = flytimer + dtime
			if flytimer > flytimeout then
				flytimer = 0
				-- Random time to next check so that it cannot be predicted.
				flytimeout = math_random(gdac.fly_timeout_min, gdac.fly_timeout_max)
				check = true
			end
			data.flytimer = flytimer
			data.flytimeout = flytimeout

			-- Check for flying.
			if check == true then
				cheat = check_fly(v:get_pos())
			end

			if cheat == true then
				-- If cheat detected, check again after a short delay in order to confirm.
				minetest.after(1, check_fly_again, name, v:get_pos())
			end
		end -- If player does not have fly priv.
	end
end



local check_drawtype = function(drawtype)
	if drawtype == "normal" then
		return true
	elseif drawtype == "glasslike" then
		return true
	elseif drawtype == "glasslike_framed" then
		return true
	elseif drawtype == "glasslike_framed_optional" then
		return true
	elseif drawtype == "allfaces" then
		return true
	elseif drawtype == "allfaces_optional" then
		return true
	end
end



local check_clip = function(pos)
	local p = vector_round(pos)
	local p1 = {x=p.x, y=p.y,   z=p.z}
	local p2 = {x=p.x, y=p.y+1, z=p.z}

	local n1 = minetest.get_node(p1).name
	local n2 = minetest.get_node(p2).name
	if n1 ~= "air" and n2 ~= "air" then
		local d1 = minetest.registered_nodes[n1]
		local d2 = minetest.registered_nodes[n2]

		local b1 = (d1.walkable == true and check_drawtype(d1.drawtype))
		local b2 = (d2.walkable == true and check_drawtype(d2.drawtype))

		if b1 and b2 then
			return true
		end
	end

	return false
end



local check_clip_again
check_clip_again = function(name, old_pos)
	local player = minetest.get_player_by_name(name)
	if player and player:is_player() then
		if player:get_hp() <= 0 then return end -- Player is dead!
		local new_pos = player:get_pos()
		local still_cheating = check_clip(new_pos)
		if still_cheating == true then
			-- If player hasn't moved they may have just glitched accidentally.
			if vector_distance(new_pos, old_pos) > 0.5 then
				gdac.add_session_violation(name)
				gdac.log("Possible noclipper? <" .. name ..
					"> caught inside \"" .. minetest.get_node(new_pos).name .. "\" at " .. minetest.pos_to_string(vector_round(new_pos)) .. ". SV: " ..
					gdac.session_violations[name] .. ".")
			end

			-- Still cheating? Check again. This will cause log spam if player cheats continuously, so will be more visible.
			minetest.after(1, check_clip_again, name, new_pos)
		end
	end
end



gdac.anticlip_globalstep = function(dtime)
	local players = minetest.get_connected_players()
	for k, v in ipairs(players) do
		if not minetest.check_player_privs(v, {noclip=true}) and
				v:get_hp() > 0 then -- Dead players tend to trigger this.
			local name = v:get_player_name()
			local data = gdac.players[name]
			assert(data ~= nil)
			local check = false -- Do we need to check?
			local cheat = false -- Have we detected a possible cheat?

			-- Check timer and timeout.
			local cliptimer = data.cliptimer
			local cliptimeout = data.cliptimeout
			cliptimer = cliptimer + dtime
			if cliptimer > cliptimeout then
				cliptimer = 0
				-- Random time to next check so that it cannot be predicted.
				cliptimeout = math_random(gdac.clip_timeout_min, gdac.clip_timeout_max)
				check = true
			end
			data.cliptimer = cliptimer
			data.cliptimeout = cliptimeout

			-- Check for noclipping.
			if check == true then
				cheat = check_clip(v:get_pos())
			end

			if cheat == true then
				-- If cheat detected, check again after a short delay in order to confirm.
				minetest.after(1, check_clip_again, name, v:get_pos())
			end
		end -- If player does not have noclip priv.
	end
end



gdac.check_long_range_interact = function(pos, node, digger, strpart)
	local ppos = digger:get_pos()
	local d = vector_distance(pos, ppos)
	if d > gdac.interact_range_limit then
		local pname = digger:get_player_name()
		local nodename = node.name
		gdac.add_session_violation(pname)
		gdac.log("Possible cheater? <" .. pname ..
			"> " .. strpart .. " '" .. nodename .. "' at " .. minetest.pos_to_string(vector_round(pos)) ..
			"; TOO FAR from player at " .. minetest.pos_to_string(vector_round(ppos)) ..
			". D: " .. round(d) ..  ". SV: " ..
			gdac.session_violations[pname] .. ".")
	end
end



if not gdac.registered then
	-- Install logging file with shutdown handler.
	do
		local path = minetest.get_worldpath() .. "/" .. gdac.cheats_logfile
		gdac.logfile = io.open(path, "a+")
		minetest.register_on_shutdown(function()
			if gdac.logfile then
				gdac.logfile:flush()
				gdac.logfile:close()
			end
		end)
	end

	if gdac.detect_mining_hacks then
		-- Helper function to reduce code size.
		local register_mining_hack = function(nodename)
			if gdac.block_mining_hacks then
				-- Log and prevent hack.
				local def = minetest.registered_items[nodename]
				local old_can_dig = def.can_dig
				minetest.override_item(nodename, {
					can_dig = function(pos, digger)
						if old_can_dig then
							old_can_dig(pos, digger)
						end
						return gdac.check_mined_invisible(pos, nodename, digger)
					end,
				})
			else
				-- Log only.
				local def = minetest.registered_items[nodename]
				local old_after_dig_node = def.after_dig_node
				minetest.override_item(nodename, {
					after_dig_node = function(pos, oldnode, oldmeta, digger)
						if old_after_dig_node then
							old_after_dig_node(pos, oldnode, oldmeta, digger)
						end
						return gdac.check_mined_invisible(pos, nodename, digger)
					end,
				})
			end
		end

		if minetest.get_modpath("default") then
			register_mining_hack("default:stone_with_coal")
			register_mining_hack("default:stone_with_mese")
			register_mining_hack("default:stone_with_iron")
			register_mining_hack("default:stone_with_copper")
			register_mining_hack("default:stone_with_gold")
			register_mining_hack("default:mese")
		end

		if minetest.get_modpath("moreores") then
			register_mining_hack("moreores:mineral_mithril")
			register_mining_hack("moreores:mineral_tin")
			register_mining_hack("moreores:mineral_silver")
		end

		if minetest.get_modpath("morerocks") then
			register_mining_hack("morerocks:marble")
			register_mining_hack("morerocks:granite")
			register_mining_hack("morerocks:marble_pink")
			register_mining_hack("morerocks:marble_white")
			register_mining_hack("morerocks:serpentine")
		end

		if minetest.get_modpath("quartz") then
			register_mining_hack("quartz:quartz_ore")
		end

		register_mining_hack("chromium:ore")
		register_mining_hack("zinc:ore")
		register_mining_hack("sulfur:ore")
		register_mining_hack("uranium:ore")
		register_mining_hack("kalite:ore")
		register_mining_hack("akalin:ore")
		register_mining_hack("alatro:ore")
		register_mining_hack("arol:ore")
		register_mining_hack("talinite:ore")
	end

	-- Detect digging at long range.
	local random = math_random
	minetest.register_on_dignode(function(pos, oldnode, digger)
		if not digger or not digger:is_player() then return end

		-- Disabled for performance reasons.
		--if gdac.detect_long_range_interact then
		--  gdac.check_long_range_interact(pos, oldnode, digger, "dug")
		--end

		-- Check advanced falling node logic.
		instability.check_unsupported_around(pos)

		-- Only *sometimes* create dig particles for other players.
		if random(1, 5) == 1 then
			ambiance.particles_on_dig(pos, oldnode)
		end
	end)

	local function node_not_walkable(pos)
		local nn = minetest.get_node(pos).name
		if nn == "air" then return true end
		local def = minetest.registered_nodes[nn]
		if def and not def.walkable then return true end
	end

	minetest.register_on_placenode(function(pos, newnode, digger)
		if not digger or not digger:is_player() then return end

		-- Detect node placement at long range.
		--if gdac.detect_long_range_interact then
		--  gdac.check_long_range_interact(pos, newnode, digger, "placed")
		--end

		local dropped = false
		local control = digger:get_player_control()
		if control.aux1 and node_not_walkable({x=pos.x, y=pos.y-1, z=pos.z}) then
			local ndef = minetest.registered_nodes[newnode.name]
			local groups = ndef.groups or {}
			-- Player may not drop wallmounted nodes, attached nodes, or hanging nodes.
			if ndef.paramtype2 ~= "wallmounted" and (groups.attached_node or 0) == 0 and (groups.hanging_node or 0) == 0 then
				if sfn.drop_node(pos) then
					dropped = true
				end
			end
		end

		if not dropped then
			instability.check_tower(pos, newnode, digger)
			instability.check_single_node(pos)
		end

		if random(1, 5) == 1 then
			ambiance.particles_on_place(pos, newnode)
		end
	end)



	-- Register antifly routines.
	--if gdac.detect_fly then
	--  minetest.register_globalstep(function(...) return gdac.antifly_globalstep(...) end)
	--end

	-- Register anticlip routines.
	--if gdac.detect_clip then
	--  minetest.register_globalstep(function(...) return gdac.anticlip_globalstep(...) end)
	--end



	-- Set up information for new players.
	--minetest.register_on_joinplayer(function(player)
	--  gdac.players[player:get_player_name()] = {
	--    -- Fly data.
	--    flytimer = 0,
	--    flytimeout = math_random(gdac.fly_timeout_min, gdac.fly_timeout_max),
	--
	--    -- Noclip data.
	--    cliptimer = 0,
	--    cliptimeout = math_random(gdac.clip_timeout_min, gdac.clip_timeout_max),
	--  }
	--end)

	-- Reloadable.
	local name = "gdac:core"
	local file = gdac.modpath .. "/init.lua"
	reload.register_file(name, file, false)

	gdac.registered = true
end



