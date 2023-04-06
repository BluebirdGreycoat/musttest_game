
if not minetest.global_exists("chat_logging") then chat_logging = {} end
chat_logging.modpath = minetest.get_modpath("chat_logging")
chat_logging.worldpath = minetest.get_worldpath()

-- Localize for performance.
local vector_round = vector.round



-- Register this file as reloadable, if not already done.
if minetest.get_modpath("reload") then
  local c = "chat_logging:core"
  local f = chat_logging.modpath .. "/init.lua"
  if not reload.file_registered(c) then
    reload.register_file(c, f, false)
  end
end



local get_time = function(pname)
  return os.date("%Y-%m-%d, %H:%M")
end

local get_time_and_place = function(pname)
  local place = "N/A"
  local player = minetest.get_player_by_name(pname)
  if player and player:is_player() then
    place = minetest.pos_to_string(vector_round(player:get_pos()))
  end
  return os.date("%Y-%m-%d, %H:%M @ " .. place)
end

local get_public_time = function()
  return os.date("!%Y/%m/%d, %H:%M:%S UTC")
end

local generate_whitespace = function(msg)
  local len = 50 - string.len(msg)
  if len < 0 then len = 0 end
  local space = string.rep(" ", len)
  return space
end

local generate_shortspace = function(msg)
  local len = 30 - string.len(msg)
  if len < 0 then len = 0 end
  local space = string.rep(" ", len)
  return space
end



chat_logging.on_shutdown = function()
	minetest.chat_send_all("# Server: Normal shutdown. Everybody off!")

  if chat_logging.logfile then
    chat_logging.logfile:flush()
    chat_logging.logfile:close()

		chat_logging.logfile2:flush()
		chat_logging.logfile2:close()
  end
end



chat_logging.on_joinplayer = function(obj)
	--[[
  local pname = obj:get_player_name()
  local prefix = "[" .. get_time_and_place(pname) .. "] "
	local prefix2 = "[" .. get_public_time() .. "] "
  local wspace = generate_whitespace(prefix)
	local wspace2 = generate_shortspace(prefix2)
  prefix = prefix .. wspace
	prefix2 = prefix2 .. wspace2
	local msg = prefix .. "*** <" .. rename.gpn(pname) .. "> joined the game.\n"
	local msg2 = prefix2 .. "*** <" .. rename.gpn(pname) .. "> joined the game.\n"
  chat_logging.logfile:write(msg)
	if not chat_colorize.should_suppress(pname) then
		chat_logging.logfile2:write(msg2)
	end
  chat_logging.logfile:flush()
	chat_logging.logfile2:flush()
	--]]
end



chat_logging.report_leavejoin_player = function(pname, message)
  local prefix = "[" .. get_time_and_place(pname) .. "] "
  local prefix2 = "[" .. get_public_time() .. "] "
  local wspace = generate_whitespace(prefix)
	local wspace2 = generate_shortspace(prefix2)
  prefix = prefix .. wspace
	prefix2 = prefix2 .. wspace2

	local msg = prefix .. message .. "\n"
	local msg2 = prefix2 .. message .. "\n"

	chat_logging.logfile:write(msg)
	if not chat_colorize.should_suppress(pname) then
		chat_logging.logfile2:write(msg2)
	end

  chat_logging.logfile:flush()
	chat_logging.logfile2:flush()
end

chat_logging.on_leaveplayer = function(obj, timeout)
	--[[
  local pname = obj:get_player_name()
  local prefix = "[" .. get_time_and_place(pname) .. "] "
  local prefix2 = "[" .. get_public_time() .. "] "
  local wspace = generate_whitespace(prefix)
	local wspace2 = generate_shortspace(prefix2)
  prefix = prefix .. wspace
	prefix2 = prefix2 .. wspace2
  if timeout then
		local msg = prefix .. "*** <" .. rename.gpn(pname) .. "> left the game. (Broken connection.)\n"
		local msg2 = prefix2 .. "*** <" .. rename.gpn(pname) .. "> left the game. (Broken connection.)\n"
    chat_logging.logfile:write(msg)
		if not chat_colorize.should_suppress(pname) then
			chat_logging.logfile2:write(msg2)
		end
  else
		local msg = prefix .. "*** <" .. rename.gpn(pname) .. "> left the game.\n"
		local msg2 = prefix2 .. "*** <" .. rename.gpn(pname) .. "> left the game.\n"
    chat_logging.logfile:write(msg)
		if not chat_colorize.should_suppress(pname) then
			chat_logging.logfile2:write(msg2)
		end
  end
  chat_logging.logfile:flush()
	chat_logging.logfile2:flush()
	--]]
end



-- Open logfile if not already done.
if not chat_logging.opened then
  local path = chat_logging.worldpath .. "/chat.txt"
  chat_logging.logfile = io.open(path, "a")

	local path2 = chat_logging.worldpath .. "/chat-public.txt"
	chat_logging.logfile2 = io.open(path2, "a")

  minetest.register_on_shutdown(function(...) 
    return chat_logging.on_shutdown(...) end)
  --minetest.register_on_joinplayer(function(...)
  --  return chat_logging.on_joinplayer(...) end)
  --minetest.register_on_leaveplayer(function(...)
  --  return chat_logging.on_leaveplayer(...) end)
  
  chat_logging.opened = true
end



-- Public API functions.

chat_logging.log_public_shout = function(pname, msg, loc)
  local prefix = "[" .. get_time_and_place(pname) .. "] "
  local prefix2 = "[" .. get_public_time() .. "] "
  local wspace = generate_whitespace(prefix)
	local wspace2 = generate_shortspace(prefix2)
  prefix = prefix .. wspace .. "<!" .. rename.gpn(pname) .. loc .. "!> " .. msg .. "\n"
	prefix2 = prefix2 .. wspace2 .. "<!" .. rename.gpn(pname) .. loc .. "!> " .. msg .. "\n"
  chat_logging.logfile:write(prefix)
	chat_logging.logfile2:write(prefix2)
  chat_logging.logfile:flush()
	chat_logging.logfile2:flush()
end

chat_logging.log_public_chat = function(pname, msg, loc)
  local prefix = "[" .. get_time_and_place(pname) .. "] "
	local prefix2 = "[" .. get_public_time() .. "] "
  local wspace = generate_whitespace(prefix)
	local wspace2 = generate_shortspace(prefix2)
  prefix = prefix .. wspace .. "<" .. rename.gpn(pname) .. loc .. "> " .. msg .. "\n"
	prefix2 = prefix2 .. wspace2 .. "<" .. rename.gpn(pname) .. loc .. "> " .. msg .. "\n"
  chat_logging.logfile:write(prefix)
	chat_logging.logfile2:write(prefix2)
  chat_logging.logfile:flush()
	chat_logging.logfile2:flush()
end

chat_logging.log_public_action = function(pname, act, loc)
  local prefix = "[" .. get_time_and_place(pname) .. "] "
	local prefix2 = "[" .. get_public_time() .. "] "
  local wspace = generate_whitespace(prefix)
	local wspace2 = generate_shortspace(prefix2)
  prefix = prefix .. wspace .. "* <" .. rename.gpn(pname) .. loc .. "> " .. act .. "\n"
	prefix2 = prefix2 .. wspace2 .. "* <" .. rename.gpn(pname) .. loc .. "> " .. act .. "\n"
  chat_logging.logfile:write(prefix)
	chat_logging.logfile2:write(prefix2)
  chat_logging.logfile:flush()
	chat_logging.logfile2:flush()
end

chat_logging.log_private_message = function(from, to, message)
  local prefix = "[" .. get_time_and_place(from) .. "] "
  local wspace = generate_whitespace(prefix)
  prefix = prefix .. wspace .. "<" .. rename.gpn(from) .. " -- " .. rename.gpn(to) .. "> " .. message .. "\n"
  chat_logging.logfile:write(prefix)
  chat_logging.logfile:flush()
end

chat_logging.log_team_chat = function(from, message, team)
  local prefix = "[" .. get_time_and_place(from) .. "] "
  local wspace = generate_whitespace(prefix)
  prefix = prefix .. wspace .. "<" .. rename.gpn(from) .. " x:" .. team .. "> " .. message .. "\n"
  chat_logging.logfile:write(prefix)
  chat_logging.logfile:flush()
end

chat_logging.log_server_message = function(message)
  local prefix = "[" .. get_time() .. "] "
	local prefix2 = "[" .. get_public_time() .. "] "
  local wspace = generate_whitespace(prefix)
	local wspace2 = generate_shortspace(prefix2)
  prefix = prefix .. wspace .. message .. "\n"
	prefix2 = prefix2 .. wspace2 .. message .. "\n"
  chat_logging.logfile:write(prefix)
	chat_logging.logfile2:write(prefix2)
  chat_logging.logfile:flush()
	chat_logging.logfile2:flush()
end


