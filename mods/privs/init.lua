
privs = privs or {}
privs.modpath = minetest.get_modpath("privs")



privs.print_privs = function(user, param)
  assert(type(user) == "string")
  assert(type(param) == "string")

  local name = param:trim()
  if name == "" then
    name = user
  end
  
  if not minetest.player_exists(name) then
    minetest.chat_send_player(user, "# Server: Player <" .. rename.gpn(name) .. "> does not exist.")
    return true
  end
  
  local privs = minetest.get_player_privs(name)
  if privs then
    -- There are only two tiers. A player is either a `player`, or the server operator (ME).
    -- There are no other privilege tiers, and no details given, to avoid jealously problems.
    local string = "player"

    if privs.server then
      string = "server"
    end

		if user == name or minetest.check_player_privs(target, {privs=true}) then
			-- If player is querying privs of self, or player is admin, then print full privs list.
			minetest.chat_send_player(user, "# Server: Privileges of <" .. rename.gpn(name) .. ">: " .. core.privs_to_string(table.sort(privs)):gsub(",", ", ") .. ".")
		else
			-- Otherwise just print the generic privs rank.
			minetest.chat_send_player(user, "# Server: Privilege rank of <" .. rename.gpn(name) .. ">: " .. string .. ".")
		end
    return true
  end
  
  minetest.chat_send_player(user, "# Server: Could not obtain privileges of player <" .. rename.gpn(name) .. ">!")
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

