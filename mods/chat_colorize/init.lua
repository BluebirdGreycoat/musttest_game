
chat_colorize = chat_colorize or {}
chat_colorize.player_just_died = chat_colorize.player_just_died or {}
chat_colorize.modpath = minetest.get_modpath("chat_colorize")



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

	minetest.after(math.random(10, 20), function()
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



chat_colorize.send_player = function(name, message)
  local color = ""
  if string.sub(message, 1, 1) == "#" then
    color = chat_colorize.COLOR_OLIVE
  elseif string.find(message, "^%-!%- Invalid command") then
    message = "# Server: Invalid command. See '/help all' for a list of valid commands."
		easyvend.sound_error(name)
    color = chat_colorize.COLOR_OLIVE
  end
  return chat_colorize.old_chat_send_player(name, color .. message)
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
  --elseif string.sub(message, 1, 2) == "* " then
  --  color = chat_colorize.COLOR_ORANGE
  elseif string.sub(message, 1, 3) == "***" then
    -- Some players can have join/leave messages hidden.
    if should_suppress(message) then return end
    
    color = chat_colorize.COLOR_GRAY
    -- Add <> around player's name.
    message = string.gsub(message, "%*%*%* ([%w_%-]+) ", "*** <%1> ")

		-- Get player's internal name, so we can substitute their nick.
		local nick = string.match(message, "<([%w_%-]+)>")
		if nick then
			message = string.gsub(message, "<[%w_%-]+>", "<" .. rename.gpn(nick) .. ">")
		end

    -- Rewrite the timeout message.
		-- March 20, 2018: changed "timed out" to "connection broke" for better understanding.
    message = string.gsub(message, ". %(timed out%)$", ". (Broken connection.)")

		if nick and message:find("left the game") and chat_colorize.is_ragequit(nick) then
			message = message .. " (" .. ragequit[math.random(1, #ragequit)] .. ".)"
		end
  end
  
  if is_server_message then
    chat_logging.log_server_message(message)
  end
  return chat_colorize.old_chat_send_all(color .. message)
end

if not chat_colorize.registered then
	minetest.chat_send_all = function(...) return chat_colorize.send_all(...) end
	minetest.chat_send_player = function(...) return chat_colorize.send_player(...) end

	chat_colorize.registered = true
end


