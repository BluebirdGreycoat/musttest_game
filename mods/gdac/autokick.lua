
if not minetest.global_exists("autokick") then autokick = {} end
autokick.kicked_players = autokick.kicked_players or {}

local players = autokick.kicked_players

function autokick.kick_player(pname, time)
  time = time or 60
  players[pname] = os.time() + time
end
