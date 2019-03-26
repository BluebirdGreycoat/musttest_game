
sheriff = sheriff or {}
sheriff.modpath = minetest.get_modpath("sheriff")

-- Table of playernames under punishment.
local players = {}

players["MustTest"] = {}

-- Let other mods query whether a give player is being punished.
function sheriff.player_punished(pname)
	if players[pname] then
		return true
	end
end

-- Can be called by mods to check if player should be punished *this time*.
function sheriff.punish_probability(pname)
	if math.random(1, 4) == 1 then
		return true
	end
end

-- May be called by mods to execute a random punishment on a player.
-- This may be called from `minetest.after`, etc.
function sheriff.punish_player(pname)
	-- Check that player actually exists and is logged in.
	local player = minetest.get_player_by_name(pname)
	if not player then
		return
	end

	minetest.chat_send_player(pname, "# Server: Oops!")
end

--[[
	-- Usage is as follows:
	if sheriff.player_punished(name) then
		if sheriff.punish_probability(name) then
			sheriff.punish_player(name)

			-- May possibly need to do `return` here, to abort other operations.
			-- Depends on context.
			return
		end
	end
--]]

if not sheriff.loaded then
	-- Register reloadable mod.
	local c = "sheriff:core"
	local f = sheriff.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	sheriff.loaded = true
end
