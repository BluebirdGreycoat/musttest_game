
local STOMP_RADIUS = 2.5



local function boast(stomper, target)
  local pname = stomper:get_player_name()
	if spam.test_key("stomper" .. pname .. "9353") then
		return
	end
	spam.mark_key("stomper" .. pname .. "9353", 30)

  if target:is_player() then
    local tname = target:get_player_name()
    minetest.chat_send_all("# Server: <" .. rename.gpn(pname) .. "> stomped on <" .. rename.gpn(tname) .. ">'s head.")
  else
    minetest.chat_send_all("# Server: <" .. rename.gpn(pname) .. "> stomped on a mob's head.")
  end
end



local function stomp_em(stomper, target, damage)
  -- Ignore dead players.
  if target:is_player() and target:get_hp() == 0 then
    return
  end

  target:punch(stomper, 1.0, {
    full_punch_interval = 1.0,
    damage_groups = {crush = damage, from_stomp = 0},
  }, nil)--{x=0, y=0.01, z=0})

  --minetest.log('stomping! ' .. target:get_player_name() .. ": " .. damage)

  if target:is_player() and target:get_hp() == 0 then
    boast(stomper, target)
  end
end



local function do_stomp(pname, pos, damage)
  local stomper = minetest.get_player_by_name(pname)
  if not stomper then
    return
  end

  local objs = minetest.get_objects_inside_radius(pos, STOMP_RADIUS)

  for k, v in ipairs(objs) do
    if v:is_player() and v:get_player_name() ~= pname then
      stomp_em(stomper, v, damage)
    else
      local ent = v:get_luaentity()
      if ent and ent.mob then
        stomp_em(stomper, v, damage)
      end
    end
  end
end



function armor.stomp_at(stomper, pos, damage)
  local pname = stomper:get_player_name()
  local objs = minetest.get_objects_inside_radius(pos, STOMP_RADIUS)
  local stomped = false

  -- Check if we're going to stomp anybody.
  for k, v in ipairs(objs) do
    if v:is_player() and v:get_player_name() ~= pname then
      -- Ignore the dead ones.
      if v:get_hp() > 0 then
        stomped = true
      end
    else
      local ent = v:get_luaentity()
      if ent and ent.mob then
        stomped = true
      end
    end
  end

  -- Must execute on the next server step, to avoid conflict with currently
  -- running armor/hp-change code.
  minetest.after(0, function() do_stomp(pname, pos, damage) end)

  return stomped
end
