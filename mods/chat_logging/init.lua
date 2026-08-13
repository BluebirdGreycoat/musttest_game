
if not minetest.global_exists("chat_logging") then chat_logging = {} end
chat_logging.modpath = minetest.get_modpath("chat_logging")
chat_logging.worldpath = minetest.get_worldpath()
reload.install_simple_signals(chat_logging)

-- Localize for performance.
local vector_round = vector.round

dofile(chat_logging.modpath .. "/functions.lua")



-- Register this file as reloadable, if not already done.
if minetest.get_modpath("reload") then
  local c = "chat_logging:core"
  local f = chat_logging.modpath .. "/init.lua"
  if not reload.file_registered(c) then
    reload.register_file(c, f, false)
  end
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


