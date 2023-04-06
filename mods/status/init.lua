
if not minetest.global_exists("status") then status = {} end
status.modpath = minetest.get_modpath("status")
status.motd = minetest.setting_get("motd") or ""

-- Get text color.
local STATUS_COLOR = core.get_color_escape_sequence("#0d9b7b")
status.color = STATUS_COLOR



function status.chat_players(user, param)
	do
		-- Serialize player names to string.
		local players = minetest.get_connected_players()
		local clients = "{"
		local num_clients = 0
		for k, v in ipairs(players) do
			local hide = minetest.check_player_privs(v:get_player_name(), {statushide=true})
			if hide == false then
				clients = clients .. rename.gpn(v:get_player_name()) .. ", "
				num_clients = num_clients + 1
			end
		end
		clients = clients .. "}"
		clients = string.gsub(clients, ", }", "}")

		-- Build status string.
		local final =
			STATUS_COLOR .. "# Server: Players Online (" .. num_clients .. "): " .. clients .. "."

		minetest.chat_send_player(user, final)
	end

	do
		-- Serialize player names to string.
		local channel = shout.player_channel(user)
		if channel and channel ~= "" then
			local players = shout.channel_players(channel)
			local clients = "{"
			local num_clients = 0
			for k, v in ipairs(players) do
				local hide = minetest.check_player_privs(v, {statushide=true})
				if hide == false then
					clients = clients .. rename.gpn(v) .. ", "
					num_clients = num_clients + 1
				end
			end
			clients = clients .. "}"
			clients = string.gsub(clients, ", }", "}")

			-- Build status string.
			local final =
				STATUS_COLOR .. "# Server: Players In Channel '" .. channel .. "' (" .. num_clients .. "): " .. clients .. "."

			minetest.chat_send_player(user, final)
		end
	end

	return true
end



function status.chat_status(user, param)
  local p1, p2
  
  -- Get uptime.
  local status_str = status.original_status()
  p1, p2 = string.find(status_str, "uptime:[^|]+")
  local uptime = "uptime: unknown"
  if p1 and p2 then
    uptime = string.sub(status_str, p1, p2)
    uptime = string.gsub(uptime, "uptime: ", "Uptime: ")
		uptime = string.trim(uptime)
  end
  
  p1, p2 = string.find(status_str, "max lag:[^|]+")
  local max_lag = "max lag: unknown"
  if p1 and p2 then
    max_lag = string.sub(status_str, p1, p2)
    max_lag = string.gsub(max_lag, "max lag: ", "Max Lag: ")
		max_lag = string.trim(max_lag)
  end

  -- Get MoTD.
  local motd2 = status.motd
  if not motd2 then
		motd2 = "Daily message has not been set!"
  end
  
  -- Get version string.
  local version = "version: unknown"
  p1, p2 = string.find(status_str, "version:[^|]+")
  if p1 and p2 then
		version = string.sub(status_str, p1, p2)
		version = string.trim(version)
  end
  version = string.gsub(version, "version: ", "Version: ")
  version = string.gsub(version, "-dev", "-DEV")
  
  -- Build status string.
  local final =
		STATUS_COLOR .. "# Server: " .. version .. ", " .. uptime .. ", " .. max_lag .. ".\n" ..
		STATUS_COLOR .. "# Server: " .. motd2 .. "\n" ..
		STATUS_COLOR .. "# Server: More info can be found at http://arklegacy.duckdns.org/."
  
  minetest.chat_send_player(user, final)
  return true
end



function status.chat_short_status(user, param)
  -- Serialize player names to string.
  local players = minetest.get_connected_players()
  local clients = "{"
  local num_clients = 0
  for k, v in ipairs(players) do
		local pname = v:get_player_name()
		local hide = minetest.check_player_privs(pname, {statushide=true})
		if pname == user then
			hide = true
		end
		if hide == false then
			clients = clients .. rename.gpn(pname) .. ", "
			num_clients = num_clients + 1
		end
  end
  clients = clients .. "}"
  clients = string.gsub(clients, ", }", "}")

	local sare = "are"
	local splayers = "players"

	if num_clients == 1 then
		sare = "is"
		splayers = "player"
	end

	local tail = ": " .. clients .. "."
	if num_clients == 0 then
		tail = "."
	end

	local final = STATUS_COLOR .. "# Server: " ..
		"Welcome back, <" .. rename.gpn(user) .. ">! There " .. sare ..
		" currently " ..
		num_clients .. " " .. splayers .. " online" .. tail

	minetest.chat_send_player(user, final)
end



function status.chat_admin(name, param)
	minetest.chat_send_player(name,
		STATUS_COLOR .. "# Server: The administrator of this server is <MustTest>. " ..
		"You may send me messages using the email interface found through the Key of Citizenship.")
	return true
end



function status.on_joinplayer(player)
	local pname = player:get_player_name()
	-- Don't show /status info to registered players rejoining the server.
	-- It's just noise, if they want it they can type /status manually.
	if not passport.player_registered(pname) then
		status.chat_status(pname, "")
	else
		status.chat_short_status(pname, "")
	end
end



if not status.registered then
	-- Save original function.
	status.original_status = minetest.get_server_status

	-- Override builtin status function to prevent showing this message on player join!
	function minetest.get_server_status(pname, joined)
		return nil
	end


	-- Override the /status chat command.
	minetest.override_chatcommand("status", {
		params = "",
		description = "Show the server's current status.",
		privs = {},
		func = function(...) return status.chat_status(...) end,
	})

	minetest.register_chatcommand("players", {
		params = "",
		description = "Show list of players currently online.",
		privs = {},
		func = function(...) return status.chat_players(...) end,
	})

	minetest.override_chatcommand("admin", {
		params = "",
		description = "Show the name of the server owner and primary operator.",
		privs = {},
		func = function(...) return status.chat_admin(...) end,
	})

	local timefunc = minetest.registered_chatcommands["time"].func
	assert(type(timefunc) == "function")
	minetest.override_chatcommand("time", {
		description = "Set or get the current time of day.",
		func = function(name, param)
			local result, message = timefunc(name, param)
			message = STATUS_COLOR .. "# Server: " .. message
			minetest.chat_send_player(name, message)
			return true
		end,
	})

	local daysfunc = minetest.registered_chatcommands["days"].func
	assert(type(daysfunc) == "function")
	minetest.override_chatcommand("days", {
		description = "Display day count.",
		func = function(name, param)
			local result, message = daysfunc(name, param)
			message = STATUS_COLOR ..
				"# Server: " .. message .. " " ..
				string.gsub(hud_clock.get_date_string(), "\n+", ", ")
			minetest.chat_send_player(name, message)
			return true
		end,
	})

	minetest.register_privilege("statushide", {
		description = "Player's name will not be shown in the server's status string.",
		give_to_singleplayer = false,
	})

	-- Send status string to players on join.
	-- The engine status string is disabled in server config.
	minetest.register_on_joinplayer(function(...) return status.on_joinplayer(...) end)

	reload.register_file("status:core", status.modpath .. "/init.lua", false)
	status.registered = true
end


