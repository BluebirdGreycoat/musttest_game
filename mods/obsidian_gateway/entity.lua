
local function spawn_particles(pos)
	for k, v in ipairs({
		{texture = "quartz_crystal_piece.png", vel=1.5, dst=0, a=60},
		{texture = "default_coal_lump.png", vel=0.5, dst=1, a=40},
		{texture = "default_mese_crystal.png", vel=0.5, dst=1, a=10},
	}) do
		local D = v.dst
		local V = v.vel
		local particles = {
			amount = v.a,
			time = 3,
			minpos = vector.add(pos, {x=-D, y=-D, z=-D}),
			maxpos = vector.add(pos, {x=D, y=D, z=D}),
			minvel = vector.new(-V, -V, -V),
			maxvel = vector.new(V, V, V),
			minacc = {x=0, y=0, z=0},
			maxacc = {x=0, y=0, z=0},
			minexptime = 0.5,
			maxexptime = 2.0,
			minsize = 0.5,
			maxsize = 1.0,
			collisiondetection = false,
			collision_removal = false,
			vertical = false,
			texture = v.texture,
			glow = 14,
		}
		minetest.add_particlespawner(particles)
	end
end

local function send_player_to(pname, target)
	preload_tp.execute({
		player_name = pname,
		target_position = target,
		send_blocks = true,
		particle_effects = true,
		spinup_time = 3,

		pre_teleport_callback = function()
		end,

		on_map_loaded = function()
		end,

		post_teleport_callback = function()
			portal_sickness.on_use_portal(pname)
		end,
	})
end

function obsidian_gateway.on_portent_activate(self, staticdata, dtime_s)
	local data = minetest.parse_json(staticdata)
	if not data or type(data) ~= "table" then
		self.object:remove()
		return
	end

	self.time = 0
	self.target = data.target
	self.realm = data.realm or ""
end

function obsidian_gateway.on_portent_deactivate(self, removal)
end

function obsidian_gateway.on_portent_punch(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
end

function obsidian_gateway.on_portent_death(self, killer)
end

function obsidian_gateway.on_portent_rightclick(self, clicker)
end

function obsidian_gateway.portent_get_staticdata(self)
	return minetest.write_json({
		target = self.target,
		realm = self.realm or "",
	})
end

function obsidian_gateway.on_portent_blast(self, damage)
	return false, false, {}
end

function obsidian_gateway.on_portent_step(self, dtime, moveresult)
	-- Do our logic once per second.
	self.time = self.time + dtime
	if self.time < 1 then
		return
	end
	self.time = 0

	local pos = vector.round(self.object:get_pos())
	local minp = vector.offset(pos, -5, -5, -5)
	local maxp = vector.offset(pos, 5, 5, 5)
	local objs = minetest.get_objects_in_area(minp, maxp)

	-- Remove duplicates.
	local foundme = false
	for k = 1, #objs do
		local ent = objs[k]:get_luaentity()
		if ent then
			if ent.name == "obsidian_gateway:portent" then
				if foundme then
					self.object:remove()
					return
				else
					foundme = true
				end
			end
		end
	end

	spawn_particles(pos)

	local players = minetest.get_connected_players()
	for k = 1, #players do
		local p = players[k]:get_pos()
		if vector.distance(p, pos) < 3 then
			if self.target then
				local pname = players[k]:get_player_name()
				if not default.player_attached[pname] and not players[k]:get_attach() then
					if not preload_tp.teleport_in_progress(pname) then
						send_player_to(pname, self.target)

						-- Only teleport one player at this time.
						return
					end
				end
			end
		end
	end

	-- Remove the entity once the gate stops pointing here.
	local strexitpos = serveressentials.get_current_exit_location(self.realm)
	local exitpos = minetest.string_to_pos(strexitpos)
	if exitpos then
		if vector.distance(pos, exitpos) > 15 then
			self.object:remove()
			return
		end
	end
end

function obsidian_gateway.on_portent_attach_child(self, child)
end

function obsidian_gateway.on_portent_detach_child(self, child)
end

function obsidian_gateway.on_portent_detach(self, parent)
end

-- Constructor function.
function obsidian_gateway.create_portal_entity(pos, data)
	pos = vector.round(pos)

	data = data or {}
	data.target = data.target or {x=0, y=0, z=0}
	data.realm = rc.current_realm_at_pos(pos)
	local json = minetest.write_json(data)

	local obj = minetest.add_entity(pos, "obsidian_gateway:portent", json)
	if not obj then
		return
	end

	local ent = obj:get_luaentity()
	if not ent then
		obj:remove()
		return
	end
end

if not obsidian_gateway.entity_registered then
	local entity = {
		initial_properties = {
			visual = "mesh",
			mesh = "boats_boat.obj",
			visual_size = {x=0, y=0},
			collisionbox = {0, 0, 0, 0, 0, 0},
			physical = false,
			textures = {"air"},
			is_visible = false,
			static_save = true,
		},

		on_activate = function(...)
			return obsidian_gateway.on_portent_activate(...)
		end,

		on_deactivate = function(...)
			return obsidian_gateway.on_portent_deactivate(...)
		end,

		on_punch = function(...)
			return obsidian_gateway.on_portent_punch(...)
		end,

		on_death = function(...)
			return obsidian_gateway.on_portent_death(...)
		end,

		on_rightclick = function(...)
			return obsidian_gateway.on_portent_rightclick(...)
		end,

		get_staticdata = function(...)
			return obsidian_gateway.portent_get_staticdata(...)
		end,

		on_blast = function(...)
			return obsidian_gateway.on_portent_blast(...)
		end,

		on_step = function(...)
			return obsidian_gateway.on_portent_step(...)
		end,

		on_attach_child = function(...)
			return obsidian_gateway.on_portent_attach_child(...)
		end,

		on_detach_child = function(...)
			return obsidian_gateway.on_portent_detach_child(...)
		end,

		on_detach = function(...)
			return obsidian_gateway.on_portent_detach(...)
		end,
	}

	minetest.register_entity("obsidian_gateway:portent", entity)
	obsidian_gateway.entity_registered = true
end
