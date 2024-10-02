
local function get_velocity(v, yaw, y)
	local x = -math.sin(yaw) * v
	local z =  math.cos(yaw) * v
	return {x = x, y = y, z = z}
end

local function get_v(v)
	return math.sqrt(v.x ^ 2 + v.z ^ 2)
end

local function highlight_position(pos)
	utility.original_add_particle({
		pos = pos,
		velocity = {x=0, y=0, z=0},
		acceleration = {x=0, y=0, z=0},
		expirationtime = 0.5,
		size = 10,
		collisiondetection = false,
		vertical = false,
		texture = "heart.png",
		glow = 14,
	})
end

-- Returns nil, or (distance, intersection point).
local function distance_to_obstacle(pos, dir)
	local p1 = pos
	local p2 = vector.add(pos, vector.multiply(vector.normalize(dir), lagwing.MAX_ALTITUDE))

	local ray = Raycast(p1, p2, true, true)
	local target

	for pt in ray do
		if pt.type == "node" then
			target = pt.intersection_point
			break
		end
	end

	if target then
		if lagwing.SHOW_RAYCASTS then
			highlight_position(target)
		end
		return vector.distance(p1, target), target
	end
end

local function in_dive(obj)
	local r = obj:get_rotation()
	if math.abs(r.x - lagwing.MAX_DIVE_ANGLE) < 0.1 then
		return true
	end
end

local function in_climb(obj)
	local r = obj:get_rotation()
	if math.abs(r.x - lagwing.MAX_CLIMB_ANGLE) < 0.1 then
		return true
	end
end

local function collides_with_ground(moveresult)
	if moveresult.collisions then
		local c = moveresult.collisions
		for k = 1, #c do
			local d = c[k]
			if d.type == "node" then
				return true
			end
		end
	end
end



function lagwing.do_flightmodel(self, dtime, moveresult)
	local obj = self.object

	-- Begin with default acceleration due to gravity.
	local acc = {x=0, y=lagwing.GRAVITY, z=0}

	-- Get player controls, or no controls if no rider.
	local ctrl = {}
	if self.rider then
		local pref = minetest.get_player_by_name(self.rider)
		if pref then
			ctrl = lagwing.do_player_controls(self, pref, dtime)
		else
			-- Player left while riding.
			self.rider = nil
		end
	end

	-- If we collide with the ground at low velocity, turn into a landing.
	if not self.landing and not self.takeoff then
		if self.airspeed <= lagwing.MIN_AIRSPEED then
			if collides_with_ground(moveresult) then
				self.landing = true
			end
		end
	end

	-- Altitude detection.
	local dist1
	local dist2

	if not self.landing then
		dist1 = distance_to_obstacle(obj:get_pos(), {x=(math.random(-10, 10) / 20), y=-1, z=(math.random(-10, 10) / 20)})
		dist2 = distance_to_obstacle(obj:get_pos(), get_velocity(1, obj:get_yaw() + (math.random(-10, 10) / 20), -1 + (math.random(-10, 10) / 20)))
	end

	if in_dive(obj) then
		-- Since we're a flier, assume we can arrest our fall. Cap max descent rate.
		local v = obj:get_velocity()
		if v.y < lagwing.MAX_DIVE_RATE then
			acc = vector.add(acc, {x=0, y=-(lagwing.GRAVITY), z=0})
		end
	elseif in_climb(obj) then
		-- We are climbing.
		local v = obj:get_velocity()
		if v.y < lagwing.MAX_CLIMB_ACCEL then
			acc = vector.add(acc, {x=0, y=(-lagwing.GRAVITY)+lagwing.MAX_CLIMB_ACCEL, z=0})
			if ctrl.sneak then
				acc = vector.add(acc, {x=0, y=2, z=0})
			end
		end
	elseif not self.landing then
		local v = obj:get_velocity()
		local r = obj:get_rotation()

		-- Pitching up.
		if r.x > ((lagwing.MAX_CLIMB_ANGLE / 3) * 2) then
			acc = vector.add(acc, {x=0, y=(lagwing.MAX_CLIMB_ACCEL / 2), z=0})
		elseif r.x > (lagwing.MAX_CLIMB_ANGLE / 3) then
			acc = vector.add(acc, {x=0, y=(lagwing.MAX_CLIMB_ACCEL / 4), z=0})
		end

		-- Pitching down.
		if r.x < ((lagwing.MAX_DIVE_ANGLE / 3) * 2) then
			acc = vector.add(acc, {x=0, y=(lagwing.MAX_DESCENT_RATE / 2), z=0})
		elseif r.x < (lagwing.MAX_DIVE_ANGLE / 3) then
			acc = vector.add(acc, {x=0, y=(lagwing.MAX_DESCENT_RATE / 4), z=0})
		end

		-- Flying against gravity.
		if v.y < 0.0 then
			acc = vector.add(acc, {x=0, y=-(lagwing.GRAVITY), z=0})
		end
	end

	-- If we had entered a dive, and have now leveled out, end the dive.
	if true then
		local v = obj:get_velocity()
		if v.y >= 0.0 and self.entered_dive then
			self.entered_dive = false
			local d = distance_to_obstacle(obj:get_pos(), {x=0, y=-1, z=0})
			if d then
				self.wanted_altitude = d
			end
		end
	end

	local dist3_center
	local dist3_left
	local dist3_right

	if not self.landing then
		-- The center ray is raised slightly with respect to the left and right.
		-- This causes us to fly straight over flat terrain.
		local steerray_drop = self.steerray_drop

		dist3_center = distance_to_obstacle(obj:get_pos(), get_velocity(1, obj:get_yaw() + (math.random(-10, 10) / 30), steerray_drop + 0.1))
		dist3_left = distance_to_obstacle(obj:get_pos(), get_velocity(1, obj:get_yaw() + math.rad(35) + (math.random(-10, 10) / 30), steerray_drop))
		dist3_right = distance_to_obstacle(obj:get_pos(), get_velocity(1, obj:get_yaw() - math.rad(35) + (math.random(-10, 10) / 30), steerray_drop))

		-- Auto adjust steer ray altitude to increase contact with the ground.
		-- Need to make sure the "feelers" are touching something as much as possible.
		if not dist3_center or not dist3_left or not dist3_right then
			self.steerray_drop = self.steerray_drop - (0.1 * dtime)
			if self.steerray_drop < lagwing.MIN_STEERRAY_ANGLE then
				self.steerray_drop = lagwing.MIN_STEERRAY_ANGLE
			end
		end
		if dist3_center and dist3_left and dist3_right then
			self.steerray_drop = self.steerray_drop + (0.1 * dtime)
			if self.steerray_drop > lagwing.MAX_STEERRAY_ANGLE then
				self.steerray_drop = lagwing.MAX_STEERRAY_ANGLE
			end
		end
	end

	-- At the end of a dive, set the current altitude as the desired altitude.
	if in_dive(obj) and not self.diving then
		self.diving = true
		self.entered_dive = true
	end
	if not in_dive(obj) and self.diving then
		self.diving = false
	end

	-- At the end of a climb, set the current altitude as the desired altitude.
	if in_climb(obj) and not self.climbing then
		self.climbing = true
	end
	if not in_climb(obj) and self.climbing then
		self.climbing = false
	end

	if ctrl.up or ctrl.down then
		local d = distance_to_obstacle(obj:get_pos(), {x=0, y=-1, z=0})
		if d then
			self.wanted_altitude = d
		end
	end

	-- Make sure wanted altitude is clamped.
	if self.wanted_altitude > lagwing.MAX_ALTITUDE then
		self.wanted_altitude = lagwing.MAX_ALTITUDE
	end
	if self.wanted_altitude < lagwing.MIN_ALTITUDE then
		self.wanted_altitude = lagwing.MIN_ALTITUDE
	end

	-- Auto maintain altitude above ground, if we're not diving or climbing.
	-- Altitude is maintained by pitching up or down as needed.
	self.pitch_up = false
	self.pitch_down = false
	if not ctrl.up and not ctrl.down and not self.landing then
		local avgdist = dist1 or 1000
		if dist1 and dist2 then
			if (dist2 * 0.5) < dist1 then
				avgdist = (dist2 * 0.5)
			end
		end

		if avgdist then
			local H = self.wanted_altitude
			local D = math.abs(H - avgdist)
			local A = 5

			-- Adjust tolerance for altitude changes based on the wanted altitude.
			-- If we're high up, tolerance can be a lot higher.
			if H > (lagwing.MAX_ALTITUDE / 2) then
				A = 20
			elseif H <= lagwing.MIN_ALTITUDE then
				A = 3
			else
				A = 15
			end

			if (avgdist < H and D > A) then
				self.pitch_up = true
				self.pitch_down = false
			elseif (avgdist > H and D > A) then
				self.pitch_down = true
				self.pitch_up = false
			end
		end
	end

	-- Auto steer to avoid tall obstacles in our path.
	if not self.landing and not ctrl.left and not ctrl.right and not ctrl.up and not ctrl.down then
		local dist = dist3_center or 1000
		local left = dist3_left or 1000
		local right = dist3_right or 1000
		local under = dist1 or 1000
		local ahead = dist2 or 1000

		-- Not avoiding obstacle by default.
		self.avoiding_obstacle = false

		-- Open space to the left, turn left.
		if left > dist and left > right then
			self.circle_left = true
			self.circle_right = false
		end

		-- Open space to the right, turn right.
		if right > dist and right > left then
			self.circle_right = true
			self.circle_left = false
		end

		-- Open space straight ahead, go forward.
		if dist > right and dist > left then
			self.circle_left = false
			self.circle_right = false
		end

		-- Obstacle to the near left, turn right.
		if left < lagwing.OBSTACLE_AVOID_DISTANCE and left < dist and left < right then
			self.circle_right = true
			self.circle_left = false
			self.avoiding_obstacle = true
		end

		-- Obstacle to the near right, turn left.
		if right < lagwing.OBSTACLE_AVOID_DISTANCE and right < dist and right < left then
			self.circle_left = true
			self.circle_right = false
			self.avoiding_obstacle = true
		end

		-- Too low, pitch up!
		if under < lagwing.MIN_ALTITUDE or ahead < lagwing.OBSTACLE_AVOID_DISTANCE then
			self.pitch_up = true
			self.pitch_down = false
		end

		-- Too high, pitch down!
		if under > lagwing.MAX_ALTITUDE then
			self.pitch_down = true
			self.pitch_up = false
		end
	end

	-- Check if we need to climb out of a dive.
	if true then
		local v = obj:get_velocity()
		local ahead = dist2 or 1000

		-- Dropping too fast, pitch up!
		if self.entered_dive and v.y < 0.0 and ahead < lagwing.DIVE_ABORT_ALTITUDE then
			self.pitch_up = true
			self.pitch_down = false
		end
	end

	-- Auto rotate so we fly in a circle (unless rider directs yaw).
	-- Slowly circle left or right.
	if not self.landing then
		local turnrate = lagwing.SLOW_TURN_RATE
		local rollangle = lagwing.MAX_ROLL_ANGLE

		if self.wanted_altitude > ((lagwing.MAX_ALTITUDE / 4) * 3) then
			turnrate = (lagwing.SLOW_TURN_RATE / 6)
			rollangle = (lagwing.MAX_ROLL_ANGLE / 3)
		elseif self.wanted_altitude > (lagwing.MAX_ALTITUDE / 2) then
			turnrate = (lagwing.SLOW_TURN_RATE / 2)
			rollangle = (lagwing.MAX_ROLL_ANGLE / 2)
		end

		if self.avoiding_obstacle or ctrl.left or ctrl.right then
			turnrate = lagwing.MAX_TURN_RATE
			rollangle = lagwing.MAX_ROLL_ANGLE
		end

		if self.circle_left then
			local r = obj:get_rotation()
			r.y = r.y + (turnrate * dtime)
			obj:set_rotation(r)
		elseif self.circle_right then
			local r = obj:get_rotation()
			r.y = r.y - (turnrate * dtime)
			obj:set_rotation(r)
		end

		-- Auto roll to match direction of turn.
		if self.circle_right then
			local r = obj:get_rotation()
			if r.z < rollangle then
				r.z = r.z + (lagwing.MAX_ROLL_RATE * dtime)
			else
				r.z = r.z - (lagwing.MAX_ROLL_RATE * dtime)
			end
			obj:set_rotation(r)
		elseif self.circle_left then
			local r = obj:get_rotation()
			if r.z > -rollangle then
				r.z = r.z - (lagwing.MAX_ROLL_RATE * dtime)
			else
				r.z = r.z + (lagwing.MAX_ROLL_RATE * dtime)
			end
			obj:set_rotation(r)
		end
	end

	-- Auto roll to horizontal.
	if (not self.circle_left and not self.circle_right) or self.landing then
		local r = obj:get_rotation()

		if r.z > 0 then
			r.z = r.z - (lagwing.MAX_ROLL_RATE * dtime)
			if r.z < 0 then r.z = 0 end
		elseif r.z < 0 then
			r.z = r.z + (lagwing.MAX_ROLL_RATE * dtime)
			if r.z > 0 then r.z = 0 end
		end

		obj:set_rotation(r)
	end

	-- Auto pitch toward horizontal (unless rider directs pitch).
	if true then
		local r = obj:get_rotation()

		local minv = -3.0
		local maxv = 3.0
		local D = self.wanted_altitude

		if (self.pitch_up or ctrl.down) and not self.landing and D < lagwing.MAX_ALTITUDE then
			-- Pitch up.
			local prate = lagwing.MAX_PITCH_RATE

			-- If in a dive, the upward pitch rate is multiplied for emergency.
			if self.entered_dive then
				prate = lagwing.MAX_PITCH_RATE * 3
			end

			if r.x < lagwing.MAX_CLIMB_ANGLE then
				r.x = r.x + (prate * dtime)
				if r.x > lagwing.MAX_CLIMB_ANGLE then
					r.x = lagwing.MAX_CLIMB_ANGLE
				end
				obj:set_rotation(r)
			end
		elseif (self.pitch_down or ctrl.up) and not self.landing and D > lagwing.MIN_ALTITUDE then
			-- Pitch down.
			if r.x > lagwing.MAX_DIVE_ANGLE then
				r.x = r.x - (lagwing.MAX_PITCH_RATE * dtime)
				if r.x < lagwing.MAX_DIVE_ANGLE then
					r.x = lagwing.MAX_DIVE_ANGLE
				end
				obj:set_rotation(r)
			end
		else
			-- Pitch toward horizontal, if not trying to pitch up or down.
			if r.x < 0 then
				r.x = r.x + (lagwing.MAX_PITCH_RATE * dtime)
				if r.x > 0 then r.x = 0 end
				obj:set_rotation(r)
			elseif r.x > 0 then
				r.x = r.x - (lagwing.MAX_PITCH_RATE * dtime)
				if r.x < 0 then r.x = 0 end
				obj:set_rotation(r)
			end
		end
	end

	-- Auto reduce airspeed over time, reduce it more if we're climbing.
	if not ctrl.sneak or in_climb(obj) then
		local rate = 0.3
		if in_climb(obj) then
			rate = 2
		end
		self.airspeed = self.airspeed - (rate * dtime)
		if self.airspeed < lagwing.MIN_AIRSPEED and not self.landing and not self.takeoff then
			self.airspeed = lagwing.MIN_AIRSPEED
		end
		if self.airspeed < 0 then
			self.airspeed = 0
		end
	end

	-- Increase airspeed if diving.
	if in_dive(obj) then
		self.airspeed = self.airspeed + (lagwing.MAX_ACCEL * dtime)
		if self.airspeed > lagwing.MAX_AIRSPEED then
			self.airspeed = lagwing.MAX_AIRSPEED
		end
	end

	-- Decrease airspeed if there's something close right in front of us.
	-- Gives us more time to go around, or up and over, without striking ground.
	if dist3_center and dist3_center < lagwing.OBSTACLE_SLOW_DISTANCE then
		self.airspeed = self.airspeed - (lagwing.MAX_ACCEL * dtime)
		if self.airspeed < lagwing.MIN_AIRSPEED and not self.landing and not self.takeoff then
			self.airspeed = lagwing.MIN_AIRSPEED
		end
	end

	-- Reduce airspeed to 0 if we're landing. Increase airspeed from 0 if taking off.
	if self.landing then
		if self.airspeed > 0 then
			self.airspeed = self.airspeed - ((lagwing.MAX_ACCEL / 4) * dtime)
		end
		if self.airspeed < 0 then
			self.airspeed = 0
		end
	elseif self.takeoff then
		if self.airspeed < lagwing.MIN_AIRSPEED then
			self.airspeed = self.airspeed + ((lagwing.MAX_ACCEL / 2) * dtime)
		end
		if self.airspeed >= lagwing.MIN_AIRSPEED then
			self.takeoff = false
		end
	end

	-- Auto fly toward facing direction. Since we're a flier, we can't stop in the
	-- air, we must always be going forward.
	if true then
		local r = obj:get_rotation()
		local ovel = obj:get_velocity()
		--local nvel = get_velocity(self.airspeed, r.y, ovel.y)

		local sin = math.sin
		local cos = math.cos

		local yaw = r.y
		local pitch = r.x

		-- Developed by trial and error. Not sure about the math, but seems to work.
		local nvel = {
			x = -sin(yaw),
			y = sin(pitch),
			z = cos(yaw),
		}

		nvel = vector.normalize(nvel)
		nvel = vector.multiply(nvel, self.airspeed)

		if self.landing then
			nvel.y = ovel.y
		end

		obj:set_velocity(nvel)
		obj:set_acceleration(acc)
	end
end
