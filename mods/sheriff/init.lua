
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

	sheriff.random_hit(player)

	minetest.after(1, function()
		sheriff.random_gloat(pname)
	end)
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

local accidents = {
	{
		func = function(player)
			minetest.chat_send_player(player:get_player_name(), "# Server: Close call!")
		end,
	},
	{
		func = function(player)
			minetest.chat_send_player(player:get_player_name(), "# Server: Poison dart!")
			hb4.delayed_harm({
				name = player:get_player_name(),
				step = 2,
				min = 1,
				max = 1,
				msg = "# Server: Someone was poisoned!",
				poison = true,
			})
		end,
	},
}

-- Called with a player object to actually apply a random punishment.
function sheriff.random_hit(player)
	if #accidents > 0 then
		local act = accidents[math.random(1, #accidents)]
		act.func(player)
	end
end

local gloats = {
	"Oops.",
	"Sorry ....",
	"An accident!",
	"Uhoh.",
	"Accidents happen ....",
	"Help!",
	"No!",
}

-- Called to send a random chat message to a punished player.
function sheriff.random_gloat(pname)
	if #gloats > 0 then
		local msg = gloats[math.random(1, #gloats)]
		minetest.chat_send_player(pname, "# Server: " .. msg)
	end
end

if not sheriff.loaded then
	-- Register reloadable mod.
	local c = "sheriff:core"
	local f = sheriff.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	sheriff.loaded = true
end
