
pm = pm or {}
pm.modpath = minetest.get_modpath("pm")
pm.sight_range = 30

-- Pathfinder cooldown min/max time.
pm.pf_cooldown_min = 5
pm.pf_cooldown_max = 15

-- Cooldown timer to acquire a new target.
pm.aq_cooldown_min = 1
pm.aq_cooldown_max = 10

-- Range at which entity is considered to have found its target.
pm.range = 2
pm.velocity = 3
pm.run_velocity = 4.5
pm.walk_velocity = 2

-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round
local math_floor = math.floor
local math_max = math.max
local math_random = math.random



dofile(pm.modpath .. "/seek.lua")
dofile(pm.modpath .. "/action.lua")

function pm.target_is_player_or_mob(target)
	if target:is_player() then
		return true
	end

	local ent = target:get_luaentity()
	if ent.mob then
		return true
	end
end

function pm.debug_chat(text)
	-- Comment or uncomment as needed for debugging.
	--minetest.chat_send_all(text)
end
function pm.debug_path(path)
	-- Ditto.
	--for k, v in ipairs(path) do pm.spawn_path_particle(v) end
end
function pm.debug_goal(pos)
	-- Ditto.
	--pm.spawn_path_particle(pos)
	--pm.death_particle_effect(pos)
end

function pm.death_particle_effect(pos)
	local particles = {
		amount = 100,
		time = 1.1,
		minpos = vector.add(pos, {x=-0.1, y=-0.1, z=-0.1}),
		maxpos = vector.add(pos, {x=0.1, y=0.1, z=0.1}),
		minvel = vector.new(-3.5, -3.5, -3.5),
		maxvel = vector.new(3.5, 3.5, 3.5),
		minacc = {x=0, y=0, z=0},
		maxacc = {x=0, y=0, z=0},
		minexptime = 1.5,
		maxexptime = 2.0,
		minsize = 0.5,
		maxsize = 1.0,
		collisiondetection = false,
		collision_removal = false,
		vertical = false,
		texture = "quartz_crystal_piece.png",
		glow = 14,
		--attached = entity,
	}
	minetest.add_particlespawner(particles)
end

-- Get objects inside radius, but remove self from the returned list.
function pm.get_nearby_objects(self, pos, radius)
	local objects = minetest.get_objects_inside_radius(pos, radius)
	if self._identity then
		for i=1, #objects, 1 do
			local ent = objects[i]:get_luaentity()
			if ent and ent._identity then
				if ent._identity == self._identity then
					table.remove(objects, i)
					break
				end
			end
		end
	end
	return objects
end

function pm.spawn_path_particle(pos)
	local particles = {
		amount = 1,
		time = 0.1,
		minpos = pos,
		maxpos = pos,
		minvel = {x=0, y=0, z=0},
		maxvel = {x=0, y=0, z=0},
		minacc = {x=0, y=0, z=0},
		maxacc = {x=0, y=0, z=0},
		minexptime = 5,
		maxexptime = 5,
		minsize = 2.0,
		maxsize = 2.0,
		collisiondetection = false,
		collision_removal = false,
		vertical = false,
		texture = "default_mese_crystal.png",
		glow = 14,
		--attached = entity,
	}
	minetest.add_particlespawner(particles)
end

function pm.follower_spawn_particles(pos, entity)
	local particles = {
		amount = 10,
		time = 1,
		minpos = vector.add(pos, {x=-0.1, y=-0.1, z=-0.1}),
		maxpos = vector.add(pos, {x=0.1, y=0.1, z=0.1}),
		minvel = vector.new(-0.5, -0.5, -0.5),
		maxvel = vector.new(0.5, 0.5, 0.5),
		minacc = {x=0, y=0, z=0},
		maxacc = {x=0, y=0, z=0},
		minexptime = 0.5,
		maxexptime = 2.0,
		minsize = 0.5,
		maxsize = 1.0,
		collisiondetection = false,
		collision_removal = false,
		vertical = false,
		texture = "quartz_crystal_piece.png",
		glow = 14,
		--attached = entity,
	}
	minetest.add_particlespawner(particles)
end

function pm.follower_on_activate(self, staticdata, dtime_s)
	if staticdata and staticdata ~= "" then
		local data = minetest.deserialize(staticdata)
		if type(data) == "table" then
			for k, v in pairs(data) do
				pm.debug_chat("on_activate(): self["..k.."]="..tostring(v))
				self[k] = v
			end
			return
		end
	end

	-- Otherwise, set up default data.
	self._timer = self._timer or 0
	self._lifetime = self._lifetime or 60*60*24
	self._sound_time = self._sound_time or 0
end

function pm.follower_get_staticdata(self)
	local data = {}
	for k, v in pairs(self) do
		local t = type(v)
		if t == "number" or t == "string" or t == "boolean" then
			if k:find("_") == 1 then
				pm.debug_chat("get_staticdata(): data["..k.."]="..tostring(v))
				data[k] = v
			end
		end
	end
	return minetest.serialize(data) or ""
end

function pm.get_wanted_velocity(self)
	if self and self._path then
		if #(self._path) > (pm.sight_range * 0.75) then
			return pm.run_velocity
		elseif #(self._path) < 5 then
			return pm.walk_velocity
		else
			return pm.velocity
		end
	end
	return pm.velocity
end

function pm.follower_on_step(self, dtime, moveresult)
	-- Remove object once we're old enough.
	if not self._lifetime then
		self.object:remove()
		return
	end
	self._lifetime = self._lifetime - dtime
	if self._lifetime < 0 then
		self.object:remove()
		return
	end

	-- Cooldown timer for the pathfinder, since using it is intensive.
	if self._failed_pathfind_cooldown then
		self._failed_pathfind_cooldown = self._failed_pathfind_cooldown - dtime
		if self._failed_pathfind_cooldown < 0 then
			self._failed_pathfind_cooldown = nil

			-- Also reset path/target info so we have a chance to acquire fresh data.
			self._goto = nil
			self._path = nil
		end
	end

	if self._acquire_target_cooldown then
		self._acquire_target_cooldown = self._acquire_target_cooldown - dtime
		if self._acquire_target_cooldown < 0 then
			self._acquire_target_cooldown = nil
		end
	end

	if self._wander_cooldown then
		self._wander_cooldown = self._wander_cooldown - dtime
		if self._wander_cooldown < 0 then
			self._wander_cooldown = nil
		end
	end

	-- Entity changes its behavior every so often.
	if not self._behavior_timer or self._behavior_timer < 0 then
		self._behavior_timer = math_random(1, 20)*60
		pm.choose_random_behavior(self)
	end
	self._behavior_timer = self._behavior_timer - dtime

	-- Entities sometimes get stuck against objects.
	-- Unstick them by rounding their positions to the nearest air node.
	if not self._unstick_timer or self._unstick_timer < 0 then
		self._unstick_timer = math_random(1, 30)
		local air = minetest.find_node_near(self.object:get_pos(), 1, "air", true)
		if air then
			self.object:set_pos(air)
		end
	end
	self._unstick_timer = self._unstick_timer - dtime

	-- Sound timer.
	if not self._sound_time then self._sound_time = 0 end
	self._sound_time = self._sound_time - dtime
	if self._sound_time < 0 then
		self._sound_time = math_random(100, 300)/100
		if not self._no_sound then
			ambiance.sound_play("wisp", self.object:get_pos(), 0.2, 32)
		end
	end

	-- If currently following a path, remove waypoints as we reach them.
	if self._path and #(self._path) > 0 then
		local p = self._path[1]
		-- Remove waypoint from path if we've reached it.
		if vector_distance(p, self.object:get_pos()) < 0.5 then
			pm.debug_chat('hit waypoint')
			self._stuck_timer = 2
			table.remove(self._path, 1)
		end

		-- Remove path when all waypoints exhausted.
		if #(self._path) < 1 then
			pm.debug_chat('finished following path: ' .. minetest.pos_to_string(self._goto))
			pm.debug_chat('node at terminus: ' .. minetest.get_node(self._goto).name)
			self._path = nil
			self._path_is_los = nil
			self._stuck_timer = nil
			self._failed_pathfind_cooldown = nil
			self.object:set_velocity({x=0, y=0, z=0})
		end

		if self._stuck_timer then
			self._stuck_timer = self._stuck_timer - dtime
			if self._stuck_timer < 0 then
				pm.debug_chat('got stuck following path')
				-- Got stuck trying to follow path.
				-- This is caused because the entity is physical and may collide with
				-- the environment. Blocks may have been added in the entity's path, or
				-- (more usually) the entity did not properly navigate a corner.
				-- We should seek a new target.
				self._goto = nil
				self._path = nil
				self._target = nil
				self._failed_pathfind_cooldown = math_random(pm.pf_cooldown_min, pm.pf_cooldown_max)
				self._stuck_timer = nil
				self._wander_cooldown = nil
				self.object:set_velocity({x=0, y=0, z=0})
			end
		end
	end

	-- Main logic timer.
	-- This controls how often the main "AI" logic runs.
	self._timer = self._timer + dtime
	if self._timer < 0.3 then return end
	self._timer = 0

	-- Spawn particles to indicate our location.
	local pos = self.object:get_pos()
	pm.follower_spawn_particles(pos, self.object)

	-- Find new target/goal-waypoint if we don't have one.
	if not self._acquire_target_cooldown and not self._failed_pathfind_cooldown then
		if not self._goto and not self._path then
			local tp, target = self._interest_point(self, pos)
			if target then
				-- Target is another entity.
				pm.debug_chat('acquired moving target')
				--if target:is_player() then pm.debug_chat('targeting player') end
				local s = tp
				if not s then s = target:get_pos() end
				if s then
					s = vector_round(s)
					if pm.target_is_player_or_mob(target) then
						s.y = s.y + 1 -- For players or mobs, seek above them, not at their feet.
					end
					s = minetest.find_node_near(s, 1, "air", true)
					-- Target must be standing in air.
					-- Otherwise it would never be reachable.
					if s then
						-- Don't reacquire target if we're already sitting on it.
						if vector_distance(pos, s) > pm.range then
							pm.debug_chat('set moving target goal')
							self._goto = vector_round(s)
							self._target = target -- Userdata object.
						end
					end
				end
				self._acquire_target_cooldown = math_random(pm.aq_cooldown_min, pm.aq_cooldown_max)
			elseif tp then
				-- Target is a static location.
				pm.debug_chat('acquired static target')
				-- Don't reacquire target if we're already sitting on it.
				if vector_distance(pos, tp) > pm.range then
					pm.debug_chat('set static target goal')
					self._goto = vector_round(tp)
					self._target = nil
				end
				self._acquire_target_cooldown = math_random(pm.aq_cooldown_min, pm.aq_cooldown_max)
			else
				-- No target acquired. Wait awhile before calling function again.
				pm.debug_chat('no target acquired')
				self._acquire_target_cooldown = math_random(pm.aq_cooldown_min, pm.aq_cooldown_max)
			end
		end
	end

	-- Get a path to our target if we don't have a path yet, and target is not nearby.
	if not self._failed_pathfind_cooldown then
		if self._goto and not self._path and vector_distance(self._goto, pos) > pm.range then
			pm.debug_chat('want path to target')
			local los, obstruction = minetest.line_of_sight(vector_round(pos), vector_round(self._goto))
			if los then
				-- We have LOS (line of sight) direct to target.
				pm.debug_chat('LOS confirmed')
				local dir = vector.subtract(vector_round(self._goto), vector_round(pos))
				local dst = vector.length(dir)
				dir = vector.normalize(dir) -- Returns 0,0,0 for zero-length vector.

				-- Assemble a straight-line path.
				local path = {}
				for i=1, dst, 1 do
					path[#path+1] = vector.add(pos, vector.multiply(dir, i))
				end
				if #path > 0 then
					self._path = path
					self._path_is_los = true
					self._stuck_timer = nil
				end
			else
				-- No line of sight to target. Use pathfinder!
				pm.debug_chat('will try pathfinder')
				local rp1 = vector_round(pos)
				local rp2 = vector_round(self._goto)

				local a1 = rp1
				local a2 = rp2

				local d1 = minetest.registered_nodes[minetest.get_node(rp1).name]
				local d2 = minetest.registered_nodes[minetest.get_node(rp2).name]

				-- If either start or end are non-walkable, we don't need to look for air.
				if d1.walkable then
					a1 = minetest.find_node_near(rp1, 2, "air", true)
				end
				if d2.walkable then
					a2 = minetest.find_node_near(rp2, 2, "air", true)
				end

				if a1 and a2 then
					pm.debug_chat('start and end position are both in air')
					local prepath = {table.copy(a1)}
					local postpath = {table.copy(a2)}

					-- Find air directly above ground for the wisp's start position.
					-- This is necessary because the wisp usually flies a little bit above
					-- the ground. Pathfinding will fail if we don't start at ground level.
					while minetest.get_node(vector.add(a1, {x=0, y=-1, z=0})).name == "air" do
						a1.y = a1.y - 1
						table.insert(prepath, table.copy(a1))
					end
					-- Find air directly above ground for the target position.
					local target_y = a2.y
					while minetest.get_node(vector.add(a2, {x=0, y=-1, z=0})).name == "air" do
						a2.y = a2.y - 1
						table.insert(postpath, 1, table.copy(a2))
					end

					-- If this triggers then the target is flying, or hanging over a high ledge.
					if (target_y - a2.y) > 2 then
					end

					-- The shorter the apparent distance between these 2 points, the farther
					-- we can afford to look around.
					local d = vector_distance(a1, a2)
					local r = math_max(1, math_floor(pm.sight_range - d))

					pm.debug_chat("trying to find path")
					self._path = minetest.find_path(a1, a2, r, 1, 1, "A*_noprefetch")

					if not self._path then
						pm.debug_chat('no path found')
						-- If we couldn't find a path to this location, we should remove this
						-- goal. Also set the pathfinder cooldown timer.
						self._goto = nil
						self._failed_pathfind_cooldown = math_random(pm.pf_cooldown_min, pm.pf_cooldown_max)
					else
						if #(self._path) >= 1 then
							pm.debug_chat("got path")
							self._stuck_timer = nil

							pm.debug_chat('welding pre and post paths')
							local path = {}
							for i=1, #prepath, 1 do
								path[#path+1] = prepath[i]
							end
							for i=1, #(self._path), 1 do
								path[#path+1] = self._path[i]
							end
							for i=1, #postpath, 1 do
								path[#path+1] = postpath[i]
							end
							self._path = path
							self._stuck_timer = nil

							-- Debug render path.
							pm.debug_path(self._path)

							-- If start and end points are equal, toss this path out.
							-- Also set the pathfinder cooldown timer.
							if vector.equals(self._path[1], self._path[#(self._path)]) then
								pm.debug_chat('tossing path because start and end are equal')
								self._path = nil
								self._goto = nil
								self._failed_pathfind_cooldown = math_random(pm.pf_cooldown_min, pm.pf_cooldown_max)
							end

							-- If path's start position is too far away, we can't use the path.
							if self._path then
								if vector_distance(self._path[1], pos) > pm.range then
									pm.debug_chat('tossing path because start is too far away')
									self._path = nil
									self._goto = nil
									self._failed_pathfind_cooldown = math_random(pm.pf_cooldown_min, pm.pf_cooldown_max)
								end
							end
						else
							-- Not a real path!
							-- Must have at least one position.
							pm.debug_chat('tossing path because it is bogus')
							self._goto = nil
							self._path = nil
							self._failed_pathfind_cooldown = math_random(pm.pf_cooldown_min, pm.pf_cooldown_max)
						end
					end
				else
					-- One or both positions not accessible (no nearby air).
					-- Thus we must give up this target.
					self._goto = nil
					self._path = nil
					self._failed_pathfind_cooldown = math_random(pm.pf_cooldown_min, pm.pf_cooldown_max)
				end
			end
		end
	end

	-- Follow current path.
	if self._path and #(self._path) > 0 then
		-- For paths of longer than trivial length, try to optimize with LOS.
		-- We can do this because this mob can fly over gaps and such. This also
		-- makes the movement look better.
		if #(self._path) > 5 then
			-- Don't do LOS optimization if the current waypoint is already so marked.
			local p = self._path[2]
			if not p.los then
				while #(self._path) > 1 and minetest.line_of_sight(pos, p) do
					table.remove(self._path, 1)
					p = self._path[2]
				end

				local dir = vector.subtract(self._path[1], pos)
				local dst = vector.length(dir)
				dir = vector.normalize(dir) -- Returns 0,0,0 for zero-length vector.

				-- Assemble a straight-line path.
				local path = {}
				for i=1, dst, 1 do
					path[#path+1] = vector.add(pos, vector.multiply(dir, i))
					path[#path].los = true -- Mark waypoint as a LOS point.
				end

				-- Append the remainder of the real path.
				for i=1, #(self._path), 1 do
					path[#path+1] = self._path[i]
				end

				-- Set new path.
				self._path = path
				self._stuck_timer = nil

				-- Debug render path.
				pm.debug_path(self._path)
			end
		end

		pm.debug_chat('following path')
		local waypoint = self._path[1]
		local waynode = minetest.get_node(waypoint)

		-- Check if path runs through an obstruction.
		-- Nodes must be 'air' or non-walkable (like plants).
		local obstructed = false
		if waynode.name ~= "air" then
			local ndef = minetest.registered_nodes[waynode.name]
			if not ndef or ndef.walkable then
				obstructed = true
			end
		end

		if not obstructed then
			if self._path_is_los or waypoint.los then
				-- Follow line-of-sight paths directly.
				--self.object:move_to(waypoint, true)
				--table.remove(self._path, 1)

				-- Smooth movement.
				local dir = vector.subtract(waypoint, pos)
				if vector.length(dir) > 0.4 then
					dir = vector.normalize(dir)
					dir = vector.multiply(dir, pm.get_wanted_velocity(self))
					self.object:set_velocity(dir)
				end
			else
				-- Cause entity to float 1.5 meters above ground when following path,
				-- if there's enough head room. But not for the last waypoint in the path.
				waypoint.y = waypoint.y + 1
				local n = minetest.get_node(waypoint)

				if n.name == "air" and #(self._path) > 1 then
					waypoint.y = waypoint.y - 0.5
					--self.object:move_to(waypoint, true)
					--table.remove(self._path, 1)

					-- Smooth movement.
					local dir = vector.subtract(waypoint, pos)
					if vector.length(dir) > 0.4 then
						dir = vector.normalize(dir)
						dir = vector.multiply(dir, pm.get_wanted_velocity(self))
						self.object:set_velocity(dir)
					end
				else
					waypoint.y = waypoint.y - 1
					--self.object:move_to(waypoint, true)
					--table.remove(self._path, 1)

					-- Smooth movement.
					local dir = vector.subtract(waypoint, pos)
					if vector.length(dir) > 0.4 then
						dir = vector.normalize(dir)
						dir = vector.multiply(dir, pm.get_wanted_velocity(self))
						self.object:set_velocity(dir)
					end
				end
			end
		else
			-- Path obstructed. Need new path, this one is bad.
			pm.debug_chat('path obstructed: ' .. waynode.name)
			self._path = nil
			self._path_is_los = nil
			self._goto = nil
			self.object:set_velocity({x=0, y=0, z=0})
		end
	end

	-- Dynamic targets can move while we're trying to path to them.
	-- Update path as long as we have LOS to the target.
	if self._target and self._path and self._goto then
		local target_pos = self._target:get_pos()
		if target_pos then
			if #(self._path) > 0 then
				local end_path = self._path[#(self._path)]
				if vector_distance(target_pos, end_path) > 3 then
					local los, obstruction = minetest.line_of_sight(vector_round(pos), vector_round(target_pos))
					if los then
						pm.debug_chat('target moved, repathing via LOS')
						self._goto = vector_round(target_pos)

						local dir = vector.subtract(self._goto, vector_round(pos))
						local dst = vector.length(dir)
						dir = vector.normalize(dir) -- Returns 0,0,0 for zero-length vector.

						-- Assemble a straight-line path.
						local path = {}
						for i=1, dst, 1 do
							path[#path+1] = vector.add(pos, vector.multiply(dir, i))
						end
						if #path > 0 then
							self._path = path
							self._path_is_los = true
							self._stuck_timer = nil
						end
					end
				end
			end
		end
	end

	-- Remove target waypoint once we're close enough to it.
	-- Only if done following path.
	if self._goto and not self._path then
		pm.debug_chat('distance to goal: ' .. vector_distance(self._goto, pos))
		pm.debug_goal(self._goto)
		if vector_distance(self._goto, pos) < pm.range then
			pm.debug_chat('reached goal')
			--self.object:move_to(self._goto, true)

			-- Have we arrived at the target (if we did indeed have a target)?
			if self._target then
				local s = self._target:get_pos()
				if s then
					s = vector_round(s)
					s.y = s.y + 1 -- For entities, we seek above them, not at their feet.
					if vector_distance(pos, s) < pm.range then
						pm.debug_chat('reached dynamic target')
						-- We have reached our moveable target.
						-- We can clear this and set a timer to delay acquiring the next target.
						self._on_arrival(self, self._goto, self._target)
						self._goto = nil
						self._target = nil
						self._acquire_target_cooldown = math_random(pm.aq_cooldown_min, pm.aq_cooldown_max)
					else
						-- Our moveable target has moved. We must move toward it again.
						-- Do so right away, without delay.
						pm.debug_chat('target has moved, reacquiring')
						self._goto = s
						self._acquire_target_cooldown = nil
						self._failed_pathfind_cooldown = nil
					end
				else
					-- Moving target no longer available. We must clear this.
					self._target = nil
					self._goto = nil
				end
			else
				pm.debug_chat('reached static target')
				self._on_arrival(self, self._goto, nil)
				-- No moving target, so we can clear this.
				self._goto = nil
				self._acquire_target_cooldown = math_random(pm.aq_cooldown_min, pm.aq_cooldown_max)
			end
		end
	end

	-- Drift behavior, as long as we don't have a target to go to.
	if not self._wander_cooldown then
		if not self._goto then
			local dir = {
				x = math_random(-1, 1)/10,
				y = math_random(-1, 1)/10,
				z = math_random(-1, 1)/10
			}
			self.object:set_velocity(dir)
			self._wander_cooldown = math_random(1, 5)
		end
	end
end

function pm.follower_on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir)
	local pos = self.object:get_pos()
	pm.death_particle_effect(pos)
	minetest.add_item(pos, "glowstone:glowing_dust " .. math_random(1, 3))
	self.object:remove()
end

-- Create entity at position, if possible.
function pm.spawn_wisp(pos, behavior)
	pos = vector_round(pos)
	local node = minetest.get_node(pos)
	if node.name == "air" then
		local ent = minetest.add_entity(pos, "pm:follower")
		if ent then
			local luaent = ent:get_luaentity()
			if luaent then
				luaent._behavior = behavior
				luaent._behavior_timer = math_random(1, 20)*60

				-- Allows to uniquely identify the wisp to other wisps, with little chance of collision.
				-- In particular this allows the wisp to ignore itself in any object queries.
				luaent._identity = math_random(1, 32000)

				-- This is so the wisp knows where it spawned at.
				-- We format it as a string so that this data is saved statically.
				luaent._spawn_origin = minetest.pos_to_string(pos)

				-- Wisp has a chance to be completely silent.
				if math_random(1, 10) == 1 then
					luaent._no_sound = true
				end

				return ent
			else
				ent:remove()
			end
		end
	end
end

local behaviors = {
	"follower",
	"pest",
	"thief",
	"healer",
	"explorer",
	"boom", -- Never chosen by chance.
	"communal",
	"solitary",
	"guard",
	"arsonist",
	"porter",
	"pusher",
}

function pm.choose_random_behavior(self)
	self._behavior = behaviors[math_random(1, #behaviors)]

	-- Don't chose a self-destructive behavior by chance.
	if self._behavior == "boom" then
		self._behavior = "follower"
	end
end

-- Create entity at position, if possible.
function pm.spawn_random_wisp(pos)
	local act = behaviors[math_random(1, #behaviors)]
	if act == "boom" then
		act = "follower"
	end
	return pm.spawn_wisp(pos, act)
end

-- Table of functions for obtaining interest points.
local interests = {
	follower = function(self, pos)
		return pm.seek_player_or_mob_or_item(self, pos)
	end,

	thief = function(self, pos)
		return pm.seek_player_or_item(self, pos)
	end,

	pest = function(self, pos)
		return pm.seek_player(self, pos)
	end,

	healer = function(self, pos)
		return pm.seek_player(self, pos)
	end,

	explorer = function(self, pos)
		return pm.seek_node_with_meta(self, pos)
	end,

	-- Suicide, never chosen at random.
	boom = function(self, pos)
		return pm.seek_player_or_mob(self, pos)
	end,

	communal = function(self, pos)
		return pm.seek_wisp(self, pos)
	end,

	solitary = function(self, pos)
		return pm.seek_solitude(self, pos)
	end,

	guard = function(self, pos)
		-- Seek target in sight-range of spawn origin, otherwise return to origin.
		if self._spawn_origin then
			local origin = minetest.string_to_pos(self._spawn_origin)
			if origin then
				if vector_distance(origin, self.object:get_pos()) > pm.sight_range then
					return origin, nil
				else
					-- Within sight range of spawn origin, seek target.
					return pm.seek_player_or_mob_not_wisp(self, pos)
				end
			end
		end
		return nil, nil
	end,

	arsonist = function(self, pos)
		local target = pm.seek_flammable_node(self, pos)
		if not target then
			return pm.seek_player_or_mob(self, pos)
		end
		return target, nil
	end,

	porter = function(self, pos)
		return pm.seek_player(self, pos)
	end,

	pusher = function(self, pos)
		return pm.seek_player(self, pos)
	end,
}

-- Table of possible action functions to take on arriving at a target.
local actions = {
	pest = function(self, pos, target)
		pm.hurt_nearby_players(self)
	end,

	healer = function(self, pos, target)
		pm.heal_nearby_players(self)
	end,

	thief = function(self, pos, target)
		pm.steal_nearby_item(self, target)
	end,

	boom = function(self, pos, target)
		pm.explode_nearby_target(self, target)
	end,

	guard = function(self, pos, target)
		-- Attack target, but only if in sight-range of spawn origin.
		if self._spawn_origin then
			local origin = minetest.string_to_pos(self._spawn_origin)
			if origin then
				if vector_distance(origin, self.object:get_pos()) < pm.sight_range then
					pm.hurt_nearby_player_or_mob_not_wisp(self)
				end
			end
		end
	end,

	arsonist = function(self, pos, target)
		pm.commit_arson_at_target(pos)
	end,

	porter = function(self, pos, target)
		pm.teleport_player_to_prior_location(target)
	end,

	pusher = function(self, pos, target)
		pm.shove_player(self, target)
	end,
}

function pm.interest_point(self, pos)
	if self._behavior then
		if interests[self._behavior] then
			return interests[self._behavior](self, pos)
		end
	end
	return nil, nil
end

function pm.on_arrival(self, pos, other)
	pm.debug_chat('arrived at target')
	if self._behavior then
		pm.debug_chat('have behavior: ' .. self._behavior)
		if actions[self._behavior] then
			actions[self._behavior](self, pos, other)
		end
	end
end

if not pm.registered then
	local entity = {
		initial_properties = {
			visual = "cube",
			textures = {
				"quartz_crystal_piece.png",
				"quartz_crystal_piece.png",
				"quartz_crystal_piece.png",
				"quartz_crystal_piece.png",
				"quartz_crystal_piece.png",
				"quartz_crystal_piece.png",
			},
			visual_size = {x=0.2, y=0.2, z=0.2},
			collide_with_objects = false,
			pointable = false,
			is_visible = true,
			makes_footstep_sound = false,
			glow = 14,
			automatic_rotate = 0.5,

			-- This is so that wandering/drifting wisps don't bury themselves.
			physical = true,
			collisionbox = {-0.2, -0.2, -0.2, 0.2, 0.2, 0.2},
		},

		-- So other game code can tell what this entity is.
		_name = "pm:follower",
		description = "Seon",
		mob = true,

		on_step = function(...) return pm.follower_on_step(...) end,
		on_punch = function(...) return pm.follower_on_punch(...) end,
		on_activate = function(...) return pm.follower_on_activate(...) end,
		get_staticdata = function(...) return pm.follower_get_staticdata(...) end,

		_interest_point = function(...) return pm.interest_point(...) end,
		_on_arrival = function(...) return pm.on_arrival(...) end,
	}

	minetest.register_entity("pm:follower", entity)

	local c = "pm:core"
	local f = pm.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	pm.registered = true
end
