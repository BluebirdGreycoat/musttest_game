
heal = heal or {}
heal.modpath = minetest.get_modpath("heal")



minetest.register_privilege("heal", {
  description = "Player can heal other players or themselves.",
  give_to_singleplayer = false,
})



-- API function, can be called by other mods.
function heal.heal_health_and_hunger(pname)
  local player = minetest.get_player_by_name(pname)
  if not player then return end
  player:set_hp(player:get_properties().hp_max)
  hunger.update_hunger(player, 30)
	sprint.set_stamina(player, SPRINT_STAMINA)
	portal_sickness.reset(pname)
end



minetest.register_chatcommand("heal", {
  params = "[playername]",
  description = "Heal specified player, or heal self if called without arguments.",
  privs = {heal=true},
  func = function(name, param)
    if param == nil or param == "" then
      minetest.chat_send_player(name, "# Server: Healing player <" .. rename.gpn(name) .. ">.")
      heal.heal_health_and_hunger(name)
      return true
    end
    
    assert(type(param) == "string")
    local player = minetest.get_player_by_name(param)
    if not player then
      minetest.chat_send_player(name, "# Server: Player <" .. rename.gpn(param) .. "> not found.")
      return false
    end
    
    minetest.chat_send_player(name, "# Server: Healing player <" .. rename.gpn(param) .. ">.")
    minetest.chat_send_player(param, "# Server: Player <" .. rename.gpn(name) .. "> healed you.")
    heal.heal_health_and_hunger(param)
    return true
  end
})
