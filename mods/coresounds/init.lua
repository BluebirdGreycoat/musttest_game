
default = default or {}
coresounds = coresounds or {}
coresounds.modpath = minetest.get_modpath("coresounds")

function coresounds.play_sound_node_place(pos, nn)
	local def = minetest.registered_nodes[nn]
	if not def then return end

	if def and def.sounds and def.sounds.place then
		local sound = def.sounds.place
		if not sound.name or not sound.gain then return end
		ambiance.sound_play(sound.name, pos, sound.gain, 20)
	end
end

function coresounds.play_sound_node_dug(pos, nn)
	local def = minetest.registered_nodes[nn]
	if not def then return end

	if def and def.sounds and def.sounds.dug then
		local sound = def.sounds.dug
		if not sound.name or not sound.gain then return end
		ambiance.sound_play(sound.name, pos, sound.gain, 20)
	end
end



function default.node_sound_defaults(table)
	table = table or {}
	table.footstep = table.footstep or {name = "", gain = 1.0}
	table.dug = table.dug or {name = "default_dug_node", gain = 0.25}
	table.place = table.place or {name = "default_place_node_hard", gain = 1.0}
	return table
end



function default.node_sound_stone_defaults(table)
	table = table or {}
	table.footstep = table.footstep or {name = "default_hard_footstep", gain = 0.5}
	table.dug = table.dug or {name = "default_hard_footstep", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end



function default.node_sound_dirt_defaults(table)
	table = table or {}
	table.footstep = table.footstep or {name = "default_dirt_footstep", gain = 1.0}
	table.dug = table.dug or {name = "default_dirt_footstep", gain = 1.5}
	table.place = table.place or {name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end



function default.node_sound_sand_defaults(table)
	table = table or {}
	table.footstep = table.footstep or {name = "default_sand_footstep", gain = 0.12}
	table.dug = table.dug or {name = "default_sand_footstep", gain = 0.24}
	table.place = table.place or {name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end



function default.node_sound_gravel_defaults(table)
	table = table or {}
	table.footstep = table.footstep or {name = "default_gravel_footstep", gain = 0.5}
	table.dug = table.dug or {name = "default_gravel_footstep", gain = 1.0}
	table.place = table.place or {name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end



function default.node_sound_wood_defaults(table)
	table = table or {}
	table.footstep = table.footstep or {name = "default_wood_footstep", gain = 0.5}
	table.dug = table.dug or {name = "default_wood_footstep", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end



function default.node_sound_leaves_defaults(table)
	table = table or {}
	table.footstep = table.footstep or {name = "default_grass_footstep", gain = 0.35}
	table.dug = table.dug or {name = "default_grass_footstep", gain = 0.7}
	table.dig = table.dig or {name = "default_dig_snappy", gain = 0.4}
	table.place = table.place or {name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end



function default.node_sound_glass_defaults(table)
	table = table or {}
	table.footstep = table.footstep or {name = "default_glass_footstep", gain = 0.5}
	table.dug = table.dug or {name = "default_break_glass", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end



function default.node_sound_metal_defaults(table)
	table = table or {}
	table.footstep = table.footstep or {name = "default_metal_footstep", gain = 0.5}
	table.dig = table.dig or {name = "default_dig_metal", gain = 0.5}
	table.dug = table.dug or {name = "default_dug_metal", gain = 0.5}
	table.place = table.place or {name = "default_place_node_metal", gain = 0.5}
	default.node_sound_defaults(table)
	return table
end



function default.node_sound_snow_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_snow_footstep", gain = 0.2}
	table.dig = table.dig or
			{name = "default_snow_footstep", gain = 0.3}
	table.dug = table.dug or
			{name = "default_snow_footstep", gain = 0.3}
	table.place = table.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end


function default.node_sound_water_defaults(table)
	table = table or {}
	table.footstep = table.footstep or {name = "default_water_footstep", gain = 0.2}
	default.node_sound_defaults(table)
	return table
end



minetest.register_on_dignode(function(pos, oldnode, digger)
    if not digger then return end
    if not digger:is_player() then return end

    local n = minetest.registered_nodes[oldnode.name]
    if not n then return end
    
    if n.sounds then
        local file = ""
        local gain = 1.0
        
        if n.sounds.dug then
            local s = n.sounds.dug
            file = s.name
            gain = s.gain
        elseif n.sounds.dig then
            local s = n.sounds.dig
            file = s.name
            gain = s.gain
        elseif n.sounds.footstep then
            local s = n.sounds.footstep
            file = s.name
            gain = s.gain
        end
        
        if file ~= "" then
            ambiance.sound_play(file, pos, gain, 20, digger:get_player_name())
        end
    end
end)



minetest.register_on_placenode(function(pos, oldnode, digger)
  if not digger then return end
  if not digger:is_player() then return end

  local n = minetest.registered_nodes[oldnode.name]
  if not n then return end
  
  if n.sounds then
    local file = ""
    local gain = 1.0
    
    if n.sounds.place then
      local s = n.sounds.place
      file = s.name
      gain = s.gain
    elseif n.sounds.dig then
      local s = n.sounds.dig
      file = s.name
      gain = s.gain
    elseif n.sounds.footstep then
      local s = n.sounds.footstep
      file = s.name
      gain = s.gain
    end
    
    if file ~= "" then
      ambiance.sound_play(file, pos, gain, 30, digger:get_player_name())
    end
  end
end)



local random = math.random
minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
  if not puncher then return end
  if not puncher:is_player() then return end

	if random(1, 5) == 1 then
		ambiance.particles_on_punch(pos, node)
	end
  
  local ndef = minetest.registered_items[node.name]
  if not ndef then return end
  local ngroups = ndef.groups or {}
  local nsounds = ndef.sounds or {}
  
  local file = ""
  local gain = 1.0
  
  -- By default, the punch sound is the sound the tool makes, if the node is diggable by the tool.
  local wielded = puncher:get_wielded_item()
  local wieldef = minetest.registered_items[wielded:get_name()]
  if wieldef then
    local tool_capabilities = wieldef.tool_capabilities
    if tool_capabilities then
      local groupcaps = tool_capabilities.groupcaps
      if groupcaps then
        if groupcaps.oddly_breakable_by_hand then
          if ngroups.oddly_breakable_by_hand and ngroups.oddly_breakable_by_hand > 0 then
            file = "default_dig_oddly_breakable_by_hand"
            -- Node digging sounds (if defined) override tool digging sounds.
            if nsounds.dig then
              file = nsounds.dig.name
              gain = nsounds.dig.gain
            end
          end
        elseif groupcaps.cracky then
          if ngroups.cracky and ngroups.cracky > 0 then
            file = "default_dig_cracky"
            -- Node digging sounds (if defined) override tool digging sounds.
            if nsounds.dig then
              file = nsounds.dig.name
              gain = nsounds.dig.gain
            end
          end
        elseif groupcaps.choppy then
          if ngroups.choppy and ngroups.choppy > 0 then
            file = "default_dig_choppy"
            -- Node digging sounds (if defined) override tool digging sounds.
            if nsounds.dig then
              file = nsounds.dig.name
              gain = nsounds.dig.gain
            end
          end
        elseif groupcaps.crumbly then
          if ngroups.crumbly and ngroups.crumbly > 0 then
            file = "default_dig_crumbly"
            -- Node digging sounds (if defined) override tool digging sounds.
            if nsounds.dig then
              file = nsounds.dig.name
              gain = nsounds.dig.gain
            end
          end
        elseif groupcaps.snappy then
          if ngroups.snappy and ngroups.snappy > 0 then
            file = "default_dig_snappy"
            -- Node digging sounds (if defined) override tool digging sounds.
            if nsounds.dig then
              file = nsounds.dig.name
              gain = nsounds.dig.gain
            end
          end
        end
      end
    else
      -- If the wielded item has no tool capabilities defined, assume it is the wieldhand.
      if ngroups.oddly_breakable_by_hand and ngroups.oddly_breakable_by_hand > 0 then
        file = "default_dig_oddly_breakable_by_hand"
        -- Node digging sounds (if defined) override tool digging sounds.
        if nsounds.dig then
          file = nsounds.dig.name
          gain = nsounds.dig.gain
        end
      end
    end
  else
    -- If the wielded item does not appear to be defined, assume it is the wieldhand.
    if ngroups.oddly_breakable_by_hand and ngroups.oddly_breakable_by_hand > 0 then
      file = "default_dig_oddly_breakable_by_hand"
      -- Node digging sounds (if defined) override tool digging sounds.
      if nsounds.dig then
        file = nsounds.dig.name
        gain = nsounds.dig.gain
      end
    end
  end
  
  -- If the node is breakable by hand, and no sound has been defined yet,
  -- then just use the `oddly_breakable_by_hand` digging sound. This catches
  -- cases where the player uses an incorrect tool for a given node, but the
  -- node is still diggable by hand (the server allows the node to be dug).
  if file == "" and ngroups.oddly_breakable_by_hand and ngroups.oddly_breakable_by_hand > 0 then
    file = "default_dig_oddly_breakable_by_hand"
  elseif file == "" and ngroups.crumbly and ngroups.crumbly > 0 then
    file = "default_dig_crumbly"
  elseif file == "" and ngroups.snappy and ngroups.snappy > 0 then
    file = "default_dig_snappy"
  end
  
  if file ~= "" then
    local pname = puncher:get_player_name()
    ambiance.sound_play(file, pos, gain, 30, pname)
  end
end)



