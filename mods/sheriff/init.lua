
if not minetest.global_exists("sheriff") then sheriff = {} end
sheriff.modpath = minetest.get_modpath("sheriff")
sheriff.players = sheriff.players or {}

-- Localize for performance.
local vector_round = vector.round
local math_random = math.random

-- Get mod storage if not done already.
if not sheriff.storage then
	sheriff.storage = minetest.get_mod_storage()
end

-- Let other mods query whether player *might* be a cheater, based on
-- heuristics.
function sheriff.is_suspected_cheater(pname)
	-- If player is a confirmed cheater then they're a suspected cheater, too.
	if sheriff.is_cheater(pname) then
		return true
	end

	local total_suspicion = ac.get_total_suspicion(pname)
	local clean_sessions = ac.get_clean_sessions(pname)
	if clean_sessions < 1 then clean_sessions = 1 end
	local avg_suspicion = total_suspicion / clean_sessions

	if avg_suspicion >= ac.high_average_suspicion then
		return true
	end
end

-- Let other mods query whether a given player is a registered cheater.
function sheriff.is_cheater(pname)
	local data = sheriff.players[pname]
	if data then
		if data.is_cheater then
			-- Cheater time may be nil (thus 0) if cheater was registered before
			-- times started to be recorded.
			return true, (data.cheater_time or 0)
		end
	else
		-- Not in cache, load from mod storage.
		local s = sheriff.storage:get_string(pname)
		if s and s ~= "" then
			local d = minetest.deserialize(s)
			if d then
				sheriff.players[pname] = d
				if d.is_cheater then
					-- Cheater time may be nil (thus 0) if cheater was registered before
					-- times started to be recorded.
					return true, (d.cheater_time or 0)
				end
			end
		end
	end
end

function sheriff.get_data_or_nil(pname)
	local data = sheriff.players[pname]
	if data then
		return data
	end

	-- Not in cache, load from mod storage.
	local s = sheriff.storage:get_string(pname)
	if s and s ~= "" then
		local d = minetest.deserialize(s)
		if d then
			sheriff.players[pname] = d
			return d
		end
	end
end

-- Call to register a player as a cheater.
function sheriff.register_cheater(pname)
	local data = sheriff.get_data_or_nil(pname) or {}

	-- Record the fact that the player is a cheater (boolean) and time of record.
	data.is_cheater = true
	data.cheater_time = os.time()

	local s = minetest.serialize(data)
	sheriff.storage:set_string(pname, s)

	-- Also add it to the cache.
	sheriff.players[pname] = data

	-- Notify the exile mod.
	exile.notify_new_exile(pname)

	-- Notify the administrator.
	local from = "SERVER"
	local to = gdac.name_of_admin or "singleplayer"
	local subject = "CHEATER REGISTRATION"
	local message = "Player <" .. rename.gpn(pname) ..
		"> was registered as a cheater. Please check the cheat log, and use " ..
		"/unregister_cheater if this was done in error."

	email.send_mail_single(from, to, subject, message)
end

-- Call to unregister a player as a cheater.
function sheriff.unregister_cheater(pname)
	local data = sheriff.get_data_or_nil(pname)
	if data then
		-- Remove from mod storage.
		sheriff.storage:set_string(pname, "")

		-- Remove from cache.
		sheriff.players[pname] = nil
	end

	-- Remove cheat statistics, too.
	ac.erase_statistics(pname)
end

-- Can be called by mods to check if player should be punished *this time*.
function sheriff.punish_probability(pname)
	if math_random(1, 100) == 1 then
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
	if sheriff.is_cheater(name) then
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
				min = 1*500,
				max = math_random(1, 2)*500,
				msg = "# Server: Someone got poisoned!",
				poison = true,
			})
		end,
	},
	{
		func = function(player)
			tnt.boom(vector_round(player:get_pos()), {
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
			local pos = math_random(1, sz)
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
		local act = accidents[math_random(1, #accidents)]
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
		local msg = gloats[math_random(1, #gloats)]
		minetest.chat_send_player(pname, "# Server: " .. msg)
	end
end



function sheriff.command_register_cheater(pname, param)
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
end



function sheriff.command_unregister_cheater(pname, param)
	param = param:trim()
	if param and param ~= "" then
		param = rename.grn(param)
		if minetest.player_exists(param) then
			sheriff.unregister_cheater(param)
			minetest.chat_send_player(pname, "# Server: Player <" .. rename.gpn(param) .. "> is not registered as a cheater.")
		else
			minetest.chat_send_player(pname, "# Server: Named player does not exist.")
		end
	else
		minetest.chat_send_player(pname, "# Server: You must provide the name of a player.")
	end
	return true
end



if not sheriff.loaded then
	-- Register reloadable mod.
	local c = "sheriff:core"
	local f = sheriff.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	minetest.register_chatcommand("register_cheater", {
		params = "[name]",
		description = "Register user as confirmed cheater.",
		privs = {server=true},

		func = function(...)
			return sheriff.command_register_cheater(...)
		end,
	})

	minetest.register_chatcommand("unregister_cheater", {
		params = "[name]",
		description = "Unregister user from being a cheater.",
		privs = {server=true},

		func = function(...)
			return sheriff.command_unregister_cheater(...)
		end,
	})

	sheriff.loaded = true
end
