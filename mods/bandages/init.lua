
if not minetest.global_exists("bandages") then bandages = {} end
bandages.modpath = minetest.get_modpath("bandages")
bandages.players = bandages.players or {}

-- Localize vector.distance() for performance.
local vector_distance = vector.distance
local math_floor = math.floor



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
		return 6
	elseif level == 3 then
		return 1
	end
	return 0
end

bandages.hp_from_level = function(level, hp, hp_max)
  local heal = 0

  -- Hmm hmm hmmm, I'm a genius.
  local function mod1(hp, max)
    local a = (hp / hp_max)
    return a * a
  end

  -- This function is proof that I failed algebra.
  -- There's a way to do this in one line with no conditional, I just can't
  -- figure out what it is.
  local function mod2(hp, max)
    local a = hp / max
    local b

    if a <= 0.5 then
      b = a / 0.5
    else
      b = ((a - 0.5) / 0.5) * -1 + 1
    end

    return b * b
  end

  -- But this function makes me feel better.
  local function mod3(hp, max)
    local a = ((hp / hp_max) * -1 + 1)
    return a * a
  end

  if level == 1 then
    -- You receive the maximum heal bonus if you are only slightly hurt.
    -- Simple bandages become worse for the job the more hurt you are.
    heal = hp_max * 0.1 * mod1(hp, hp_max)
  elseif level == 2 then
    -- You get the most benefit from the basic medkit when used to heal
    -- non-lifethreatening wounds which need more care than a simple bandaging.
    heal = hp_max * 0.15 * mod2(hp, hp_max)
  elseif level == 3 then
    -- Trama medkits are best used on severe injuries. Using them for light
    -- scrapes is wasteful, and provides little benefit.
    heal = hp_max * 0.3 * mod3(hp, hp_max)
  end

  return heal
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

bandages.target_not_hurt = function(pname, tname)
  minetest.chat_send_player(pname, "# Server: <" .. rename.gpn(tname) .. "> is not wounded.")
	--easyvend.sound_error(pname)
end

bandages.player_not_hurt = function(pname)
  minetest.chat_send_player(pname, "# Server: You are not wounded.")
	--easyvend.sound_error(pname)
end

bandages.player_bandages_self = function(pname, hp, hp_max)
  local pc = math_floor((hp / hp_max) * 100)
  minetest.chat_send_player(pname, "# Server: You use bandages on yourself. Your health is now " .. pc .. "%.")
end

bandages.target_is_dead = function(pname, tname)
  minetest.chat_send_player(pname, "# Server: <" .. rename.gpn(tname) .. "> is dead!")
	--easyvend.sound_error(pname)
end

bandages.player_is_dead = function(pname)
  minetest.chat_send_player(pname, "# Server: You are dead!")
	--easyvend.sound_error(pname)
end

bandages.player_bandages_target = function(pname, tname, hp, hp_max)
  local pc = math_floor((hp / hp_max) * 100)

  minetest.chat_send_player(tname, "# Server: Player <" .. rename.gpn(pname) .. "> used a bandage on you.")
  minetest.chat_send_player(pname, "# Server: <" .. rename.gpn(tname) .. ">'s health improves to " .. pc .. "%.")
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
    return 32
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



function bandages.heal_target(itemstack, user, target, level)
  local pname = user:get_player_name()
	local tname = target:get_player_name()
	local hp = target:get_hp()
	local hp_max = target:get_properties().hp_max

	if hp >= hp_max then
		return bandages.target_not_hurt(pname, tname)
	end
	if hp <= 0 then
		return bandages.target_is_dead(pname, tname)
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
		if vector_distance(target:get_pos(), pos) > bandages.movement_limit_from_level(level) then
			return bandages.target_moved_too_much(pname, tname)
		end

		-- Don't heal target if already dead.
		-- This solves an exploit people have found.
		if hp == 0 then return end
		target:set_hp(hp + bandages.hp_from_level(level, hp, hp_max))
		bandages.player_bandages_target(pname, tname, target:get_hp(), hp_max)
	end)

	itemstack:take_item()
	return itemstack
end



function bandages.heal_self(itemstack, user, level)
  local pname = user:get_player_name()
	local hp = user:get_hp()
	local hp_max = user:get_properties().hp_max

	if hp >= hp_max then
		return bandages.player_not_hurt(pname)
	end
	if hp <= 0 then
		return bandages.player_is_dead(pname)
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
		if vector_distance(user:get_pos(), pos) > bandages.movement_limit_from_level(level) then
			return bandages.player_moved_too_much(pname)
		end

		-- Don't heal user if already dead.
		-- This solves an exploit people have found.
		if hp == 0 then return end
		user:set_hp(hp + bandages.hp_from_level(level, hp, hp_max))
		bandages.player_bandages_self(pname, user:get_hp(), hp_max)
	end)

	itemstack:take_item()
	return itemstack
end



bandages.use_bandage = function(itemstack, user, pointed_thing, level)
  if not user or not user:is_player() then return end
  
  if pointed_thing.type == "object" then
    local target = pointed_thing.ref
    if not target or not target:is_player() then
			return bandages.heal_self(itemstack, user, level)
    end

		return bandages.heal_target(itemstack, user, target, level)
  else
		return bandages.heal_self(itemstack, user, level)
  end
end



-- Execute registrations once only.
if not bandages.registered then
  minetest.register_craftitem("bandages:bandage_1", {
    description = "Simple Bandage\n\nBest used for light scrapes and scratches.\nUse on yourself or another.",
    inventory_image = "bandage_1.png",
    on_use = function(itemstack, user, pointed_thing) 
      return bandages.use_bandage(itemstack, user, pointed_thing, 1) 
    end,
  })

  minetest.register_craftitem("bandages:bandage_2", {
    description = "Basic Medkit\n\nHeals moderate wounds (best around 50% health).\nUse on yourself or another.",
    inventory_image = "bandage_2.png",
    on_use = function(itemstack, user, pointed_thing) 
      return bandages.use_bandage(itemstack, user, pointed_thing, 2) 
    end,
  })

  minetest.register_craftitem("bandages:bandage_3", {
    description = "Trauma Medkit\n\nAids in recovery from severe, debilitating injuries.\nUse on yourself or another.",
    inventory_image = "bandage_3.png",
    on_use = function(itemstack, user, pointed_thing) 
      return bandages.use_bandage(itemstack, user, pointed_thing, 3) 
    end,
  })

  minetest.register_craft({
    output = 'bandages:bandage_1 3',
    recipe = {
      {'default:paper', 'farming:string', 'default:paper'},
    }
  })

  minetest.register_craft({
    output = 'bandages:bandage_2 3',
    recipe = {
      {'default:paper', 'farming:cloth', 'default:paper'},
    }
  })

  minetest.register_craft({
    output = 'bandages:bandage_3 3',
    recipe = {
			{'', 'aloevera:aloe_gel', ''},
      {'default:paper', 'farming:cloth', 'default:paper'},
			{'', 'dye:green', ''},
    }
  })
    
  bandages.registered = true
end

