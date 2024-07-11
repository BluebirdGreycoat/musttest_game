
function lagwing.on_activate(self, staticdata, dtime_s)
	self.airspeed = 10
	self.wanted_altitude = 30
	self.steerray_drop = -0.3

	-- Randomly chose whether to circle left or right.
	if not self.circle_left and not self.circle_right then
		if math.random(0, 1) == 0 then
			self.circle_left = true
			self.circle_right = false
		else
			self.circle_left = false
			self.circle_right = true
		end
	end
end

function lagwing.on_deactivate(self, removal)
end

function lagwing.on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
end

function lagwing.on_death(self, killer)
end

function lagwing.on_rightclick(self, clicker)
	if not self.rider then
		if not clicker:get_attach() then
			clicker:set_attach(self.object)
			self.rider = clicker:get_player_name()
			return
		end
	end

	if self.rider == clicker:get_player_name() then
		clicker:set_detach()
		self.rider = nil
		return
	end
end

function lagwing.get_staticdata(self)
end

function lagwing.on_blast(self, damage)
end

function lagwing.on_step(self, dtime, moveresult)
	lagwing.do_flightmodel(self, dtime, moveresult)
end

function lagwing.on_attach_child(self, child)
end

function lagwing.on_detach_child(self, child)
end

function lagwing.on_detach(self, parent)
end
