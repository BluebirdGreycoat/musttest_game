
griefer.elite_do_custom = function(self, dtime)
	self.range_attack_timer = (self.range_attack_timer or 0) - dtime

	if self.attack and self.attack:get_pos() then
		if self.range_attack_timer <= 0 then
			local s = self.object:get_pos()
			local p = self.attack:get_pos()

			-- Only shoot if Oerkki is not currently trying to move.
			if self.stand_timer >= 1 then
				-- Don't shoot if within punching range.
				if vector.distance(s, p) >= self.punch_reach then
					-- Don't shoot unless Oerkki has LOS to target.
					local has_lineofsight = minetest.line_of_sight(
						{x = s.x, y = (s.y + 0.5), z = s.z},
						{x = p.x, y = (p.y + 1), z = p.z}, 0.2)

					if has_lineofsight then
						local vec = vector.subtract(p, s)
						mobs.shoot_arrow(self, vec)
					end
				end
			end

			-- Shoot once every 1.5 seconds.
			self.range_attack_timer = 1.5
		end
	end

	-- Do builtin logic.
	return true
end



griefer.elite_do_punch = function(self, hitter, tflp, tcaps, dir)
	-- Prevent infinite recursion.
	if self.in_punch_callback then
		return false
	end

	-- Do all normal punch activities.
	self.in_punch_callback = true
	mobs.mob_punch(self, hitter, tflp, tcaps, dir)
	self.in_punch_callback = nil

	if (self.health or 0) < 10 then
		minetest.chat_send_player("MustTest", "Testing")
	end
end

--[[

-- Localize for performance.
local math_random = math.random

function griefer.get_griefer_count(pos)
	local ents = minetest.get_objects_inside_radius(pos, 10)
	local count = 0
	for k, v in ipairs(ents) do
		if not v:is_player() then
			local tb = v:get_luaentity()
			if tb and tb.mob then
				if tb.name and tb.name == "griefer:griefer" then
					-- Found monster in radius.
					count = count + 1
				end
			end
		end
	end
	return count
end



function griefer.on_stone_construct(pos)
	minetest.get_node_timer(pos):start(math_random(10, 60)
end



function griefer.on_stone_timer(pos, elapsed)
	minetest.get_node_timer(pos):start(math_random(10, 60)
end
--]]



if not griefer.run_functions_once then
	local c = "griefer:functions"
	local f = griefer.modpath .. "/functions.lua"
	reload.register_file(c, f, false)

	griefer.run_functions_once = true
end
