--------------------------------------------------------------------------------
-- Core Chat System for Must Test Survival
-- Author: GoldFireUn
-- License: MIT
--------------------------------------------------------------------------------

chat_core = chat_core or {}
chat_core.modpath = minetest.get_modpath("chat_core")
chat_core.players = chat_core.players or {}


function chat_core.on_joinplayer(player)
	local pname = player:get_player_name()
	chat_core.players[pname] = {
		last_pm_from = "",
	}
end

function chat_core.on_leaveplayer(player, timeout)
	local pname = player:get_player_name()
	chat_core.players[pname] = nil
end

if minetest.get_modpath("reload") then
	local c = "chat_core:core"
	local f = chat_core.modpath .. "/init.lua"
	if not reload.file_registered(c) then
		reload.register_file(c, f, false)
	end
end



local color_green = core.get_color_escape_sequence("#00ff00")
local color_dark_green = core.get_color_escape_sequence("#00d000")
local color_dark_cyan = core.get_color_escape_sequence("#88ffff")
local color_nametag = core.get_color_escape_sequence("#ffd870")
local color_white = core.get_color_escape_sequence("#ffffff")
--local color_cyan = core.get_color_escape_sequence("#00e0ff")
chat_core.nametag_color = color_nametag -- make public to other mods

-- Used in PMs.
local color_magenta = core.get_color_escape_sequence("#ff50ff")
local color_dark_magenta = core.get_color_escape_sequence("#c800c8")



chat_core.rewrite_message = function(chat2)
	-- Prevent players from including zero-bytes or control characters in their chat.
	local sub = string.gsub
	local chat = chat2
	chat = sub(chat, "[%z%c]", "") -- Zero byte & control bytes.
	chat = sub(chat, " +", " ") -- Excess spaces.
	--chat = sub(chat, "[qQ]", "k")
	return chat
end



-- Send regular chat from a player to all other players.
-- This is called by this mod after validation checks pass.
chat_core.send_all = function(from, prename, actname, postname, message, alwaysecho)
	-- `alwaysecho` is true in the case of a /me command.
	-- The client never echoes this command by itself.

	local player = minetest.get_player_by_name(from)
	if not player then
		return
	end
	local ppos = player:get_pos()

	local allplayers = minetest.get_connected_players()
	local mlower = string.lower(message)

	for k, v in ipairs(allplayers) do
		local pname = v:get_player_name()
		local plower = string.lower(rename.gpn(pname))
		local plowero = string.lower(pname)
		local tpos = v:get_pos()

		if pname ~= from then
			local chosen_color = ""
			local should_send = true
			local ignored = false

			-- Execute chat filters. Order is relevant!
			-- Hide chat from players who are too far away (if feature is enabled).
			if chat_controls.player_too_far(pname, from) then
				should_send = false
			end

			-- Whitelisted player chat can be see even if far away.
			if chat_controls.player_whitelisted(pname, from) then
				should_send = true
			end

			-- Ignore list takes precedence over whitelist.
			if chat_controls.player_ignored(pname, from) then
				should_send = false
				ignored = true
			end

			-- Chat from nearby players is highlighted.
			-- Even ignored players may talk if they are close enough.
			if vector.distance(ppos, tpos) < 64 then
				-- Highlight chat from nearby player only if originating player is not invisible.
				if not gdac_invis.is_invisible(from) then
					chosen_color = color_dark_cyan
				end
				should_send = true
			end

			-- Finally, check highlighting filters. But only if not ignored!
			if not ignored then
				if chat_controls.check_highlighting_filters(pname, from, message) then
					chosen_color = color_dark_green
					should_send = true
				end
			end

			if should_send then
				-- Colorize message for players if their name or alt is used.
				-- This overrides any previous coloring.
				if string.find(mlower, plower) or string.find(mlower, plowero) then
					chosen_color = color_green
				end

				-- If /me, use correct color.
				if alwaysecho then
					chosen_color = chat_colorize.COLOR_ORANGE
				end

				-- Finally send the message.
				minetest.chat_send_player(pname, prename .. color_nametag .. actname .. color_white .. postname .. chosen_color .. message)
			end
		else -- Message being echoed back to player that sent it.
			if alwaysecho then
				-- It should be a /me command.
				minetest.chat_send_player(pname, prename .. color_nametag .. actname .. color_white .. postname .. chat_colorize.COLOR_ORANGE .. message)
			else
				-- Send chat to self if echo enabled.
				chat_echo.echo_chat(pname, prename .. color_nametag .. actname .. color_white .. postname .. message)
			end
		end
	end
end



-- Check player's language, and kick them if they are not protected by the PoC.
-- Or, mute them and send a message to other players that they were muted.
-- This function can be called from other mods.
function chat_core.check_language(name, message)
	-- Players with anticurse bypass priv cannot be kicked by this mod.
	local nokick = minetest.check_player_privs(name, {anticurse_bypass=true})
	if nokick then
		if anticurse.check(name, message, "foul") then
			anticurse.log(name, message)
		elseif anticurse.check(name, message, "curse") then
			anticurse.log(name, message)
		end
		return false -- Has bypass.
	end
	if anticurse.check(name, message, "foul") then
		anticurse.log(name, message)
		-- Players who have registered (and therefore have probably played
		-- on the server more than a few days) are warned but not kicked.
		if passport.player_registered(name) then
			local ext = anticurse.get_kick_message("foul")
			minetest.chat_send_all("# Server: Talk from someone hidden in case of uninteresting language.")
			minetest.chat_send_player(name, "# Server: " .. ext)
		else
			anticurse.kick(name, "foul")
		end
		return true -- Blocked.
	elseif anticurse.check(name, message, "curse") then
		anticurse.log(name, message)
		-- Players who have registered (and therefore have probably played
		-- on the server more than a few days) are warned but not kicked.
		if passport.player_registered(name) then
			local ext = anticurse.get_kick_message("curse")
			minetest.chat_send_all("# Server: Talk from someone hidden in case of uninteresting language.")
			minetest.chat_send_player(name, "# Server: " .. ext)
		else
			anticurse.kick(name, "foul")
		end
		return true -- Blocked.
	end
	return false -- Nothing found.
end



local generate_coord_string = function(name)
	local coord_string = ""
	if command_tokens.mark.player_marked(name) then
		local entity = minetest.get_player_by_name(name)
		local pos = entity:get_pos()

		local pstr = rc.pos_to_string(vector.round(pos))
		pstr = string.gsub(pstr, "[%(%)]", "")

		-- remember to include leading space!
		coord_string = " [" .. rc.realm_description_at_pos(pos) .. ": " .. pstr .. "]"
		minetest.chat_send_player(name, "# Server: You are marked (" .. pstr .. ")!")
	end
	return coord_string
end
chat_core.generate_coord_string = generate_coord_string



chat_core.on_chat_message = function(name, message)
	-- Trim input.
	message = string.trim(message)

	if message:sub(1, 1) == "/" then
		minetest.chat_send_player(name, "# Server: Invalid command. See '/help all' for a list of valid commands.")
		easyvend.sound_error(name)
		-- It's a special command, and not one that was registered.
		-- This is actually never called?
		return
	end

	if not minetest.check_player_privs(name, {shout=true}) then
		minetest.chat_send_player(name, "# Server: You do not have 'shout' priv.")
		-- Player doesn't have shout priv.
		return
	end

	local player_muted = false
	if command_tokens.mute.player_muted(name) then
		minetest.chat_send_player(name, "# Server: You are currently gagged.")
		-- Player is muted.
		return
	end

	-- Shouts can be executed by prepending a '!' to your chat.
	if string.find(message, "^!") then
		-- Handled by the shout mod.
		shout.shout(name, string.sub(message, 2))
		return
	end

	-- Check for accidents.
	local pm_pos = string.find(message, "msg")
	if not pm_pos then
		pm_pos = string.find(message, "MSG")
	end
	if not pm_pos then
		pm_pos = string.find(message, "pm")
	end
	if not pm_pos then
		pm_pos = string.find(message, "PM")
	end
	if pm_pos and pm_pos <= 3 then -- Space for 2 symbols.
		minetest.chat_send_player(name,
			"# Server: Did you mean to send a PM? The command format is \"/msg <player> <message>\" (without quotes). Chat not sent.")
		return
	end

	if chat_core.check_language(name, message) then return end
	local coord_string = generate_coord_string(name)

	player_labels.on_chat_message(name, message)
	chat_core.send_all(name, "<", rename.gpn(name), coord_string .. "> ", message)
	chat_logging.log_public_chat(name, message, coord_string)
	afk_removal.reset_timeout(name)
end



chat_core.handle_command_me = function(name, param)
	if not minetest.check_player_privs(name, {shout=true}) then
		minetest.chat_send_player(name, "# Server: You do not have 'shout' priv.")
		return -- Player doesn't have shout priv.
	end

	if command_tokens.mute.player_muted(name) then
		minetest.chat_send_player(name, "# Server: You can't do that while gagged, sorry.")
		return -- Player is muted.
	end

	param = string.trim(param)
	if #param < 1 then
		minetest.chat_send_player(name, "# Server: No action specified.")
		return
	end

	if chat_core.check_language(name, param) then return end
	local coord_string = generate_coord_string(name)

	player_labels.on_chat_message(name, param)
	chat_core.send_all(name, "* <", rename.gpn(name), coord_string .. "> ", param, true)
	chat_logging.log_public_action(name, param, coord_string)
	afk_removal.reset_timeout(name)
end



chat_core.handle_command_msg = function(name, param)
	if not minetest.check_player_privs(name, {shout=true}) then
		minetest.chat_send_player(name, "# Server: You do not have 'shout' priv.")
		easyvend.sound_error(name)
		return -- Player doesn't have shout priv.
	end

	if command_tokens.mute.player_muted(name) then
		minetest.chat_send_player(name, "# Server: You are gagged at the moment.")
		easyvend.sound_error(name)
		return -- Player is muted.
	end

	local coord_string = generate_coord_string(name)

	-- Split command arguments.
	local p = string.find(param, " ")
	local to, newmsg
	if p then
		newmsg = string.trim(param:sub(p+1))
		to = string.trim(param:sub(1, p-1))
	end

	if type(to)=="string" and type(newmsg)=="string" and string.len(newmsg) > 0 and string.len(to) > 0 then
		to = rename.grn(to)

		if gdac_invis.is_invisible(to) and to ~= name then -- If target is invisible, and player sending is not same as target ...
			if chat_core.players[name] and (chat_core.players[name].last_pm_from or "") ~= to then -- Do not permit, if player did not receive a PM from this target.
				if to == "MustTest" then
					minetest.chat_send_player(name, "# Server: The server admin is not available at this time! If it's important, send mail instead.")
				else
					minetest.chat_send_player(name, "# Server: <" .. rename.gpn(to) .. "> is not available at this time! If it's important, send mail instead.")
				end
				return
			end
		end

		if minetest.get_player_by_name(to) then
			-- Bad words in PMs.
			if chat_core.check_language(name, newmsg) then
				return
			end

			-- Cannot PM player if being ignored.
			if chat_controls.player_ignored_pm(to, name) and to ~= name then
				minetest.chat_send_player(name, "# Server: <" .. rename.gpn(to) .. "> is not available for private messaging!")
				easyvend.sound_error(name)
				return
			end

			minetest.after(0, function()
				minetest.chat_send_player(to, color_magenta .. "# PM: FROM <" .. rename.gpn(name) .. coord_string .. ">: " .. newmsg)
				-- Record name of last player to send this player a PM.
				if chat_core.players[to] then
					chat_core.players[to].last_pm_from = name
				end
			end)
			minetest.chat_send_player(name, color_dark_magenta .. "# PM: TO <" .. rename.gpn(to) .. coord_string .. ">: " .. newmsg)

			chat_logging.log_private_message(name, to, newmsg)
			afk_removal.reset_timeout(name)
		else minetest.chat_send_player(name, "# Server: <" .. rename.gpn(to) .. "> is not online.") end
	else minetest.chat_send_player(name, "# Server: Usage: '/msg <playername> <message>'.") end
end



function chat_core.handle_command_r(name, param)
	local to = chat_core.players[name].last_pm_from or ""

	if to == "" then
		minetest.chat_send_player(name, "# Server: No one has sent you a PM yet that can be replied to. Use /msg instead to specify the player.")
		return
	end

	return chat_core.handle_command_msg(name, to .. " " .. param) -- Prepend target name, and call normal /msg function.
end



if not chat_core.registered then
	minetest.register_chatcommand("me", {
		params = "<action>",
		description = "Send an 'action' message beginning with your name.",
		privs = {shout=true},
		func = function(name, param)
			chat_core.handle_command_me(name, chat_core.rewrite_message(param))
			return true
		end,
	})

	minetest.register_chatcommand("msg", {
		params = "<player> <message>",
		description = "Send a private message to another player.",
		privs = {shout=true},
		func = function(name, param)
			chat_core.handle_command_msg(name, chat_core.rewrite_message(param))
			return true
		end,
	})

	minetest.register_chatcommand("r", {
		params = "<message>",
		description = "Reply via PM to the last player to send you a PM.",
		privs = {shout=true},
		func = function(name, param)
			chat_core.handle_command_r(name, chat_core.rewrite_message(param))
			return true
		end,
	})

	-- This should be the only handler registered. Only one handler can be registered.
	minetest.register_on_chat_message(function(name, message)
		chat_core.on_chat_message(name, chat_core.rewrite_message(message))
		return true -- Don't send message automatically, we already did this.
	end)

	minetest.register_on_joinplayer(function(...) return chat_core.on_joinplayer(...) end)
	minetest.register_on_leaveplayer(function(...) return chat_core.on_leaveplayer(...) end)

	chat_core.registered = true
end


