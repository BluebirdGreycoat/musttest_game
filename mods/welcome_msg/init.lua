
welcome = welcome or {}
welcome.modpath = minetest.get_modpath("welcome_msg")

-- Timeout in seconds.
welcome.timeout = tonumber(minetest.setting_get("welcome_msg_delay") or 15)
welcome.timeout2 = tonumber(minetest.setting_get("welcome_msg_delay2") or 30)

-- The welcome message.
welcome.message = minetest.setting_get("welcome_msg_string") or "Welcome!"
welcome.message2 = minetest.setting_get("welcome_msg_string2")

welcome.color = core.get_color_escape_sequence("#ff00ff")



welcome.on_timer = function(pname)
	local player = minetest.get_player_by_name(pname)
	if not player then return end -- Player doesn't exist anymore.
	minetest.chat_send_player(pname, welcome.color .. "# Server: " .. welcome.message)
end



welcome.on_timer2 = function(pname)
  local player = minetest.get_player_by_name(pname)
  if not player then return end -- Player doesn't exist anymore.
  if welcome.message2 then
    minetest.chat_send_player(pname, welcome.color .. "# Server: " .. welcome.message2)
  end
end



welcome.on_joinplayer = function(player)
  if not player or not player:is_player() then return end
	local pname = player:get_player_name()

	if banned_names.guest_name(pname) then
		minetest.after(10, function() minetest.chat_send_player(pname, "# Server: WARNING! You have logged in using a \"guest name\". Please be aware that such accounts are subject to deletion WITHOUT WARNING. You are still free to explore the server, though! If you want to play permanently, log in under another (non-guest) name and register the account by crafting and keeping a Proof of Citizenship.") end)
	 return
	end

	--[[
	local pname = player:get_player_name()
	if passport.player_registered(pname) then return end
	minetest.after(welcome.timeout, welcome.on_timer, pname)
	minetest.after(welcome.timeout2, welcome.on_timer2, pname)
	--]]
end



if not welcome.init_done then
	minetest.register_on_joinplayer(function(...)
		return welcome.on_joinplayer(...) end)

	-- Support for mod reloading, if available.
	if minetest.get_modpath("reload") then
		local args = {
			"welcome:core",
			welcome.modpath .. "/init.lua",
			false,
		}
		reload.register_file(unpack(args))
	end

	dofile(welcome.modpath .. "/joinspec.lua")
	welcome.init_done = true
end



