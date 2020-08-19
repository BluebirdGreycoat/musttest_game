
function pm.hurt_nearby_players(self)
	local pos = self.object:get_pos()
	local players = minetest.get_connected_players()
	for k, v in ipairs(players) do
		if vector.distance(pos, v:get_pos()) < 2 then
			v:set_hp(v:get_hp() - 1)
		end
	end
end

function pm.heal_nearby_players(self)
	local pos = self.object:get_pos()
	local players = minetest.get_connected_players()
	for k, v in ipairs(players) do
		if vector.distance(pos, v:get_pos()) < 2 then
			v:set_hp(v:get_hp() + 1)
		end
	end
end

function pm.steal_nearby_item(self, target)
	if target then
		if target:is_player() then
			local inv = target:get_inventory()
			local max = inv:get_size("main")
			local idx = math.random(1, max)
			local stack = inv:get_stack("main", idx)
			if not passport.is_passport(stack:get_name()) then
				if stack:get_count() > 1 then
					local item = stack:take_item()
					inv:set_stack("main", idx, stack)
					minetest.item_drop(item, target, self.object:get_pos())
				end
			end
		else
			local ent = target:get_luaentity()
			if ent.name == "__builtin:item" then
				target:remove()
			end
		end
	end
end

function pm.explode_nearby_target(self, target)
	if target then
		tnt.boom(self.object:get_pos(), {
			radius = 2,
			damage_radius = 3,
			ignore_protection = false,
			ignore_on_blast = false,
			disable_drops = true,
		})
	end
end
