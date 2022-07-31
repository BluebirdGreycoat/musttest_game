
chat_colorize = chat_colorize or {}
chat_colorize.player_just_died = chat_colorize.player_just_died or {}
chat_colorize.modpath = minetest.get_modpath("chat_colorize")

local S = core.get_translator("chat_colorize")

-- Localize for performance.
local math_random = math.random



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
    msg = "# Server: Invalid command. See '/help' for a list of valid commands."
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
}

chat_colorize.send_all = function(message)
  local color = ""
  local is_server_message = false
  if string.sub(message, 1, 1) == "#" then
    color = chat_colorize.COLOR_CYAN
    is_server_message = true
  end
  
  if is_server_message then
    chat_logging.log_server_message(message)
  end
  return chat_colorize.old_chat_send_all(color .. message)
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
				rq_spc, ragequit_suffix = " ", "(" .. ragequit[math_random(1, #ragequit)] .. ".)"
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


