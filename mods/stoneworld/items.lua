
--------------------------------------------------------------------------------
-- Special item that lets you revive a dead player in-place, provided they have
-- not pressed the "respawn" button. Remember gents, there's no such thing as
-- "dead". There's only "mostly dead" and "mostly dead" means "slightly alive"!
local function scepter_revive_player(tref, tname, pname, pos)
  if pos then
    rc.notify_realm_update(tref, pos)
    tref:set_pos(pos)
  end

  preload_tp.spawn_spinup_particles(tref:get_pos(), 1)
  ambiance.sound_play("nether_portal_usual", tref:get_pos(), 1.0, 30)

  local hp_max = tref:get_properties().hp_max
  tref:set_hp(hp_max, {reason="revive"})
  minetest.close_formspec(tname, "") -- Close the respawn formspec.
  ambiance.sound_play("default_cool_lava", tref:get_pos(), 1.0, 32)
  minetest.chat_send_player(pname, "# Server: You revived <" .. rename.gpn(tname) .. ">.")
  minetest.chat_send_player(tname, "# Server: You were revived by <" .. rename.gpn(pname) .. ">.")
end



local function scepter_hit_bones(itemstack, user, pt)
  --minetest.log('scepter hit bones')

  -- Collect information.
  local pname = user:get_player_name()
  local pos = pt.under
  local node = minetest.get_node(pos)
  local meta = minetest.get_meta(pos)
  local owner = meta:get_string("owner")
  local tref = minetest.get_player_by_name(owner)
  local bones_death_time = tonumber(meta:get_string("death_time")) or 0

  ambiance.sound_play("nether_extract_blood", pos, 1.0, 30)

  -- Player must be logged in.
  if not tref or not tref:is_player() then
    --minetest.log('ghost not logged in')
    return
  end

  -- Player must be dead.
  if tref:get_hp() > 0 then
    --minetest.log('ghost not dead')
    return
  end

  local tname = tref:get_player_name()
  local player_meta = tref:get_meta()
  local player_death_time = tonumber(player_meta:get_string("last_death_time")) or 0
  local player_bones_time = tonumber(player_meta:get_string("last_bones_time")) or 0
  local player_bones_pos = minetest.string_to_pos(player_meta:get_string("last_bones_pos"))
  local player_respawn_time = tonumber(player_meta:get_string("last_respawn_time")) or 0

  -- Determine if player can be revived from these bones.

  -- Time must be valid.
  if bones_death_time == 0 or player_death_time == 0 or player_bones_time == 0 then
    --minetest.log('times not valid')
    return
  end

  -- Player's last bones position must be known.
  if not player_bones_pos then
    --minetest.log('bone pos not valid')
    return
  end

  -- Bones time must match player's last death time.
  if bones_death_time ~= player_death_time then
    --minetest.log('death times don\'t match')
    return
  end

  -- Bones position must match player's last bones position.
  if not vector.equals(pos, player_bones_pos) then
    --minetest.log('bone positions don\'t match')
    return
  end

  -- Player's last respawn must be prior to their last death time.
  if player_respawn_time >= player_death_time then
    --minetest.log('respawn time too soon')
    return
  end

  -- Player's last bones time must match their last death time.
  if player_bones_time ~= player_death_time then
    --minetest.log('bones time doesn\'t match death time')
    return
  end

  -- Player's last respawn must be older than these bones.
  if player_respawn_time >= bones_death_time then
    --minetest.log('player respawned already')
    return
  end

  -- Everything looks in order. Revive player.
  scepter_revive_player(tref, tname, pname, pos)
end



local function scepter_hit_player(itemstack, user, pt)
  local pname = user:get_player_name()
  local tref = pt.ref

  ambiance.sound_play("nether_extract_blood", tref:get_pos(), 1.0, 30)

  local hp = tref:get_hp()
  local tname = tref:get_player_name()

  if hp <= 0 and pname ~= tname then
    -- Target is another player and player is dead. Revive player.
    -- This will bypass the respawn code, and player should revive in place.
    scepter_revive_player(tref, tname, pname)
  end
end



function stoneworld.oerkki_scepter(itemstack, user, pt)
  if user and user:is_player() then
    if pt.type == "node" and minetest.get_node(pt.under).name == "bones:bones" then
      scepter_hit_bones(itemstack, user, pt)
    elseif pt.type == "object" and pt.ref and pt.ref:is_player() then
      scepter_hit_player(itemstack, user, pt, nil)
    end
  end
end



-- They say the elite oerkki used it when they wanted to interrogate a prisoner
-- harshly. But it can be repurposed for teamwork assistance.
minetest.register_tool("stoneworld:oerkki_scepter", {
	description = "Interrogation Prod",
	inventory_image = "stoneworld_oerkki_staff.png",

	-- Tools with dual-use functions MUST put the secondary use in this callback,
	-- otherwise normal punches do not work!
	on_place = stoneworld.oerkki_scepter,
	on_secondary_use = stoneworld.oerkki_scepter,

  -- Using it on a live player? >:)
  -- Damage info is stored by sysdmg.
	tool_capabilities = {
    full_punch_interval = 3.0,
  },
})

-- Not craftable. Item is loot ONLY.
--------------------------------------------------------------------------------
