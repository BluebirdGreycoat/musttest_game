
if not minetest.global_exists("kickall") then kickall = {} end
kickall.modpath = minetest.get_modpath("kickall")



minetest.register_chatcommand("kickall", {
  params = "<message>",
  description = "Kick all players, with a message.",
  privs = {kick=true},
  func = function(name, param)
    if param == nil or param == "" then
      minetest.chat_send_player(name, "# Server: Please provide a reason, so players know why they are kicked.")
      return false
    end
    
    local players = minetest.get_connected_players()
    for k, v in pairs(players) do
      local pname = v:get_player_name()
      if pname ~= name then
        minetest.kick_player(pname, param)
      end
    end
        
    minetest.chat_send_player(name, "# Server: All other players kicked!")
    return true
  end,
})
