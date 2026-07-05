
local SHOUT_COLOR = core.get_color_escape_sequence("#ff2a00")
local TEAM_COLOR = core.get_color_escape_sequence("#a8ff00")
local WHITE = core.get_color_escape_sequence("#ffffff")



-- Shout a message.
function shout.shout(name, param)
	if #param < 1 then
		minetest.chat_send_player(name, "# Server: No message specified.")
		easyvend.sound_error(name)
		return
	end

	if command_tokens.mute.player_muted(name) then
		minetest.chat_send_player(name, "# Server: You cannot shout while gagged!")
		easyvend.sound_error(name)
		return
	end

	-- If this succeeds, the player was either kicked, or muted and a message about that sent to everyone else.
	if chat_core.check_language(name, param) then return end

	local mk = chat_core.generate_coord_string(name)
	local dname = rename.gpn(name)
	local players = minetest.get_connected_players()

	for _, player in ipairs(players) do
		local target_name = player:get_player_name() or ""
		if not chat_controls.player_ignored_shout(target_name, name) or target_name == name then
			chat_core.alert_player_sound(target_name)
			minetest.chat_send_player(target_name, "<!" .. chat_core.nametag_color .. dname .. WHITE .. mk .. "!> " .. SHOUT_COLOR .. param)
		end
	end

	afk.reset_timeout(name)
	player_labels.on_chat_message(name, param)
	chat_logging.log_public_shout(name, param, mk)
end
