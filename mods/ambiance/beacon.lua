
-- Localize for performance.
local vector_round = vector.round

-- Spawn a named sound beacon at `pos`, while ensuring that no more than `count`
-- beacons of the same type are spawned within `radius` meters.
function ambiance.spawn_sound_beacon(name, pos, radius, count)
	radius = radius or 0.5
	count = count or 1
	pos = vector_round(pos)
	local objs = minetest.get_objects_inside_radius(pos, radius)
	local c = 0

	for i = 1, #objs, 1 do
		local ent = objs[i]:get_luaentity()
		if ent then
			if ent.name == name then
				c = c + 1
				if c > count then
					-- Too many sound beacons of this type in the region.
					return
				end
			end
		end
	end

	--minetest.chat_send_all("added " .. name .. "!")
	local ent = minetest.add_entity(pos, name)
	if ent then
		local lent = ent:get_luaentity()
		if not lent then
			ent:remove()
			return
		end

		-- Set initial check/play times to zero,
		-- this makes sound play instantly on first spawn.
		if lent._play_immediate then
			lent._ctime = 0
			lent._ptime = 0
		end
	end
end

-- Trigger all sound beacons in a given radius to execute an environment recheck.
function ambiance.recheck_nearby_sound_beacons(pos, radius)
	--minetest.chat_send_all('recheck2')
	pos = vector_round(pos)
	local objs = minetest.get_objects_inside_radius(pos, radius)
	for i = 1, #objs, 1 do
		local ent = objs[i]:get_luaentity()
		if ent then
			if ent.name:find("^soundbeacon:") then
				--minetest.chat_send_all('recheck')
				ent._ctime = 0
			end
		end
	end
end

function ambiance.replay_nearby_sound_beacons(pos, radius)
	--minetest.chat_send_all('replay2')
	pos = vector_round(pos)
	local objs = minetest.get_objects_inside_radius(pos, radius)
	for i = 1, #objs, 1 do
		local ent = objs[i]:get_luaentity()
		if ent then
			if ent.name:find("^soundbeacon:") then
				--minetest.chat_send_all('replay')
				ent._ptime = 0
			end
		end
	end
end

function ambiance.spawn_sound_beacon_inside_area(name, pos, minp, maxp, radius, count)
	local p1 = vector.add(pos, minp)
	local p2 = vector.add(pos, maxp)
	local p3 = {x=0, y=0, z=0}
	p3.x = p1.x + p2.x / 2
	p3.y = p1.y + p2.y / 2
	p3.z = p1.z + p2.z / 2
	ambiance.spawn_sound_beacon(name, pos, radius, count)
end



function ambiance.register_sound_beacon(name, callbacks)
	local cmin = callbacks.check_time_min or callbacks.check_time
	local cmax = callbacks.check_time_max or callbacks.check_time
	local pmin = callbacks.play_time_min or callbacks.play_time
	local pmax = callbacks.play_time_max or callbacks.play_time

	local check = callbacks.on_check_environment
	local play = callbacks.on_play_sound
	local stop = callbacks.on_stop_sound

	local rand = math.random

	local beacondef = {
		visual = "wielditem",
		visual_size = {x=0, y=0},
		collisionbox = {0, 0, 0, 0, 0, 0},
		physical = false,
		textures = {"air"},
		is_visible = false,

		_play_immediate = callbacks.play_immediate,

		on_activate = function(self, staticdata, dtime_s)
			if self._play_immediate then
				self._ptime = 0
				self._ctime = 0
			end
		end,

		on_punch = function(self, puncher, time_from_last_punch, tool_caps, dir)
		end,

		on_death = function(self, killer)
		end,

		on_rightclick = function(self, clicker)
		end,

		get_staticdata = function(self)
			return ""
		end,

		on_step = function(self, dtime)
			local pos = vector_round(self.object:get_pos())
			self._data = self._data or {}
			local d = self._data

			self._ctime = (self._ctime or rand(cmin, cmax)) - dtime
			self._ptime = (self._ptime or rand(pmin, pmax)) - dtime
			self._xtime = (self._xtime or 0) + dtime

			if self._ctime < 0 then
				self._ctime = rand(cmin, cmax)
				if not check(d, pos) then
					if stop then
						stop(d)
					end
					self.object:remove()
					return
				end
			end

			if self._ptime < 0 then
				self._ptime = rand(pmin, pmax)
				play(d, pos, self._xtime)
				self._xtime = 0
			end
		end,
	}

	minetest.register_entity(name, beacondef)
end


