
lava_extras = lava_extras or {}
lava_extras.modpath = minetest.get_modpath("lava_extras")

-- Register mod as reloadable.
if minetest.get_modpath("reload") then
	local c = "lava_extras:core"
	local f = lava_extras.modpath .. "/init.lua"
	if not reload.file_registered(c) then
		reload.register_file(c, f, false)
	end
end

-- Particle def table is reused every time particles are spawned.
local particles = {
	amount = 1,
	time = 3,
	minpos = {x=0, y=0, z=0},
	maxpos = {x=0, y=0, z=0},
	minvel = {x=-1.5, y=2, z=-1.5},
	maxvel = {x=1.5, y=4, z=1.5},
	minacc = {x=-0.5, y=-3, z=-0.5},
	maxacc = {x=0.5, y=-9, z=0.5},
	minexptime = 0.5,
	maxexptime = 3,
	minsize = 1,
	maxsize = 2,
	collisiondetection = false,
	collision_removal = false,
	vertical = false,
	texture = "default_lava.png",
}

-- Localize for speed.
local random = math.random
local vadd = vector.add
local sfind = string.find
local addspawner = minetest.add_particlespawner
local fnn = minetest.find_node_near
local after = minetest.after
local rm = minetest.remove_node
local setn = minetest.add_node
local getn = minetest.get_node

local function do_spawn_particles(pos, node)
	-- Calculate particle parameters.
	particles.amount = random(2, 6)
	particles.minpos = vadd(pos, {x=-0.5, y=0.5, z=-0.5})
	particles.maxpos = vadd(pos, {x=0.5, y=0.5, z=0.5})

	if random(1, 100) > 95 then
		particles.minvel.y = 4
		particles.maxvel.y = 8
		particles.minsize = 2
		particles.maxsize = 4
	else
		particles.minvel.y = 3
		particles.maxvel.y = 5
		particles.minsize = 1
		particles.maxsize = 2
	end

	-- Choose particle texture.
	if sfind(node.name, "^default:") then
		particles.texture = "default_lava.png"
	else
		particles.texture = "lbrim_lava.png"
	end

	addspawner(particles)

	-- Occasionally spawn a real fire node.
	if random(1, 100) > 70 then
		local f = fnn(pos, 1, "air")
		if f then
			setn(f, {name="fire:basic_flame"})
			after(random(0.5, 5), function()
				local n2 = getn(f)
				if n2.name == "fire:basic_flame" then
					rm(f)
				end
			end)
		end
	end
end
lava_extras.spawn_particles = do_spawn_particles

if not lava_extras.registered then
	-- Spawn fire/particles around lava.
	minetest.register_abm({
			nodenames = {"group:lava"},
			neighbors = {"air"},
			interval = 5,
			chance = 1024,
			catch_up = false,
			action = do_spawn_particles,
	})

	lava_extras.registered = true
end

