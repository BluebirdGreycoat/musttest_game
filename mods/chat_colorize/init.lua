
if not minetest.global_exists("chat_colorize") then chat_colorize = {} end
chat_colorize.player_just_died = chat_colorize.player_just_died or {}
chat_colorize.modpath = minetest.get_modpath("chat_colorize")

local S = core.get_translator("chat_colorize")

-- Localize for performance.
local math_random = math.random

local MUD_UKNOWN_COMMAND = {
	"Huh?",
	"I don't understand that.",
	"Eh?",
	"What?",
	"I don't understand.",
	"Huh?!?",
	"I couldn't understand that.",
	"Unknown command. Have you tried punching a tree for inspiration?",
	"That command doesn't exist. The griefers are hissing in disapproval.",
	"Command not found. It probably fell into lava.",
	"The system is confused. Did you mean to type something that actually exists?",
	"Unknown command. The wisp stole the rest of it.",
	"Error: Your contraption for parsing commands just exploded.",
	"That didn't work. Go craft some common sense and try '/help'.",
	"Unknown command. The Elite is laughing at your life choices.",
	"Command rejected. Touch some grass blocks and come back with a real one.",
	"The void ate your command. Try '/help' next time?",
	"Unknown command. The system is facepalming.",
	"That command broke. Time to rebuild it ... or just use '/help'.",
	"System says: 'Lol no.' The phantoms are already circling.",
	"Command not recognized. Your hunger bar dropped just trying to read that.",
	"Unknown command. It got lost in the Nether. Use '/help' to find your way back.",
	"The parser says 'no u.' Please craft a better command.",
	"Error 418: I'm a teapot (and this command is invalid).",
	"Unknown command. The admin's ghost is playing with your keyboard.",
	"That command isn't craftable with the materials you currently have. Try '/help' for the recipe.",
	"Unknown command. The zombies outside heard you struggling and are coming to help.",
	"That didn't parse. Did you forget your common sense?",
	"Unknown command. It was probably on the other side of the world.",
	"The system has no idea what that means. Have some cooked steak instead.",
	"Command failed successfully. Good job breaking it!",
	"Unknown command. The system is busy respawning you after your last creative idea.",
	"Unknown command.",
	"Nonsense.",
	"That's pure nonsense.",
	"Horse manure.",
	"Are you dyslexic?",
	"Every time you mistype a command, your IQ approaches Africa's.",
	"I think I'm having a senior moment.",
	"Excuse me ....",
	"Big brain much?",
}



-- Support for hot reloading.
local mp = chat_colorize.modpath .. "/init.lua"
local rn = "chat_colorize:core"
if minetest.get_modpath("reload") then
    if not reload.file_registered(rn) then
        reload.register_file(rn, mp, false)
    end
end
mp = nil
rn = nil



function chat_colorize.notify_death(pname)
	if chat_colorize.player_just_died[pname] then
		return
	end

	chat_colorize.player_just_died[pname] = true

	minetest.after(math_random(30, 60), function()
		chat_colorize.player_just_died[pname] = nil
	end)
end

function chat_colorize.is_ragequit(pname)
	if chat_colorize.player_just_died[pname] then
		return true
	end
end



if not chat_colorize.gotten then
	chat_colorize.old_chat_send_player = minetest.chat_send_player
	chat_colorize.old_chat_send_all = minetest.chat_send_all
	chat_colorize.gotten = true
end



-- Using cyan color, at request of sorcerykid. This color is easy to see.
chat_colorize.COLOR_CYAN = core.get_color_escape_sequence("#00e0ff")
chat_colorize.COLOR_OLIVE = core.get_color_escape_sequence("#9a7122")
chat_colorize.COLOR_YELLOW = core.get_color_escape_sequence("#ffff00")
chat_colorize.COLOR_ORANGE = core.get_color_escape_sequence("#ffae00")
chat_colorize.COLOR_GRAY = core.get_color_escape_sequence("#aaaaaaff")



if not chat_colorize.registered then
	minetest.register_privilege("nojoinmsg", {
		description = "Player's join/leave messages will not be announced.",
		give_to_singleplayer = false,
	})
end



-- Must be careful not to trigger on chat sent by players.
chat_colorize.send_player = function(name, msg)
  local color = ""
  if msg:sub(1, 1) == "#" then
    color = chat_colorize.COLOR_OLIVE
  elseif msg:find("^-!-") and msg:find("Invalid command usage") then
    msg = "# Server: Invalid command usage."
		easyvend.sound_error(name)
    color = chat_colorize.COLOR_OLIVE
  elseif msg:find("^-!-") and msg:find("Invalid command:") then
    msg = "# Server: " .. MUD_UKNOWN_COMMAND[math.random(1, #MUD_UKNOWN_COMMAND)]
		easyvend.sound_error(name)
    color = chat_colorize.COLOR_OLIVE
  elseif msg:find("^-!-") and msg:find("Empty command") then
    msg = "# Server: Empty command. See '/help' for a list of valid commands."
		easyvend.sound_error(name)
    color = chat_colorize.COLOR_OLIVE
  elseif msg:sub(1, 1) ~= "<" and msg:find("Command execution took") then
		-- Not an error.
    msg = "# Server: " .. minetest.strip_colors(msg)
    color = chat_colorize.COLOR_OLIVE
  elseif msg:sub(1, 1) ~= "<" and msg:find("You don't have permission to run this command") then
    msg = "# Server: " .. minetest.strip_colors(msg)
		easyvend.sound_error(name)
    color = chat_colorize.COLOR_OLIVE
  end

  --[[
  -- Make it less verbose.
  if msg:find("^# Server: ") then
		msg = "#" .. msg:sub(10)
  end
  --]]

  return chat_colorize.old_chat_send_player(name, color .. msg)
end



local should_suppress = function(msg)
  --if string.sub(msg, 1, 4) == "*** " then
    local strs = string.split(msg, " ")
    local name = strs[2]
    if type(name) == "string" and string.len(name) > 0 then
      local hide = minetest.check_player_privs(name, {nojoinmsg=true})
      if hide then return true end
    end
  --end
end

chat_colorize.should_suppress = function(pname)
	local hide = minetest.check_player_privs(pname, {nojoinmsg=true})
	if hide then return true end
end


local ragequit = {
	"Rage-quit",
	"Sneaked out",
	"Left in a huff",
	"Quit",
	"Couldn't take the heat",
	"Embarrassed",
	"Stormed out",
	"Stormed off",
	"Walked out",
	"Ugh",
	"This place stinks",
	"Gone home",
	"This server sucks, I'm going home",
	"Getting out",
	"Escaped",
	"Out-skilled",
	"Lame",
	"Just can't even",
	"Busy repairing ego",
	"The peaceful life is elsewhere",
	"Checked out",
	"Reached salt cap",
	"Noped out",
	"Equiped quit button",
	"This server's full of cheaters",
	"Salt",
	"Fled",
	"Respawning elsewhere",
	"Damage to ego",
	"Bye",
	"Way too much nope",
	"Server not balanced",
	"Ego took critical hit",
	"Hate losing",
	"Temp self-ban",
	"Salt limit exceeded",
	"Bruh",
	"Better things to do",
	"Cooling off",
	"Chilling out",
	"Fleeing the natives",
}

local function get_ragequit()
	return ragequit[math_random(1, #ragequit)]
end

chat_colorize.send_all = function(channels, message)
	-- Backward compatibility.
	if not message then
		message = channels
		channels = {"announce"}
	elseif type(channels) == "string" then
		channels = {[1]=channels}
	end

  local color = ""
  local is_server_message = false
  if string.sub(minetest.strip_colors(message), 1, 1) == "#" then
    color = chat_colorize.COLOR_CYAN
    is_server_message = true
  end

  --[[
  -- Make it less verbose.
  if message:find("^# Server: ") then
		message = "#" .. message:sub(10)
  end
  --]]

  if is_server_message then
    chat_logging.log_server_message(message)
  end

  shout.notify_channels(channels, color .. message)
  --return chat_colorize.old_chat_send_all(color .. message)
end

if not chat_colorize.registered then
	minetest.chat_send_all = function(...) return chat_colorize.send_all(...) end
	minetest.chat_send_player = function(...) return chat_colorize.send_player(...) end

	function core.send_join_message(player_name)
		if not core.is_singleplayer() and not chat_colorize.should_suppress(player_name) then
			local color = chat_colorize.COLOR_GRAY
			local prefix = "*** "
			local alias = "<" .. rename.gpn(player_name) .. ">"
			local message = " joined the game."

			-- Send colored, prefixed, translatable message to chat using player's alias.
			chat_colorize.old_chat_send_all(color .. prefix .. S("@1" .. message, alias))

			-- Send bare prefix + alias + message to log.
			chat_logging.report_leavejoin_player(player_name, prefix .. alias .. message)
		end
	end

	function core.send_leave_message(player_name, timed_out)
		if not core.is_singleplayer() and not chat_colorize.should_suppress(player_name) then
			local color = chat_colorize.COLOR_GRAY
			local prefix = "*** "
			local alias = "<" .. rename.gpn(player_name) .. ">"
			local message = " left the game."
			local to_spc, timeout_suffix = "", ""
			local rq_spc, ragequit_suffix = "", ""

			if timed_out then
				to_spc, timeout_suffix = " ", "(Broken connection.)"
			end

			if chat_colorize.is_ragequit(player_name) then
				rq_spc, ragequit_suffix = " ", "(" .. get_ragequit() .. ".)"
			end

			-- Send colored, prefixed, translatable message [ + translatable timeout_suffix ]
			-- [ + translatable ragequit_suffix ] to chat using player's alias.
			chat_colorize.old_chat_send_all(color .. prefix .. S("@1" .. message, alias) ..
				to_spc .. S(timeout_suffix) .. rq_spc .. S(ragequit_suffix))

			-- Send bare prefix + alias + message [ + timeout suffix ] [ + ragequit suffix ] to log.
			chat_logging.report_leavejoin_player(player_name, prefix .. alias .. message ..
				to_spc .. timeout_suffix .. rq_spc .. ragequit_suffix)
		end
	end

	chat_colorize.registered = true
end


