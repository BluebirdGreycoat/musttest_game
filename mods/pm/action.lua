
-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round
local math_random = math.random



local function throw_player(e, p)
	local p1 = e:get_pos()
	local p2 = p:get_pos()
	p1.y = p2.y
	local vel = vector.subtract(p2, p1)
	vel = vector.normalize(vel)
	vel = vector.add(vel, {x=0, y=0.5, z=0})
	vel = vector.multiply(vel, 10)
	p:add_player_velocity(vel)
end

function pm.shove_player(self, target)
	if target and target:is_player() then
		throw_player(self.object, target)
	end
end

function pm.hurt_nearby_players(self)
	local pos = self.object:get_pos()
	local players = minetest.get_connected_players()
	for k, v in ipairs(players) do
		if vector_distance(pos, v:get_pos()) < 2 then
			throw_player(self.object, v)
			v:set_hp(v:get_hp() - 1)
		end
	end
end

function pm.hurt_nearby_player_or_mob_not_wisp(self)
	local pos = self.object:get_pos()
	local objects = pm.get_nearby_objects(self, pos, 2)
	for k, v in ipairs(objects) do
		if v:is_player() then
			throw_player(self.object, v)
			v:set_hp(v:get_hp() - 1)
		else
			local ent = v:get_luaentity()
			if ent.mob and ent.name ~= "pm:follower" then
				local tcaps = tooldata["sword_steel"]
				v:punch(v, 1.0, tcaps, nil)
			end
		end
	end
end

function pm.heal_nearby_players(self)
	local pos = self.object:get_pos()
	local players = minetest.get_connected_players()
	for k, v in ipairs(players) do
		if vector_distance(pos, v:get_pos()) < 2 then
			v:set_hp(v:get_hp() + 1)
		end
	end
end

function pm.steal_nearby_item(self, target)
	if target then
		if target:is_player() then
			local inv = target:get_inventory()
			local max = inv:get_size("main")
			local idx = math_random(1, max)
			local stack = inv:get_stack("main", idx)
			if not passport.is_passport(stack:get_name()) then
				if stack:get_count() >= 10 then
					local item = stack:take_item(math_random(1, 10))
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

function pm.commit_arson_at_target(pos)
	local p = vector_round(pos)
	p = minetest.find_node_near(pos, 1, "air", true)
	if p and not minetest.test_protection(p, "") then
		minetest.set_node(p, {name="fire:basic_flame"})
	end
end

function pm.teleport_player_to_prior_location(target)
	if target and target:is_player() then
		local pname = target:get_player_name()
		local positions = ap.get_position_list(pname)
		if #positions > 0 then
			local tpos = positions[1].pos
			preload_tp.preload_and_teleport(pname, tpos, 8, nil, nil, nil, true)
		end
	end
end
