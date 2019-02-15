-- function only loaded on specific dofile command from game console.
function throwing_arrow_punch_entity (obj, self, damage)
  local player = minetest.get_player_by_name(self.player_name or "")
  if player and player:is_player() then
		if obj:is_player() then
			-- If target is a player, and not a mob, we can't use the shooter as the
			-- attacker. This would only actually apply damage if the shooter was a
			-- short distance from the target. So for this case, we have to "fake" the
			-- target punching themselves.
			obj:punch(self.object, 1.0, {
				full_punch_interval=1.0,
				damage_groups={fleshy=damage},
			}, nil)
		else
			-- The target of the arrow (a mob) sees the shooter as the attacker,
			-- *not* the arrow entity itself. If this were not so, players
			-- could shoot mobs with arrows without retaliation.
			obj:punch(player, 1.0, {
				full_punch_interval=1.0,
				damage_groups={fleshy=damage},
			}, nil)
		end
  else
		-- Shooter logged off game after firing arrow. Use basic fallback.
    obj:punch(self.object, 1.0, {
      full_punch_interval=1.0,
      damage_groups={fleshy=damage},
    }, nil)
  end
end
