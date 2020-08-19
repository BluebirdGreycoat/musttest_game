
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
				--minetest.chat_send_all("on_activate(): self["..k.."]="..v)
				self[k] = v
			end
			return
		end
	end

	-- Otherwise, set up default data.
	self._timer = self._timer or 0
	self._lifetime = self._lifetime or 60*60
	self._sound_time = self._sound_time or 0
end

function pm.follower_get_staticdata(self)
	local data = {}
	for k, v in pairs(self) do
		if type(v) == "number" or type(v) == "string" then
			if k:find("_") == 1 then
				--minetest.chat_send_all("get_staticdata(): data["..k.."]="..v)
				data[k] = v
			end
		end
	end
	return minetest.serialize(data) or ""
end

function pm.follower_on_step(self, dtime, moveresult)
	-- Remove object once we're old enough.
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
		self._behavior_timer = math.random(1, 20)*60
		pm.choose_random_behavior(self)
	end
	self._behavior_timer = self._behavior_timer - dtime

	-- Entities sometimes get stuck against objects.
	-- Unstick them by rounding their positions to the nearest air node.
	if not self._unstick_timer or self._unstick_timer < 0 then
		self._unstick_timer = math.random(1, 30)
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
		self._sound_time = math.random(100, 300)/100
		ambiance.sound_play("wisp", self.object:get_pos(), 0.2, 32)
	end

	-- If currently following a path, remove waypoints as we reach them.
	local finished_path_this_frame = false
	if self._path and #(self._path) > 0 then
		local p = self._path[1]
		-- Remove waypoint from path if we've reached it.
		if vector.distance(p, self.object:get_pos()) < 0.5 then
			--minetest.chat_send_all('hit waypoint')
			self._stuck_timer = 2
			table.remove(self._path, 1)
		end

		-- Remove path when all waypoints exhausted.
		if #(self._path) < 1 then
			--minetest.chat_send_all('finished following path')
			finished_path_this_frame = true
			self._path = nil
			self._path_is_los = nil
			self._stuck_timer = nil
			self.object:set_velocity({x=0, y=0, z=0})
		end

		if self._stuck_timer then
			self._stuck_timer = self._stuck_timer - dtime
			if self._stuck_timer < 0 then
				--minetest.chat_send_all('got stuck following path')
				-- Got stuck trying to follow path.
				-- This is caused because the entity is physical and may collide with
				-- the environment. Blocks may have been added in the entity's path, or
				-- (more usually) the entity did not properly navigate a corner.
				-- We should seek a new target.
				self._goto = nil
				self._path = nil
				self._target = nil
				self._failed_pathfind_cooldown = math.random(pm.pf_cooldown_min, pm.pf_cooldown_max)
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
	if not self._acquire_target_cooldown then
		if not self._goto then
			local tp, target = self._interest_point(self)
			if target then
				-- Target is another entity.
				--minetest.chat_send_all('acquired moving target')
				--if target:is_player() then minetest.chat_send_all('targeting player') end
				local s = target:get_pos()
				if s then
					s = vector.round(s)
					if pm.target_is_player_or_mob(target) then
						s.y = s.y + 1 -- For players or mobs, seek above them, not at their feet.
					end
					s = minetest.find_node_near(s, 1, "air", true)
					-- Target must be standing in air.
					-- Otherwise it would never be reachable.
					if s then
						-- Don't reacquire target if we're already sitting on it.
						if vector.distance(pos, s) > pm.range then
							--minetest.chat_send_all('set moving target goal')
							self._goto = vector.round(s)
							self._target = target -- Userdata object.
						end
					end
				end
				self._acquire_target_cooldown = math.random(pm.aq_cooldown_min, pm.aq_cooldown_max)
			elseif tp then
				-- Target is a static location.
				--minetest.chat_send_all('acquired static target')
				-- Don't reacquire target if we're already sitting on it.
				if vector.distance(pos, tp) > pm.range then
					--minetest.chat_send_all('set static target goal')
					self._goto = vector.round(tp)
					self._target = nil
				end
				self._acquire_target_cooldown = math.random(pm.aq_cooldown_min, pm.aq_cooldown_max)
			else
				-- No target acquired. Wait awhile before calling function again.
				--minetest.chat_send_all('no target acquired')
				self._acquire_target_cooldown = math.random(pm.aq_cooldown_min, pm.aq_cooldown_max)
			end
		end
	end

	-- Get a path to our target if we don't have a path yet.
	if not self._failed_pathfind_cooldown and not finished_path_this_frame then
		if self._goto and not self._path then
			--minetest.chat_send_all('want path to target')
			local los, obstruction = minetest.line_of_sight(vector.round(pos), vector.round(self._goto))
			if los then
				-- We have LOS (line of sight) direct to target.
				--minetest.chat_send_all('LOS confirmed')
				local dir = vector.subtract(vector.round(self._goto), vector.round(pos))
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
				--minetest.chat_send_all('will try pathfinder')
				local a1 = minetest.find_node_near(vector.round(pos), 1, "air", true)
				local a2 = minetest.find_node_near(vector.round(self._goto), 1, "air", true)

				if a1 and a2 then
					--minetest.chat_send_all('start and end position are both in air')
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
					local d = vector.distance(a1, a2)
					local r = math.max(1, math.floor(pm.sight_range - d))

					--minetest.chat_send_all("trying to find path")
					self._path = minetest.find_path(a1, a2, r, 1, 1, "A*_noprefetch")

					if not self._path then
						--minetest.chat_send_all('no path found')
						--[[
						-- Can't find path? (Also assumes no LOS, here.)
						-- Check if entity is flying and make it follow a path to the ground.
						-- (The pathfinder only works for ground paths.)
						-- This prevents the entity from getting stuck in the air if its
						-- target has left its line of sight (and the entity was flying).
						local path = {}
						local p = vector.round(pos)
						p.y = p.y - 1
						while minetest.get_node(p).name == "air" do
							path[#path+1] = table.copy(p)
							p.y = p.y - 1
						end

						minetest.chat_send_all('length of proposed path to ground: ' .. #path)

						if #path >= 2 then
							-- Path to ground only if path would be at least 2 positions long.
							minetest.chat_send_all('pathing to ground')
							self._path = path
							self._path_is_los = true
							self._stuck_timer = nil
							self._goto = path[#path]
							self._target = nil

							-- This counts as a pathfinding/target failure, so we install cooldowns.
							self._acquire_target_cooldown = math.random(pm.aq_cooldown_min, pm.aq_cooldown_max)
							self._failed_pathfind_cooldown = math.random(pm.pf_cooldown_min, pm.pf_cooldown_max)
						else
						--]]
							-- If we couldn't find a path to this location, we should remove this
							-- goal. Also set the pathfinder cooldown timer.
							self._goto = nil
							self._failed_pathfind_cooldown = math.random(pm.pf_cooldown_min, pm.pf_cooldown_max)
						--[[
						end
						--]]
					else
						if #(self._path) >= 1 then
							--minetest.chat_send_all("got path")
							self._stuck_timer = nil

							--minetest.chat_send_all('welding pre and post paths')
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

							-- Debug render path.
							--for k, v in ipairs(self._path) do pm.spawn_path_particle(v) end

							-- If start and end points are equal, toss this path out.
							-- Also set the pathfinder cooldown timer.
							if vector.equals(self._path[1], self._path[#(self._path)]) then
								--minetest.chat_send_all('tossing path because start and end are equal')
								self._path = nil
								self._goto = nil
								self._failed_pathfind_cooldown = math.random(pm.pf_cooldown_min, pm.pf_cooldown_max)
							end

							-- If path's start position is too far away, we can't use the path.
							if self._path then
								if vector.distance(self._path[1], pos) > pm.range then
									--minetest.chat_send_all('tossing path because start is too far away')
									self._path = nil
									self._goto = nil
									self._failed_pathfind_cooldown = math.random(pm.pf_cooldown_min, pm.pf_cooldown_max)
								end
							end
						else
							-- Not a real path!
							-- Must have at least one position.
							--minetest.chat_send_all('tossing path because it is bogus')
							self._goto = nil
							self._path = nil
							self._failed_pathfind_cooldown = math.random(pm.pf_cooldown_min, pm.pf_cooldown_max)
						end
					end
				else
					-- One or both positions not accessible (no nearby air).
					-- Thus we must give up this target.
					self._goto = nil
					self._path = nil
					self._failed_pathfind_cooldown = math.random(pm.pf_cooldown_min, pm.pf_cooldown_max)
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

				-- Debug render path.
				--for k, v in ipairs(self._path) do pm.spawn_path_particle(v) end
			end
		end

		--minetest.chat_send_all('following path')
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
					dir = vector.multiply(dir, pm.velocity)
					self.object:set_velocity(dir)
				end
			else
				-- Cause entity to float 1.5 meters above ground when following path,
				-- if there's enough head room.
				waypoint.y = waypoint.y + 1
				local n = minetest.get_node(waypoint)

				if n.name == "air" then
					waypoint.y = waypoint.y - 0.5
					--self.object:move_to(waypoint, true)
					--table.remove(self._path, 1)

					-- Smooth movement.
					local dir = vector.subtract(waypoint, pos)
					if vector.length(dir) > 0.4 then
						dir = vector.normalize(dir)
						dir = vector.multiply(dir, pm.velocity)
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
						dir = vector.multiply(dir, pm.velocity)
						self.object:set_velocity(dir)
					end
				end
			end
		else
			-- Path obstructed. Need new path, this one is bad.
			--minetest.chat_send_all('path obstructed: ' .. waynode.name)
			self._path = nil
			self._path_is_los = nil
			self._goto = nil
			self.object:set_velocity({x=0, y=0, z=0})
		end
	end

	-- Remove target waypoint once we're close enough to it.
	-- Only if done following path.
	if self._goto and not self._path then
		--minetest.chat_send_all('distance to goal: ' .. vector.distance(self._goto, pos))
		--pm.spawn_path_particle(self._goto)
		if vector.distance(self._goto, pos) < pm.range then
			--minetest.chat_send_all('reached goal')
			--self.object:move_to(self._goto, true)

			-- Have we arrived at the target (if we did indeed have a target)?
			if self._target then
				local s = self._target:get_pos()
				if s then
					s = vector.round(s)
					s.y = s.y + 1 -- For entities, we seek above them, not at their feet.
					if vector.distance(pos, s) < pm.range then
						--minetest.chat_send_all('reached dynamic target')
						-- We have reached our moveable target.
						-- We can clear this and set a timer to delay acquiring the next target.
						self._on_arrival(self, self._goto, self._target)
						self._goto = nil
						self._target = nil
						self._acquire_target_cooldown = math.random(pm.aq_cooldown_min, pm.aq_cooldown_max)
					else
						-- Our moveable target has moved. We must move toward it again.
						-- Do so right away, without delay.
						--minetest.chat_send_all('target has moved, reacquiring')
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
				--minetest.chat_send_all('reached static target')
				self._on_arrival(self, self._goto, nil)
				-- No moving target, so we can clear this.
				self._goto = nil
				self._acquire_target_cooldown = math.random(pm.aq_cooldown_min, pm.aq_cooldown_max)
			end
		end
	end

	-- Drift behavior, as long as we don't have a target to go to.
	if not self._wander_cooldown then
		if not self._goto then
			local dir = {
				x = math.random(-1, 1)/10,
				y = math.random(-1, 1)/10,
				z = math.random(-1, 1)/10
			}
			self.object:set_velocity(dir)
			self._wander_cooldown = math.random(1, 5)
		end
	end
end

function pm.follower_on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir)
	self.object:remove()
end

-- Create entity at position, if possible.
function pm.spawn_wisp(pos, behavior)
	pos = vector.round(pos)
	local node = minetest.get_node(pos)
	if node.name == "air" then
		local ent = minetest.add_entity(pos, "pm:follower")
		if ent then
			local luaent = ent:get_luaentity()
			if luaent then
				luaent._behavior = behavior
				luaent._behavior_timer = math.random(1, 20)*60
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
	"boom",
}

function pm.choose_random_behavior(self)
	self._behavior = behaviors[math.random(1, #behaviors)]

	-- Don't chose a self-destructive behavior by chance.
	if self._behavior == "boom" then
		self._behavior = "follower"
	end
end

-- FOLLOWER entity.
function pm.spawn_follower(pos)
	return pm.spawn_wisp(pos, "follower")
end

-- PEST entity.
function pm.spawn_pest(pos)
	return pm.spawn_wisp(pos, "pest")
end

-- THIEF entity.
function pm.spawn_thief(pos)
	return pm.spawn_wisp(pos, "thief")
end

-- HEALER entity.
function pm.spawn_healer(pos)
	return pm.spawn_wisp(pos, "healer")
end

-- EXPLORER entity.
function pm.spawn_explorer(pos)
	return pm.spawn_wisp(pos, "explorer")
end

-- BOOM entity.
function pm.spawn_boom(pos)
	return pm.spawn_wisp(pos, "boom")
end

-- Table of functions for obtaining interest points.
local interests = {
	follower = function(self)
		return pm.seek_player_or_mob_or_item(self.object:get_pos())
	end,

	thief = function(self)
		return pm.seek_player_or_item(self.object:get_pos())
	end,

	pest = function(self)
		return pm.seek_player(self.object:get_pos())
	end,

	healer = function(self)
		return pm.seek_player(self.object:get_pos())
	end,

	explorer = function(self)
		return pm.seek_node_with_meta(self.object:get_pos())
	end,

	boom = function(self)
		return pm.seek_player_or_mob(self.object:get_pos())
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
}

function pm.interest_point(self)
	if self._behavior then
		if interests[self._behavior] then
			return interests[self._behavior](self)
		end
	end
	return nil, nil
end

function pm.on_arrival(self, pos, other)
	--minetest.chat_send_all('arrived at target')
	if self._behavior then
		--minetest.chat_send_all('have behavior: ' .. self._behavior)
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

			-- So other game code can tell what this entity is.
			_name = "pm:follower",
			description = "Seon",
			mob = true,
		},

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
