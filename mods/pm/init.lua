
pm = pm or {}
pm.modpath = minetest.get_modpath("pm")
pm.sight_range = 30
pm.nest_range = 15

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
dofile(pm.modpath .. "/spawner.lua")
dofile(pm.modpath .. "/entity.lua")

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

local overrides = {
	nest_guard = {
		-- Wisp is persistent and will not alter behavior.
		_no_autochose_behavior = true,
		_no_lifespan_limit = true,
	},

	nest_worker = {
		-- Wisp is persistent and will not alter behavior.
		_no_autochose_behavior = true,
		_no_lifespan_limit = true,
	},
}

-- Create entity at position, if possible.
function pm.spawn_wisp(pos, behavior)
	pos = vector_round(pos)
	local node = minetest.get_node(pos)

	local pos_ok = false
	if node.name == "air" then
		pos_ok = true
	else
		local ndef = minetest.registered_nodes[node.name]
		if ndef and not ndef.walkable then
			pos_ok = true
		end
	end

	if pos_ok then
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

				-- Apply overrides if wanted.
				if overrides[behavior] then
					local o = overrides[behavior]
					for k, v in pairs(o) do
						luaent[k] = v
					end
				end

				return ent, luaent
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
	"nest_guard",
	"arsonist",
	"porter",
	"pusher",
	"nest_worker",
}

function pm.choose_random_behavior(self)
	self._behavior = behaviors[math_random(1, #behaviors)]

	-- Don't chose a self-destructive behavior by chance.
	if self._behavior == "boom" then
		self._behavior = "follower"
	elseif self._behavior == "nest_guard" then
		self._behavior = "guard"
	elseif self._behavior == "nest_worker" then
		self._behavior = "explorer"
	end
end

-- Create entity at position, if possible.
function pm.spawn_random_wisp(pos)
	local act = behaviors[math_random(1, #behaviors)]
	if act == "boom" then
		act = "follower"
	elseif act == "nest_guard" then
		act = "guard"
	elseif act == "nest_worker" then
		act = "explorer"
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
		return pm.seek_player_or_mob_not_wisp(self, pos)
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

	-- Never chosen at random, can only be deliberately created.
	nest_guard = function(self, pos)
		-- Seek target in sight-range of spawn origin, otherwise return to origin.
		if self._spawn_origin then
			local origin = minetest.string_to_pos(self._spawn_origin)
			if origin then
				if vector_distance(origin, self.object:get_pos()) > pm.nest_range then
					return origin, nil
				else
					-- Within sight range of spawn origin, seek target.
					return pm.seek_player(self, pos)
				end
			end
		end
		return nil, nil
	end,

	-- Never chosen at random, can only be deliberately created.
	nest_worker = function(self, pos)
		-- Seek target in sight-range of spawn origin, otherwise return to origin.
		if self._spawn_origin then
			local origin = minetest.string_to_pos(self._spawn_origin)
			if origin then
				if vector_distance(origin, self.object:get_pos()) > pm.sight_range then
					return origin, nil
				else
					-- Within sight range of spawn origin, seek target.
					return pm.seek_flora(self, pos)
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

	nest_guard = function(self, pos, target)
		-- Attack target, but only if in sight-range of spawn origin.
		if self._spawn_origin then
			local origin = minetest.string_to_pos(self._spawn_origin)
			if origin then
				if vector_distance(origin, self.object:get_pos()) < pm.nest_range then
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
		_cmi_is_mob = true,

		on_step = function(...) return pm.follower_on_step(...) end,
		on_punch = function(...) return pm.follower_on_punch(...) end,
		on_activate = function(...) return pm.follower_on_activate(...) end,
		get_staticdata = function(...) return pm.follower_get_staticdata(...) end,

		_interest_point = function(...) return pm.interest_point(...) end,
		_on_arrival = function(...) return pm.on_arrival(...) end,
	}

	minetest.register_entity("pm:follower", entity)

	minetest.register_node("pm:spawner", {
		drawtype = "airlike",
		description = "Wisp Spawner (Please Report to Admin)",
		paramtype = "light",
		sunlight_propagates = true,
		walkable = false,
		pointable = false,
		groups = {immovable = 1},
		climbable = false,
		buildable_to = true,
		floodable = true,
		drop = "",

		on_construct = function(...)
			return pm.on_nodespawner_construct(...)
		end,

		on_destruct = function(...)
			return pm.on_nodespawner_destruct(...)
		end,

		on_timer = function(...)
			return pm.on_nodespawner_timer(...)
		end,

		on_finish_collapse = function(pos, node)
			minetest.remove_node(pos)
		end,

		on_collapse_to_entity = function(pos, node)
    	-- Do nothing.
  	end,
	})

	minetest.register_node("pm:quartz_ore", {
		description = "Quartz Crystals In Sand",
		tiles = {"default_desert_sand.png^quartz_ore.png"},
		groups = utility.dig_groups("mineral"),
		drop = 'quartz:quartz_crystal',
		sounds = default.node_sound_stone_defaults(),
		silverpick_drop = true,
		place_param2 = 10,
		movement_speed_multiplier = default.SLOW_SPEED,

		after_destruct = function(pos, oldnode)
			if math_random(1, 500) == 1 then
				pm.spawn_random_wisp(pos)
			end
		end,
	})

	local c = "pm:core"
	local f = pm.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	pm.registered = true
end
