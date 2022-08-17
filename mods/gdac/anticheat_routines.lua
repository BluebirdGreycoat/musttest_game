-- LGPL
--[[

-- DO NOT INCLUDE THIS WITH SOURCES
-- THIS will produce anticheat_routines.bin.

-- instructions:
-- 1. uncomment in init.lua around line 80:
-- dofile(minetest.get_modpath("anticheat").."/anticheat_source.lua")
-- just run server and .bin is generated. Then comment it again.

-- how to use in code(already done):
--	local anticheat_routines=loadfile(minetest.get_modpath("anticheat").."/anticheat_routines.bin")
--	check_noclip, check_fly, check_player = anticheat_routines(minetest,cheat);

-- Localize for performance.
local math_floor = math.floor

local anticheat_routines = function(minetest,cheat, CHECK_AGAIN, punish_cheat)

	-- DETAILED NOCLIP CHECK
	local check_noclip = function(pos)
		local nodename = minetest.get_node(pos).name;
		local clear=true;
		if nodename ~= "air" then  -- check if forbidden material!
			clear = cheat.nodelist[nodename]; -- test clip violation
			if clear == nil then clear = true end
		end

		if not clear then -- more detailed check
			local anodes = minetest.find_nodes_in_area({x=pos.x-1, y=pos.y-1, z=pos.z-1}, {x=pos.x+1, y=pos.y+1, z=pos.z+1}, {"air"});
			if #anodes == 0 then return false end
			clear=true;
		end
		return clear;
	end

	-- DETAILED FLY CHECK
	local check_fly = function(pos) -- return true if player not flying
		local fly = (minetest.get_node(pos).name=="air" and minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z}).name=="air"); -- prerequisite for flying is this to be "air", but not sufficient condition
		if not fly then return true end;

		local anodes = minetest.find_nodes_in_area({x=pos.x-1, y=pos.y-1, z=pos.z-1}, {x=pos.x+1, y=pos.y, z=pos.z+1}, {"air"});
		if #anodes == 18 then -- player standing on air?
			return false
		else
			return true
		end
	end


	local round = function (x)
		if x > 0 then
			return math_floor(x+0.5)
		else
			return -math_floor(-x+0.5)
		end
	end

	--main check routine
	local check_player = function(player)

		local name = player:get_player_name();
		local privs = minetest.get_player_privs(name).kick;if privs then return end -- dont check moderators
		if cheat.watcher[name] then return end -- skip checking watchers while they watch

		local pos = player:get_pos(); -- feet position
		pos.x = round(pos.x*10)/10;pos.z = round(pos.z*10)/10; -- less useless clutter
		pos.y = round(pos.y*10)/10; -- minetest buggy collision - need to do this or it returns wrong materials for feet position: aka magic number 0.498?????228
		if pos.y<0 then pos.y=pos.y+1 end -- weird, without this it fails to check feet block where y<0, it checks one below feet

		local nodename = minetest.get_node(pos).name;
		local clear=true;
		if nodename ~= "air" then  -- check if forbidden material!
			clear = cheat.nodelist[nodename]; -- test clip violation
			if clear == nil then clear = true end
		end

		local fly = (nodename=="air" and minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z}).name=="air"); -- prerequisite for flying, but not sufficient condition

		if cheat.players[name].count == 0 then -- player hasnt "cheated" yet, remember last clear position
			cheat.players[name].clearpos = cheat.players[name].lastpos
		end


		-- manage noclip cheats
		if not clear then -- player caught inside walls
			local moved = (cheat.players[name].lastpos.x~=pos.x) or (cheat.players[name].lastpos.y~=pos.y) or (cheat.players[name].lastpos.z~=pos.z);
			if moved then -- if player stands still whole time do nothing
				if cheat.players[name].count == 0 then cheat.players[name].cheatpos = pos end -- remember first position where player found inside wall


				if cheat.players[name].count == 0 then
					minetest.after(CHECK_AGAIN,
						function()
							cheat.players[name].count = 0;
							if not check_noclip(pos) then
								punish_cheat(name)-- we got a cheater!
							else
								cheat.players[name].count = 0; -- reset
								cheat.players[name].cheattype = 0;
							end
						end
					)
				end

				if cheat.players[name].count == 0 then -- mark as suspect
					cheat.players[name].count = 1;
					cheat.players[name].cheattype = 1;
				end

			end
		end

		-- manage flyers
		if fly then

			local fpos;
			fly,fpos = minetest.line_of_sight(pos, {x = pos.x, y = pos.y - 4, z = pos.z}, 1); --checking node maximal jump height below feet

			if fly then -- so we are in air, are we flying?

				if player:get_player_control().sneak then -- player sneaks, maybe on border?
					--search 18 nodes to find non air
					local anodes = minetest.find_nodes_in_area({x=pos.x-1, y=pos.y-1, z=pos.z-1}, {x=pos.x+1, y=pos.y, z=pos.z+1}, {"air"});
					if #anodes < 18 then fly = false end
				end	-- if at this point fly = true means player is not standing on border

				if pos.y>=cheat.players[name].lastpos.y and fly then -- we actually didnt go down from last time and not on border

					-- was lastpos in air too?
					local lastpos  =  cheat.players[name].lastpos;
					local anodes = minetest.find_nodes_in_area({x=lastpos.x-1, y=lastpos.y-1, z=lastpos.z-1}, {x=lastpos.x+1, y=lastpos.y, z=lastpos.z+1}, {"air"});
					if #anodes == 18 then fly = true else fly = false end

					if fly then -- so now in air above previous position, which was in air too?

						if cheat.players[name].count == 0 then cheat.players[name].cheatpos = pos end -- remember first position where player found "cheating"

						if cheat.players[name].count == 0 then
							minetest.after(CHECK_AGAIN,
								function()
									cheat.players[name].count = 0;
									if not check_fly(pos) then
										punish_cheat(name)-- we got a cheater!
									else
										cheat.players[name].count = 0;
										cheat.players[name].cheattype = 0;
									end
								end
							)
						end

						if cheat.players[name].count == 0 then -- mark as suspect
							cheat.players[name].count = 1;
							cheat.players[name].cheattype = 2;
						end
					end

				end

			end
		end

		cheat.players[name].lastpos = pos
	end

return check_noclip, check_fly, check_player;

end

-- this produces compiled version of source
local out = io.open(minetest.get_modpath("anticheat").."\\anticheat_routines.bin", "wb");
local s = string.dump(anticheat_routines);
out:write(s);
out:close()
--]]
