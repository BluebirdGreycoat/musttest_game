
-- Localize for performance.
local vector_round = vector.round



local get_time = function(pname)
  return os.date("%Y-%m-%d, %H:%M")
end

local function write(msg)
	if chat_logging.logfile then
		chat_logging.logfile:write(msg)
		chat_logging.logfile:flush()
	end
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
  end
end



chat_logging.on_joinplayer = function(obj)
end

chat_logging.on_leaveplayer = function(obj, timeout)
end



chat_logging.report_leavejoin_player = function(pname, message)
  local prefix2 = "[" .. get_public_time() .. "] "
	local wspace2 = generate_shortspace(prefix2)
	prefix2 = prefix2 .. wspace2
	local msg2 = prefix2 .. message .. "\n"

	if not chat_colorize.should_suppress(pname) then
		write(msg2)
	end
end



-- Public API functions.

chat_logging.log_public_shout = function(pname, msg, loc)
  local prefix2 = "[" .. get_public_time() .. "] "
	local wspace2 = generate_shortspace(prefix2)
	prefix2 = prefix2 .. wspace2 .. "<!" .. rename.gpn(pname) .. loc .. "!> " .. msg .. "\n"
	write(prefix2)
end

chat_logging.log_public_chat = function(pname, msg, loc)
	local prefix2 = "[" .. get_public_time() .. "] "
	local wspace2 = generate_shortspace(prefix2)
	prefix2 = prefix2 .. wspace2 .. "<" .. rename.gpn(pname) .. loc .. "> " .. msg .. "\n"
	write(prefix2)
end

--[[
chat_logging.log_public_action = function(pname, act, loc)
	local prefix2 = "[" .. get_public_time() .. "] "
	local wspace2 = generate_shortspace(prefix2)
	prefix2 = prefix2 .. wspace2 .. "* <" .. rename.gpn(pname) .. loc .. "> " .. act .. "\n"
	write(prefix2)
end
--]]

chat_logging.log_server_message = function(message)
	local prefix2 = "[" .. get_public_time() .. "] "
	local wspace2 = generate_shortspace(prefix2)
	prefix2 = prefix2 .. wspace2 .. message .. "\n"
	write(prefix2)
end


