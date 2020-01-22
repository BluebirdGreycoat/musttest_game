
afk_removal = afk_removal or {}
afk_removal.players = afk_removal.players or {}
afk_removal.modpath = minetest.get_modpath("afk_removal")
afk_removal.steptime = 5
afk_removal.timeout = 60 * 10
afk_removal.warntime = 60 * 9



-- Public API function.
-- This should be called from any mod that wishes to reset the kick timeout for a player.
-- For example, a chat mod may call this when a player chats.
afk_removal.reset_timeout = function(name)
    -- Ensure an entry exists for this name.
    if not afk_removal.players[name] then
        afk_removal.players[name] = {time=0, pos={x=0, y=0, z=0}}
    end
    afk_removal.players[name].time = 0
		afk_removal.players[name].afk = nil
end



function afk_removal.on_joinplayer(player)
	local name = player:get_player_name()
	afk_removal.players[name] = {time=0, pos={x=0, y=0, z=0}}
end

function afk_removal.on_leaveplayer(player, timedout)
	local pname = player:get_player_name()
	afk_removal.players[pname] = nil
end



-- API function to query whether a player is currently AFK.
-- Note that this only has meaning for registered players.
-- Unregistered players are kicked, so you generally won't encounter those.
function afk_removal.is_afk(pname)
	local p = afk_removal.players
	local o = p[pname]
	if o then
		if o.afk then
			return true
		end
	end
	return false
end






afk_removal.update = function()
  local allplayers = minetest.get_connected_players()
  for k, player in ipairs(allplayers) do
    local name = player:get_player_name()
    
    if not minetest.check_player_privs(name, {canafk=true}) then
      local pos = vector.round(player:getpos())
      local dist = vector.distance(pos, afk_removal.players[name].pos)
      if dist > 0.5 then
        afk_removal.players[name].pos = pos
        afk_removal.players[name].time = 0
				afk_removal.players[name].afk = nil
      else
        local time = afk_removal.players[name].time
        time = time + afk_removal.steptime
        afk_removal.players[name].time = time
        
        if time >= afk_removal.warntime then
					if player:get_hp() > 0 and passport.player_registered(name) then -- Only ignore players who are registered and NOT dead.
						-- If player is registered, ignore them.
						afk_removal.players[name].pos = pos
						afk_removal.players[name].time = 0
						afk_removal.players[name].afk = true
					else
						local remain = afk_removal.timeout - time
						minetest.chat_send_player(name, "# Server: You will be kicked for inactivity in " .. math.floor(remain) .. " seconds.")
						easyvend.sound_error(name)
					end
        end
      end
      
      -- Kick players who have done nothing for too long.
      if afk_removal.players[name].time >= afk_removal.timeout then
        afk_removal.players[name] = nil
        minetest.kick_player(name, "Kicked for inactivity.")
				local dname = rename.gpn(name)
        minetest.chat_send_all("# Server: <" .. dname .. "> was kicked for being AFK too long.")
      end
    end -- If player doesn't have 'canafk' priv.
  end
end



local timer = 0
local delay = afk_removal.steptime
function afk_removal.globalstep(dtime)
	timer = timer + dtime
	if timer < delay then return end
	timer = 0
	afk_removal.update()
end



function afk_removal.on_craft(itemstack, player, old_craft_grid, craft_inv)
	if not player then return end
	if not player:is_player() then return end
	
	-- Ensure this player has an entry in the table.
	local name = player:get_player_name()
	if not afk_removal.players[name] then
			afk_removal.players[name] = {time=0, pos={x=0, y=0, z=0}}
	end
	
	afk_removal.players[name].time = 0
end


if not afk_removal.registered then
	-- Crafting resets the player's AFK timeout.
	minetest.register_on_craft(function(...)
		return afk_removal.on_craft(...)
	end)
	
	minetest.register_globalstep(function(...)
		return afk_removal.globalstep(...)
	end)

	minetest.register_privilege("canafk", {
		description = "Player can remain AFK without being kicked.", 
		give_to_singleplayer = false,
	})

	minetest.register_on_joinplayer(function(...)
		return afk_removal.on_joinplayer(...)
	end)

	minetest.register_on_leaveplayer(function(...)
		return afk_removal.on_leaveplayer(...)
	end)

	local c = "afk_removal:core"
	local f = afk_removal.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	afk_removal.registered = true
end


