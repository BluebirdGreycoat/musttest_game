
bandages = bandages or {}
bandages.modpath = minetest.get_modpath("bandages")
bandages.players = bandages.players or {}



if minetest.get_modpath("reload") then
  local c = "bandages:core"
  local f = bandages.modpath .. "/init.lua"
  if not reload.file_registered(c) then
    reload.register_file(c, f, false)
  end
end



bandages.movement_limit_from_level = function(level)
	if level == 1 then
		return 20
	elseif level == 2 then
		return 5
	elseif level == 3 then
		return 2
	end
	return 0
end

bandages.hp_from_level = function(level)
  if level == 1 then
    return 2
  elseif level == 2 then
    return 3
  elseif level == 3 then
    return 6
  end
  return 0
end

bandages.delay_from_level = function(level)
  if level == 1 then
    return 1.5
  elseif level == 2 then
    return 2.0
  elseif level == 3 then
    return 2.5
  end
  return 0
end

bandages.target_not_player = function(pname)
  minetest.chat_send_player(pname, "# Server: Target is not a player.")
	--easyvend.sound_error(pname)
end

bandages.target_not_hurt = function(pname, tname)
  minetest.chat_send_player(pname, "# Server: Player <" .. rename.gpn(tname) .. "> is not wounded.")
	--easyvend.sound_error(pname)
end

bandages.player_not_hurt = function(pname)
  minetest.chat_send_player(pname, "# Server: You are not harmed.")
	--easyvend.sound_error(pname)
end

bandages.player_bandages_self = function(pname, hp)
  minetest.chat_send_player(pname, "# Server: You use bandages on yourself. Your health is now " .. hp .. "/20 HP.")
end

bandages.target_is_dead = function(pname, tname)
  minetest.chat_send_player(pname, "# Server: Player <" .. rename.gpn(tname) .. "> is dead!")
	--easyvend.sound_error(pname)
end

bandages.player_is_dead = function(pname)
  minetest.chat_send_player(pname, "# Server: You are dead!")
	--easyvend.sound_error(pname)
end

bandages.player_bandages_target = function(pname, tname, hp)
  minetest.chat_send_player(tname, "# Server: Player <" .. rename.gpn(pname) .. "> used a bandage on you.")
  minetest.chat_send_player(pname, "# Server: <" .. rename.gpn(tname) .. ">'s health improves to " .. hp .. "/20 HP.")
end

bandages.medkit_already_in_use = function(pname)
  minetest.chat_send_player(pname, "# Server: You are already using a medkit; wait to be done.")
	--easyvend.sound_error(pname)
end

bandages.player_moved_too_much = function(pname)
  minetest.chat_send_player(pname, "# Server: You must hold still while using a medkit!")
	--easyvend.sound_error(pname)
end

bandages.target_moved_too_much = function(pname, tname)
  minetest.chat_send_player(pname, "# Server: Player <" .. rename.gpn(tname) .. "> must hold still for you to use medkit!")
  minetest.chat_send_player(tname, "# Server: Player <" .. rename.gpn(pname) .. "> is trying to use a medkit on you; hold still!")
	--easyvend.sound_error(pname)
end

bandages.get_sound_range_from_level = function(level)
  if level == 1 then
    return 8
  elseif level == 2 then
    return 16
  elseif level == 3 then
    return 24
  end
  return 0
end

bandages.get_sound_gain_from_level = function(level)
  if level == 1 then
    return 0.5
  elseif level == 2 then
    return 0.7
  elseif level == 3 then
    return 1.0
  end
  return 0
end

bandages.play_sound_effects = function(pos, level)
  local range = bandages.get_sound_range_from_level(level)
  local gain = bandages.get_sound_gain_from_level(level)
  ambiance.sound_play("bandages_bandaging", pos, gain, range)
  -- Increase length of sound effect for higher levels.
  if level >= 2 then
    minetest.after(1.0, function()
      ambiance.sound_play("bandages_bandaging", pos, gain, range)
    end)
  end
  if level >= 3 then
    minetest.after(2.0, function()
      ambiance.sound_play("bandages_bandaging", pos, gain, range)
    end)
  end
end

bandages.get_max_damage_for_level = function(level, hp, hp_max)
	if level == 3 then
		return 1
	elseif level == 2 then
		return (hp_max / 3)
	elseif level == 1 then
		return (hp_max / 5) * 4
	end
	return 0
end

bandages.target_too_hurt = function(pname, tname, level)
  minetest.chat_send_player(pname, "# Server: Player <" .. rename.gpn(tname) .. "> is too severely hurt for a level " .. level .. " medkit.")
	--easyvend.sound_error(pname)
end

bandages.player_too_hurt = function(pname, level)
  minetest.chat_send_player(pname, "# Server: You are too severely hurt for a level " .. level .. " medkit.")
	--easyvend.sound_error(pname)
end



bandages.use_bandage = function(itemstack, user, pointed_thing, level)
  if not user or not user:is_player() then return end
  local pname = user:get_player_name()
  
  if pointed_thing.type == "object" then
    local target = pointed_thing.ref
    if not target or not target:is_player() then
      return bandages.target_not_player(pname)
    end
    local tname = target:get_player_name()
    local hp = target:get_hp()
		local hp_max = target:get_properties().hp_max
    
    if hp >= hp_max then
      return bandages.target_not_hurt(pname, tname)
    end
    if hp <= 0 then
      return bandages.target_is_dead(pname, tname)
    end
    if hp < bandages.get_max_damage_for_level(level, hp, hp_max) then
      return bandages.target_too_hurt(pname, tname, level)
    end
    if bandages.players[pname] or bandages.players[tname] then
      return bandages.medkit_already_in_use(pname)
    end
    
    bandages.play_sound_effects(target:get_pos(), level)

    bandages.players[tname] = {pos=target:get_pos()}
    bandages.players[pname] = {pos=user:get_pos()}
    minetest.after(bandages.delay_from_level(level), function()
      local pos = bandages.players[tname].pos
      bandages.players[tname] = nil
      bandages.players[pname] = nil
      local target = minetest.get_player_by_name(tname)
      if not target or not target:is_player() then return end
      if vector.distance(target:get_pos(), pos) > bandages.movement_limit_from_level(level) then
        return bandages.target_moved_too_much(pname, tname)
      end
			-- Don't heal target if already dead.
			-- This solves an exploit people have found.
			if target:get_hp() == 0 then return end
      target:set_hp(hp + bandages.hp_from_level(level))
      bandages.player_bandages_target(pname, tname, target:get_hp())
    end)
    
    itemstack:take_item()
    return itemstack
  else
    -- Otherwise, try to heal self.
    local hp = user:get_hp()
		local hp_max = target:get_properties().hp_max

    if hp >= hp_max then
      return bandages.player_not_hurt(pname)
    end
    if hp <= 0 then
      return bandages.player_is_dead(pname)
    end
    if hp < bandages.get_max_damage_for_level(level, hp, hp_max) then
      return bandages.player_too_hurt(pname, level)
    end
    if bandages.players[pname] then
      return bandages.medkit_already_in_use(pname)
    end
    
    bandages.play_sound_effects(user:get_pos(), level)
  
    bandages.players[pname] = {pos=user:get_pos()}
    minetest.after(bandages.delay_from_level(level), function()
      local pos = bandages.players[pname].pos
      bandages.players[pname] = nil
      local user = minetest.get_player_by_name(pname)
      if not user or not user:is_player() then return end
      if vector.distance(user:get_pos(), pos) > bandages.movement_limit_from_level(level) then
        return bandages.player_moved_too_much(pname)
      end
			-- Don't heal user if already dead.
			-- This solves an exploit people have found.
			if user:get_hp() == 0 then return end
      user:set_hp(hp + bandages.hp_from_level(level))
      bandages.player_bandages_self(pname, user:get_hp())
    end)
    
    itemstack:take_item()
    return itemstack
  end
end



-- Execute registrations once only.
if not bandages.registered then
  minetest.register_craftitem("bandages:bandage_1", {
    description = "Simple Bandage\n\nHeals light scrapes and scratches.\nUse on yourself or another.",
    inventory_image = "bandage_1.png",
    on_use = function(itemstack, user, pointed_thing) 
      return bandages.use_bandage(itemstack, user, pointed_thing, 1) 
    end,
  })

  minetest.register_craftitem("bandages:bandage_2", {
    description = "Basic Medkit\n\nHeals wounds.\nUse on yourself or another.",
    inventory_image = "bandage_2.png",
    on_use = function(itemstack, user, pointed_thing) 
      return bandages.use_bandage(itemstack, user, pointed_thing, 2) 
    end,
  })

  minetest.register_craftitem("bandages:bandage_3", {
    description = "Trauma Medkit\n\nHeals player from severe wounds.\nUse on yourself or another.",
    inventory_image = "bandage_3.png",
    on_use = function(itemstack, user, pointed_thing) 
      return bandages.use_bandage(itemstack, user, pointed_thing, 3) 
    end,
  })

  minetest.register_craft({
    output = 'bandages:bandage_1 2',
    recipe = {
      {'default:paper', 'default:paper', 'default:paper'},
    }
  })

  minetest.register_craft({
    output = 'bandages:bandage_2 2',
    recipe = {
      {'default:paper', 'wool:white', 'default:paper'},
    }
  })

  minetest.register_craft({
    output = 'bandages:bandage_3 2',
    recipe = {
      {'default:paper', 'wool:green', 'default:paper'},
    }
  })
    
  bandages.registered = true
end

