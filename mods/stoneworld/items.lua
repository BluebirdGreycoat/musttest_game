
--------------------------------------------------------------------------------
-- Special item that lets you revive a dead player in-place, provided they have
-- not pressed the "respawn" button. Remember gents, there's no such thing as
-- "dead". There's only "mostly dead" and "mostly dead" means "slightly alive"!
function stoneworld.oerkki_scepter(itemstack, user, pt)
  if pt.type == "object" and user and user:is_player() then
    local pname = user:get_player_name()
    local pref = pt.ref
    if pref:is_player() then
      local hp = pref:get_hp()
      local tname = pref:get_player_name()
      if hp <= 0 and pname ~= tname then
        -- Target is another player and player is dead. Revive player.
        -- This will bypass the respawn code, and player should revive in place.
        local hp_max = pref:get_properties().hp_max
        pref:set_hp(math.max(1, math.floor(hp_max * 0.01)))
        ambiance.sound_play("default_cool_lava", pref:get_pos(), 1.0, 32)
        minetest.chat_send_player(pname, "# Server: You revived <" .. rename.gpn(tname) .. ">.")
        minetest.chat_send_player(tname, "# Server: You were revived by <" .. rename.gpn(pname) .. ">.")
      end
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
	on_secondary_use = stoneworld.oerkki_scepter,

  -- Using it on a live player? >:)
  -- Damage info is stored by sysdmg.
	tool_capabilities = {
    full_punch_interval = 3.0,
  },
})

-- Not craftable. Item is loot ONLY.
--------------------------------------------------------------------------------
