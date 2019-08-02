
gdac_invis = gdac_invis or {}
gdac_invis.modpath = minetest.get_modpath("gdac_invis")
gdac_invis.players = gdac_invis.players or {}



gdac_invis.is_invisible = function(name)
  if gdac_invis.players[name] then
    return true
  else
    return false
  end
end



-- Must be called with the server-internal name of a player.
function gdac_invis.gpn(pname)
	if gdac_invis.is_invisible(pname) then
		return ""
	end
	return rename.gpn(pname)
end



gdac_invis.toggle_invisibility = function(name, param)
  local player = minetest.get_player_by_name(name)
  if player and player:is_player() then
    if not gdac_invis.players[name] then
      gdac_invis.players[name] = {}

			-- Store player's current properties.
			local playerproperties = player:get_properties()
			gdac_invis.players[name].collisionbox = playerproperties.collisionbox

      --player_labels.disable_nametag_broadcast(name)
      player:set_nametag_attributes({color={a=0, r=0, g=0, b=0}, text=gdac_invis.gpn(name)})
      
      player:set_properties({
        visual_size = {x=0, y=0},
        makes_footstep_sound = false,

				-- Cannot be zero-size because otherwise player would fall through cracks.
        collisionbox = {-0.01, 0, -0.01, 0.01, 0.02, 0.01},

				collide_with_objects = false,
				is_visible = false,
      })
      
      minetest.chat_send_player(name, "# Server: You become invisible!")
    else
      player_labels.enable_nametag_broadcast(name)

			-- Restore player properties.
			local collisionbox = gdac_invis.players[name].collisionbox
      player:set_properties({
				visual_size = {x=1, y=1},
        makes_footstep_sound = true,
				collisionbox = collisionbox,
				collide_with_objects = true,
				is_visible = true,
			})
      gdac_invis.players[name] = nil
      
      minetest.chat_send_player(name, "# Server: You are now visible.")
    end
  end
  return true
end



if not gdac_invis.run_once then
  minetest.register_privilege("gdac_invis", {
    description = "Permits an admin to be invisible to other players.",
    give_to_singleplayer = false,
  })
  
  minetest.register_chatcommand("invisible", {
    params = "",
    description = "",
    privs = {gdac_invis=true},
    func = function(...)
      return gdac_invis.toggle_invisibility(...)
    end,
  })
  
  minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    gdac_invis.players[name] = nil
  end)
  
  -- Reloadable.
  local file = gdac_invis.modpath .. "/init.lua"
  local name = "gdac_invis:core"
  reload.register_file(name, file, false)
  
  gdac_invis.run_once = true
end


