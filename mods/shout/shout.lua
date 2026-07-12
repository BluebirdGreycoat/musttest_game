
local SHOUT_COLOR = core.get_color_escape_sequence("#ff2a00")
local TEAM_COLOR = core.get_color_escape_sequence("#a8ff00")
local WHITE = core.get_color_escape_sequence("#ffffff")

local GAG_MESSAGES = {
	"You cannot shout while gagged!",
	"Your shout is muffled by the gag.",
	"No sound escapes the duct-tape.",
	"You've been gagged.",
	"Shouting is impossible right now.",
	"Somebody gagged you. Can't shout.",
	"You can't shout.",
	"You are currently gagged.","Your voice is muffled by the gag.",
	"The gag prevents any shouting.",
	"You try to shout but only muffled sounds come out.",
	"Duct tape keeps your mouth shut tight.",
	"No shouting allowed while gagged.",
	"Your shout is blocked by the gag.",
	"The gag has silenced you.",
	"Mmph! You can't shout right now.",
	"Your mouth is taped closed.",
	"Shouting is impossible with a gag on.",
	"The duct tape muffles your voice completely.",
	"You've been silenced by the gag.",
	"Your attempt to shout fails due to the gag.",
	"Gag in effect: no shouting.",
	"Your voice can't escape the gag.",
	"The gag absorbs your shout.",
	"You mumble helplessly instead.",
	"Somebody taped your mouth shut.",
	"Shout canceled by gag.",
	"Your vocal cords are currently gagged.",
	"The gag says 'quiet!'",
	"You can't form words through the tape.",
	"Muffled gag noises are all you manage.",
	"Voice disabled by duct tape.",
	"The gag has claimed your ability to shout.",
	"Your shout is trapped behind the gag.",
	"Gagged. Shouting not permitted.",
	"The tape keeps your mouth from opening.",
	"You attempt a shout but it comes out as a quiet mmph.",
	"Gag active – your voice is offline.",
	"Duct tape: the ultimate anti-shout device.",
	"Your shout was deleted by the gag.",
	"The server gagged you for a reason. No shouting.",
	"Mouth sealed. Shout denied.",
	"The gag is doing its job too well.",
	"You open your mouth but nothing comes out.",
	"Shouting requires an ungagged mouth.",
	"The duct tape has other ideas.",
	"Your voice is currently on mute.",
	"Gag detected. Shouting disabled.",
}



function shout.get_gag_message()
	return GAG_MESSAGES[math.random(1, #GAG_MESSAGES)]
end



-- Shout a message.
-- This is called from chatcommand OR from regular chat by prepending a [!]
function shout.shout(name, param)
	-- Shouting in all channels requires the 'shout' priv.
	if not minetest.check_player_privs(name, {shout=true}) then
		minetest.chat_send_player(name, "# Server: You can't shout.")
		return
	end

	if command_tokens.mute.player_muted(name) then
		minetest.chat_send_player(name, "# Server: " .. shout.get_gag_message())
		easyvend.sound_error(name)
		return
	end

	if #param < 1 then
		minetest.chat_send_player(name, "# Server: Empty shout.")
		easyvend.sound_error(name)
		return
	end

	param = toad.modify_chat(name, param)

	-- If this succeeds, the player was either kicked, or muted and a message about that sent to everyone else.
	if chat_core.check_language(name, param) then return end

	local mk = chat_core.generate_coord_string(name)
	local dname = rename.gpn(name)
	local players = minetest.get_connected_players()

	for _, player in ipairs(players) do
		local target_name = player:get_player_name() or ""
		if not chat_controls.player_ignored_shout(target_name, name) or target_name == name then
			chat_core.alert_player_sound(target_name)
			minetest.chat_send_player(target_name, "«" .. chat_core.nametag_color .. dname .. WHITE .. mk .. "» " .. SHOUT_COLOR .. param)
		end
	end

	afk.reset_timeout(name)
	player_labels.on_chat_message(name, param)
	chat_logging.log_public_shout(name, param, mk)
end



-- Whisper a message.
-- This is called from chatcommand OR from regular chat by prepending a [$]
function shout.whisper(name, param)
	if #param < 1 then
		minetest.chat_send_player(name, "# Server: Empty whisper.")
		easyvend.sound_error(name)
		return
	end

	local pref = minetest.get_player_by_name(name)
	if not pref or not pref:is_player() then return end
	local pos = pref:get_pos()

	-- If this succeeds, the player was either kicked, or muted and a message about that sent to everyone else.
	-- No language checks on whispers.
	--if chat_core.check_language(name, param) then return end

	param = toad.modify_chat(name, param)

	local mk = chat_core.generate_coord_string(name)
	local dname = rename.gpn(name)
	local players = minetest.get_connected_players()

	for _, player in ipairs(players) do
		local target_name = player:get_player_name() or ""
		local pos2 = player:get_pos()
		-- Since whispers are range limited, they always get through even if players are ignored.
		if vector.distance(pos, pos2) < chat_core.WHISPER_DISTANCE then
			--chat_core.alert_player_sound(target_name)
			minetest.chat_send_player(target_name, "«" .. chat_core.nametag_color .. dname .. WHITE .. mk .. "» " .. chat_core.WHISPER_COLOR .. param)
		end
	end

	afk.reset_timeout(name)
	player_labels.on_chat_message(name, param)
	--chat_logging.log_public_shout(name, param, mk)
end



local function check_language(pname, message)
	if anticurse.check(pname, message, "foul") then
		return
	elseif anticurse.check(pname, message, "curse") then
		return
	end
	return true
end



-- Spoof a local server message.
-- You could use this e.g., for flavor-text, scene-setting, etc.
-- Or use it to abuse someone in an untraceable manner.
function shout.spoof(pname, param, show_help)
	if show_help then
		local helplines = {
			"Usages:",
			"    /spoof A cloaked figure slips a note onto the table.",
			"    /spoof Someplayer You're the only one who'll get this.",
			"If the first word of your message is the name of an online user, the message will be sent to only that user with the prefix \"Someone tells you:\"",
			"Only nearby users receive anything. The max distance is " .. chat_core.WHISPER_DISTANCE .. " blocks.",
		}

		for _, line in ipairs(helplines) do
			minetest.chat_send_player(pname, "# Server: " .. line)
		end
		return
	end

	if #param < 1 then
		minetest.chat_send_player(pname, "# Server: Empty spoof command.")
		easyvend.sound_error(pname)
		return
	end

	local pref = minetest.get_player_by_name(pname)
	if not pref or not pref:is_player() then return end
	local pos = pref:get_pos()

	local to_players = minetest.get_connected_players()
	local message = param
	local tokens = param:split(" ")
	local target_pname = tokens[1] or ""
	local target_pref = minetest.get_player_by_name(target_pname)

	if target_pref then
		message = "Someone tells you: " .. param:sub(target_pname:len() + 2):trim()
		to_players = {[1]=target_pref}
	end

	message = toad.modify_chat(pname, message)

	if not check_language(pname, message) then
		minetest.chat_send_player(pname, "# Server: Watch your tongue.")
		return
	end

	local players_sent_to = {}

	for _, player in ipairs(to_players) do
		local target_name = player:get_player_name() or ""
		local pos2 = player:get_pos()
		-- Since whispers are range limited, they always get through even if players are ignored.
		if vector.distance(pos, pos2) < chat_core.WHISPER_DISTANCE then
			--chat_core.alert_player_sound(target_name)
			minetest.chat_send_player(target_name, "# Server: " .. message)
			if target_name ~= pname then
				table.insert(players_sent_to, target_name)
			end
		end
	end

	if #players_sent_to > 0 then
		minetest.chat_send_player(pname, "# Server: Sent to {" .. table.concat(players_sent_to, ", ") .. "}.")
	else
		minetest.chat_send_player(pname, "# Server: No one received that.")
	end
end
