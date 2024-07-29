
if not minetest.global_exists("privs") then privs = {} end
privs.modpath = minetest.get_modpath("privs")



privs.print_privs = function(user, param)
  assert(type(user) == "string")
  assert(type(param) == "string")

  local name = param:trim()
  if name == "" then
    name = user
  end
  
  if not minetest.player_exists(name) then
    minetest.chat_send_player(user, "# Server: Entity <" .. rename.gpn(name) .. "> was never embodied.")
    easyvend.sound_error(user)
    return true
  end
  
  local privs = minetest.get_player_privs(name)
  if privs then
    -- Few details are given, to avoid jealously problems.
    local string = "a civilian"

    if privs.server then
      string = "an arch-wizard"
    end

		if user == name or minetest.check_player_privs(user, {privs=true}) then
			-- If player is querying privs of self, or player is admin, then print full privs list.
			minetest.chat_send_player(user, "# Server: Capabilities of <" .. rename.gpn(name) .. ">: " .. core.privs_to_string(privs, ", ") .. ".")
		else
			-- Otherwise just print the generic privs rank.
			minetest.chat_send_player(user, "# Server: <" .. rename.gpn(name) .. "> is " .. string .. ".")
		end
    return true
  end
  
  minetest.chat_send_player(user, "# Server: Could not obtain capabilities of <" .. rename.gpn(name) .. ">!")
	easyvend.sound_error(user)
  return true
end



if not privs.run_once then
  minetest.register_chatcommand("privs", {
    params = "[playername]",
    description = "Print privileges of a player, or your own privileges.",
    privs = {},
    func = function(...) return privs.print_privs(...) end,
  })
  
  local c = "privs:core"
  local f = privs.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
  privs.run_once = true
end

