
sheriff = sheriff or {}
sheriff.modpath = minetest.get_modpath("sheriff")
sheriff.players = sheriff.players or {}

-- Get mod storage if not done already.
if not sheriff.storage then
	sheriff.storage = minetest.get_mod_storage()
end

-- Let other mods query whether a give player is a registered cheater.
function sheriff.player_punished(pname)
	local data = sheriff.players[pname]
	if data then
		if data.is_cheater then
			return true
		end
	else
		-- Not in cache, load from mod storage.
		local s = sheriff.storage:get_string(pname)
		if s and s ~= "" then
			local d = minetest.deserialize(s)
			if d then
				sheriff.players[pname] = d
				if d.is_cheater then
					return true
				end
			end
		end
	end
end

-- Call to register a player as a cheater.
function sheriff.register_cheater(pname)
	local data = {
		is_cheater = true,
	}
	local s = minetest.serialize(data)
	sheriff.storage:set_string(pname, s)

	-- Also add it to the cache.
	sheriff.players[pname] = data
end

-- Can be called by mods to check if player should be punished *this time*.
function sheriff.punish_probability(pname)
	if math.random(1, 100) == 1 then
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
			local pname = player:get_player_name()
			minetest.after(2, function()
				minetest.chat_send_player(pname, "# Server: Close call!")
			end)
		end,
	},
	{
		func = function(player)
			minetest.chat_send_player(player:get_player_name(), "# Server: Poison dart!")
			hb4.delayed_harm({
				name = player:get_player_name(),
				step = 10,
				min = 1,
				max = math.random(1, 2),
				msg = "# Server: Someone got poisoned!",
				poison = true,
			})
		end,
	},
	{
		func = function(player)
			tnt.boom(vector.round(player:get_pos()), {
				radius = 2,
				ignore_protection = false,
				ignore_on_blast = false,
				damage_radius = 3,
				disable_drops = true,
			})
		end,
	},
	{
		func = function(player)
			local pname = player:get_player_name()
			local inv = player:get_inventory()
			local sz = inv:get_size("main")
			local pos = math.random(1, sz)
			local stack = inv:get_stack("main", pos)
			if not stack:is_empty() and not passport.is_passport(stack:get_name()) then
				minetest.chat_send_player(pname, "# Server: Pick-pocket!")
				stack:take_item(stack:get_count())
				inv:set_stack("main", pos, stack)
			else
				minetest.after(2, function()
					minetest.chat_send_player(pname, "# Server: Close call!")
				end)
			end
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

	minetest.register_chatcommand("register_cheater", {
		params = "[name]",
		description = "Register the named player as a confirmed cheater.",
		privs = {server=true},
		func = function(pname, param)
			param = param:trim()
			if param and param ~= "" then
				param = rename.grn(param)
				if minetest.player_exists(param) then
					sheriff.register_cheater(param)
					minetest.chat_send_player(pname, "# Server: Player <" .. rename.gpn(param) .. "> has been registered as a cheater.")
				else
					minetest.chat_send_player(pname, "# Server: Named player does not exist.")
				end
			else
				minetest.chat_send_player(pname, "# Server: You must provide the name of a player.")
			end
			return true
		end,
	})

	sheriff.loaded = true
end
