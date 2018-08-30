
echo = echo or {}
echo.modpath = minetest.get_modpath("echo")



minetest.register_privilege("echo", "Allows the player to send server chat messages.")



minetest.register_chatcommand("echo", {
  params = "<message>",
  description = "Send a message to all players as if it came from the server itself.",
  privs = {shout=true, echo=true},
  func = function(name, param)
    minetest.chat_send_all("# Server: " .. param)
  end,
})
