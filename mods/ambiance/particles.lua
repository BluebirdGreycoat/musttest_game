
particles = particles or {}
particles.modpath = minetest.get_modpath("ambiance")



-- Food crumbs when player eats something.
function ambiance.particles_eat_item(user, name)
	local def = minetest.registered_items[name]
	if not def then
		return
	end

	local texture = ""
	if def.inventory_image then
		texture = def.inventory_image
	elseif def.wield_image then
		texture = def.wield_image
	end

	if texture == "" then
		return
	end

	local rnd = function(u, l)
		return math.random(u*10, l*10)/10
	end

	local pos = user:get_pos()
	local yaw = user:get_look_horizontal()
	local forward = vector.multiply(minetest.yaw_to_dir(yaw), 0.3)
	local push = vector.multiply(minetest.yaw_to_dir(yaw), 1.5)
	pos = vector.add(pos, forward)
	local particles = {
		amount = math.random(2, 5),
		time = 0.2,
		minpos = vector.add(pos, {x=-0.1, y=1.1, z=-0.1}),
		maxpos = vector.add(pos, {x=0.1, y=1.6, z=0.1}),
		minvel = vector.add(vector.new(-0.3, 0.3, -0.3), push),
		maxvel = vector.add(vector.new(0.3, 0.6, 0.3), push),
		minacc = vector.new(0.0, -8.0, 0.0),
		maxacc = vector.new(0.0, -8.0, 0.0),
		minexptime = 0.5,
		maxexptime = 2,
		minsize = 0.8,
		maxsize = 1.3,
		collisiondetection = true,
		collision_removal = true,
		vertical = false,
		texture = texture,
	}
	minetest.add_particlespawner(particles)
end



-- Particles when player is entirely submerged.
function ambiance.particles_underwater(pos)
	local rnd = function(u, l)
		return math.random(u*10, l*10)/10
	end

	local particles = {
		amount = math.random(5, 10),
		time = 1.0,
		minpos = vector.add(pos, -0.5),
		maxpos = vector.add(pos, 0.5),
		minvel = vector.new(0.5, 0.5, 0.5),
		maxvel = vector.new(-0.5, -0.5, -0.5),
		minacc = vector.new(0.1, 0.1, 0.1),
		maxacc = vector.new(-0.1, -0.1, -0.1),
		minexptime = 0.5,
		maxexptime = 2,
		minsize = 0.1,
		maxsize = 1.0,
		collisiondetection = false,
		collision_removal = false,
		vertical = false,
		texture = "default_water.png",
	}
	minetest.add_particlespawner(particles)
end



-- Swimming particles when player is swimming on water surface.
function ambiance.particles_swimming(pos)
	local rnd = function(u, l)
		return math.random(u*10, l*10)/10
	end

	local bubbles = {
		amount = math.random(5, 10),
		time = 1.0,
		minpos = vector.add(pos, -0.5),
		maxpos = vector.add(pos, 0.5),
		minvel = vector.new(-0.5, 0.0, -0.5),
		maxvel = vector.new(0.5, 0.5, 0.5),
		minacc = vector.new(0.0, -6, 0.0),
		maxacc = vector.new(0.0, -10, 0.0),
		minexptime = 0.5,
		maxexptime = 2,
		minsize = 0.5,
		maxsize = 1.5,
		collisiondetection = false,
		collision_removal = false,
		vertical = false,
		texture = "bubble.png",
	}
	minetest.add_particlespawner(bubbles)
	local splash = {
		amount = math.random(5, 10),
		time = 1.0,
		minpos = vector.add(pos, -0.5),
		maxpos = vector.add(pos, 0.5),
		minvel = vector.new(-0.5, 0.0, -0.5),
		maxvel = vector.new(0.5, 0.5, 0.5),
		minacc = vector.new(0.0, -6, 0.0),
		maxacc = vector.new(0.0, -10, 0.0),
		minexptime = 0.5,
		maxexptime = 2,
		minsize = 0.1,
		maxsize = 1.0,
		collisiondetection = false,
		collision_removal = false,
		vertical = false,
		texture = "default_water.png",
	}
	minetest.add_particlespawner(splash)
end



local function get_texture(node)
	local texture = ""
	local def = minetest.registered_items[node.name]

	if def then
		if def.tiles and def.tiles[1] then
			if type(def.tiles[1]) == "string" then
				texture = def.tiles[1]
			end
		end
	end

	-- If no texture could be found, calling function should abort.
	return texture
end



function ambiance.particles_on_dig(pos, node)
	local texture = get_texture(node)
	if texture == "" then
		return
	end
	local particles = {
		amount = math.random(5, 10),
		time = 0.1,
		minpos = vector.add(pos, -0.49),
		maxpos = vector.add(pos, 0.49),
		minvel = {x=0, y=1, z=0},
		maxvel = {x=0, y=2, z=0},
		minacc = {x=0, y=-10, z=0},
		maxacc = {x=0, y=-10, z=0},
		minexptime = 0.5,
		maxexptime = 1,
		minsize = 1,
		maxsize = 1,
		collisiondetection = true,
		collision_removal = false,
		vertical = false,
		texture = texture,
	}
	minetest.add_particlespawner(particles)
end



function ambiance.particles_on_punch(pos, node)
	local texture = get_texture(node)
	if texture == "" then
		return
	end
	local particles = {
		amount = math.random(1, 5),
		time = 0.1,
		minpos = vector.add(pos, -0.49),
		maxpos = vector.add(pos, 0.49),
		minvel = {x=-0.3, y=0, z=-0.3},
		maxvel = {x=0.3, y=0, z=0.3},
		minacc = {x=0, y=-10, z=0},
		maxacc = {x=0, y=-10, z=0},
		minexptime = 0.5,
		maxexptime = 1,
		minsize = 1,
		maxsize = 1,
		collisiondetection = true,
		collision_removal = false,
		vertical = false,
		texture = texture,
	}
	minetest.add_particlespawner(particles)
end



function ambiance.particles_on_place(pos, node)
	local texture = get_texture(node)
	if texture == "" then
		return
	end
	local particles = {
		amount = math.random(5, 10),
		time = 0.1,
		minpos = vector.add(pos, -0.49),
		maxpos = vector.add(pos, 0.49),
		minvel = {x=-0.3, y=0, z=-0.3},
		maxvel = {x=0.3, y=0, z=0.3},
		minacc = {x=0, y=-10, z=0},
		maxacc = {x=0, y=-10, z=0},
		minexptime = 0.5,
		maxexptime = 1,
		minsize = 1,
		maxsize = 1,
		collisiondetection = true,
		collision_removal = false,
		vertical = false,
		texture = texture,
	}
	minetest.add_particlespawner(particles)
end



local function player_nearby(pos)
	local players = minetest.get_connected_players()
	for k, v in ipairs(players) do
		if vector.distance(pos, v:get_pos()) < 16 then
			return true
		end
	end
end



function ambiance.flamespawner(self, dtime)
	self.st = (self.st or 0) - dtime
	self.ct = (self.ct or 0) - dtime
	self.nt = (self.nt or 0) - dtime

	-- Remove spawner if no flame here.
	if self.nt < 0 then
		self.nt = math.random(10, 60)
		local pos = self.object:get_pos()
		local nn = minetest.get_node(pos).name
		if not string.find(nn, "^fire:") and not string.find(nn, "^maptools:") then
			self.object:remove()
		end
	end

	-- Check every so often if a player is nearby.
	if self.ct < 0 then
		local pos = self.object:get_pos()
		self.good = player_nearby(pos)
		self.ct = math.random(2, 8)
	end

	if self.st < 0 then
		local rnd = function(u, l)
			return math.random(u*10, l*10)/10
		end
		self.st = rnd(0.5, 1.0)

		-- Spawn particle only if player nearby.
		if self.good then
			local pos = self.object:get_pos()
			local particle = {
				pos = {x=pos.x+rnd(-0.5, 0.5), y=pos.y+rnd(0.0, 0.5), z=pos.z+rnd(-0.5, 0.5)},
				velocity = {x=rnd(-0.1, 0.1), y=rnd(0.1, 0.7), z=rnd(-0.1, 0.1)},
				acceleration = {x=rnd(-0.1, 0.1), y=rnd(0.1, 0.7), z=rnd(-0.1, 0.1)},
				expirationtime = rnd(0.1, 2.0),
				size = rnd(0.3, 0.7),
				collisiondetection = false,
				collision_removal = false,
				vertical = false,
				texture = "particles.png",
				animation = {
					type = "vertical_frames",
					aspect_w = 1,
					aspect_h = 1,
					length = 1.0,
				},
				glow = rnd(10, 15),
			}
			if math.random(1, 6) == 1 then
				particle.texture = "smoke_particles.png"
				particle.animation = {
					type = "vertical_frames",
					aspect_w = 4,
					aspect_h = 4,
					length = 1.0,
				}
				particle.size = rnd(0.8, 1.1)
				particle.velocity.y = particle.velocity.y + rnd(0.2, 0.4)
				particle.pos.y = pos.y + rnd(0.4, 0.6)
			end
			minetest.add_particle(particle)

			-- Occasionally play flame sound.
			if math.random(1, 10) == 1 then
				ambiance.sound_play("fire_small", pos, 1.0, 16)
			end
		end
	end
end



function particles.add_flame_spawner(pos)
	minetest.add_entity(pos, "particles:flamespawner")
end



function particles.del_flame_spawner(pos)
	local ents = minetest.get_objects_inside_radius(pos, 0.6)
	if ents then
		for k, obj in ipairs(ents) do
			if obj and obj:get_luaentity() and obj:get_luaentity().name == "particles:flamespawner" then
				obj:remove()
			end
		end
	end
end



function particles.restore_flame_spawner(pos)
	particles.del_flame_spawner(pos)
	particles.add_flame_spawner(pos)
end



if not particles.run_once then
	-- File is reloadable.
	local c = "particles:core"
	local f = particles.modpath .. "/particles.lua"
	reload.register_file(c, f, false)

	-- Torches no longer spawn particles, this creates too many entities and network packets.
	-- The entity definition now only exists to delete existing torchspawners from the world.
	local torchspawner = {
		visual = "wielditem",
		visual_size = {x=0, y=0},
		collisionbox = {0, 0, 0, 0, 0, 0},
		physical = false,
		textures = {"air"},

		on_activate = function(self, staticdata, dtime_s)
			self.object:remove()
		end,

		on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		end,

		on_death = function(self, killer)
		end,

		on_rightclick = function(self, clicker)
		end,

		get_staticdata = function(self)
			return ""
		end,

		on_step = function(self, dtime)
			self.object:remove()
		end,
	}
	minetest.register_entity(":particles:torchspawner", torchspawner)

	local flamespawner = {
		visual = "wielditem",
		visual_size = {x=0, y=0},
		collisionbox = {0, 0, 0, 0, 0, 0},
		physical = false,
		textures = {"air"},

		on_activate = function(self, staticdata, dtime_s)
		end,

		on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		end,

		on_death = function(self, killer)
		end,

		on_rightclick = function(self, clicker)
		end,

		get_staticdata = function(self)
			return ""
		end,

		on_step = function(self, dtime)
			return ambiance.flamespawner(self, dtime)
		end,
	}
	minetest.register_entity(":particles:flamespawner", flamespawner)

	particles.run_once = true
end
