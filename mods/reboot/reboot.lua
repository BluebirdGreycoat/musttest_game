
-- Mod API table.
reboot = reboot or {}



-- This function is reloadable.
reboot.do_reboot = function(name, param)
  local message = "Server is restarting. It should be back online in a few seconds."
  if param ~= "" then
    message = param
  end

  local request_reconnect = false
  local sigpath = minetest.setting_get("reboot_signal_path")
  
  if sigpath then
    -- Signal to the control script to restart the server.
    local file = io.open(sigpath, "w")
    
    if not file then
      minetest.chat_send_player(name, "# Server: Error: could not create signal file at '" .. sigpath .. "'.")
			easyvend.sound_error(name)
      return
    end
    
    file:close()
    file = nil
    request_reconnect = true
  end

  -- Ask the MT server to shutdown.
	minetest.chat_send_all("# Server: " .. message)
  minetest.request_shutdown(message, request_reconnect)
end



if not reboot.chatcommand_registered then
  minetest.register_chatcommand("reboot", {
    params = "<kick message>",
    description = "Reboot the server, with an optional message to all players explaining what is going on.",

    -- Player must have server priviliges.
    privs = {server = true},
    func = function(...) return reboot.do_reboot(...) end,
  })

  reboot.chatcommand_registered = true
end



