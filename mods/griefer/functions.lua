
griefer.elite_do_custom = function(self, dtime)
	self.range_attack_timer = (self.range_attack_timer or 0) - dtime

	if self.state == "attack" and self.attack and self.attack:get_pos() then
		if self.range_attack_timer <= 0 then
			local s = self.object:get_pos()
			local p = self.attack:get_pos()
			local old_s = self.last_known_pos or {x=0, y=0, z=0}

			-- Only shoot if Oerkki is not moving (stuck or something).
			if vector.distance(s, old_s) < 0.25 and not self.path.following then
				-- Don't shoot if within punching range.
				if vector.distance(s, p) >= self.punch_reach then
					-- Don't shoot unless Oerkki has LOS to target.
					local has_lineofsight = minetest.line_of_sight(
						{x = s.x, y = (s.y + 0.5), z = s.z},
						{x = p.x, y = (p.y + 1), z = p.z}, 0.2)

					if has_lineofsight then
						local vec = vector.subtract(p, s)
						--mobs.shoot_arrow(self, vec)
					end
				end
			end

			self.last_known_pos = s
			self.range_attack_timer = 1
		end
	end

	-- Do builtin logic.
	return true
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
