
chat_echo = chat_echo or {}
chat_echo.modpath = minetest.get_modpath("chat_echo")
chat_echo.players = chat_echo.players or {}

-- Player chat is echoed by default, since most players need it now.



chat_echo.echo_chat = function(pname, chat)
  if chat_echo.players[pname] then
    minetest.chat_send_player(pname, chat)
  end
end



chat_echo.set_echo = function(pname, value)
  if value == true then
    chat_echo.players[pname] = true
    chat_echo.modstorage:set_int(pname .. ":echo", 1)
    minetest.chat_send_player(pname, "# Server: The server will now echo your chat back to you.")
  elseif value == false then
    chat_echo.players[pname] = nil
    chat_echo.modstorage:set_int(pname .. ":echo", 2)
    minetest.chat_send_player(pname, "# Server: The server will no longer echo your chat to you.")
  end
end

chat_echo.get_echo = function(pname)
  if chat_echo.players[pname] then
    return true
  else
    return false
  end
end



chat_echo.on_joinplayer = function(player)
	local pname = player:get_player_name()
	chat_echo.players[pname] = true
	local value = chat_echo.modstorage:get_int(pname .. ":echo")
	if value == 1 then
		-- Chat echo should stay enabled.
	elseif value == 2 then
		-- Chat echo must be disabled.
		-- (Player must still have older client that auto-predicts chat.)
		chat_echo.players[pname] = nil
	end
end

chat_echo.on_leaveplayer = function(player)
	local pname = player:get_player_name()
	chat_echo.players[pname] = nil
end



if not chat_echo.run_once then
  chat_echo.modstorage = minetest.get_mod_storage()
  
  minetest.register_on_joinplayer(function(...)
		return chat_echo.on_joinplayer(...)
  end)

	minetest.register_on_leaveplayer(function(...)
		return chat_echo.on_leaveplayer(...)
	end)
  
  local c = "chat_echo:core"
  local f = chat_echo.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
  chat_echo.run_once = true
end
