
if not minetest.global_exists("preload_tp") then preload_tp = {} end
preload_tp.modpath = minetest.get_modpath("preload_tp")

-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round
local math_floor = math.floor



function preload_tp.finalize(parameters)
	local pname = parameters.player_name
	local force = parameters.force_teleport
	local pp = parameters.start_position
	local tp = parameters.target_position
	local pre_cb = parameters.pre_teleport_callback
	local post_cb = parameters.post_teleport_callback
	local cb_param = parameters.callback_param
	local tpsound = parameters.teleport_sound
	local pfx = parameters.particle_effects
	
	-- Find the player.
	local player = minetest.get_player_by_name(pname)
	if not player or not player:is_player() then
		-- The player left, or something. Do not teleport them.
		minetest.log("action", pname .. " left the game while a teleport callback was in progress")
		return
	end

	-- The player may optionally be force-teleported.
	if not force then
		-- Did the player move?
		if vector_distance(pp, player:get_pos()) > 1.5 then
			minetest.chat_send_player(pname, "# Server: Transport error. You cannot move while a transport is in progress.")
			return
		end

		-- If the player killed themselves, do not teleport them.
		if player:get_hp() == 0 then
			minetest.chat_send_player(pname, "# Server: Transport error. You are dead.")
			return
		end
	end

	-- But we must never teleport a player who is attached.
	if default.player_attached[pname] then
		minetest.chat_send_player(pname, "# Server: Transport error. Player attached!")
		return
	end

	-- Execute the callback function, if everything else succeeded.
	if pre_cb then
		-- If the pre-teleport callback returns 'success' then that
		-- signals that the teleport must be aborted for some reason.
		if pre_cb(cb_param) then
			minetest.chat_send_player(pname, "# Server: Transport canceled.")
			return
		end
	end

	minetest.log("action", "executing teleport callback for " .. pname .. "!")

	-- Teleport player only if they didn't move (or teleporting is forced).
	wield3d.on_teleport()
	rc.notify_realm_update(player, tp)
	player:set_pos(tp)
	minetest.log("action", pname .. " actually teleports to " .. minetest.pos_to_string(tp))

	-- Execute the callback function, if everything else succeeded.
	if post_cb then
		post_cb(cb_param)
	end

	local thesound = "teleport"
	if type(tpsound) == "string" then
		thesound = tpsound
	end

	-- The teleport sound, played @ old & new locations.
	ambiance.sound_play(thesound, pp, 1.0, 50)
	ambiance.sound_play(thesound, tp, 1.0, 50)

	if pfx then
		preload_tp.spawn_particles(pp)
		preload_tp.spawn_particles(tp)
		preload_tp.spawn_spinup_particles(vector_round(tp), 3)
	end
end



function preload_tp.wait_for_timeout(parameters)
	local start_time = parameters.start_time
	local total_time = parameters.total_time

	local end_time = os.time()
	if (end_time - start_time) < total_time then
		minetest.after(1, function()
			preload_tp.wait_for_timeout(parameters)
		end)
		return
	end

	preload_tp.finalize(parameters)
end



function preload_tp.spawn_spinup_particles(pos, time)
	local xd = 1
	local zd = 1

	-- We used to use the coal & mese textures (ew).
	-- Now that we have better particles, we don't need multiple spawners.
	-- Can animate the particles, too.
	minetest.add_particlespawner({
		amount = 160,
		time = time,
		minpos = {x=pos.x-xd, y=pos.y-0, z=pos.z-zd},
		maxpos = {x=pos.x+xd, y=pos.y+2, z=pos.z+zd},
		minvel = {x=0, y=-1, z=0},
		maxvel = {x=0, y=1, z=0},
		minacc = {x=0, y=-1, z=0},
		maxacc = {x=0, y=1, z=0},
		minexptime = 1.0,
		maxexptime = 2.5,
		minsize = 1.0,
		maxsize = 1.0,
		collisiondetection = true,
		collision_removal = true,
		vertical = false,

		texture = "nether_particle_anim1.png",

		animation = {
			type = "vertical_frames",
			aspect_w = 7,
			aspect_h = 7,

			-- Disabled for now due to causing older clients to hang.
			--length = -1,
			length = 0.3,
		},

		glow = 14,
	})
end



-- API function. Preload the area, then teleport the player there
-- only if they have not moved during the preload. After a successful
-- teleport, execute the callback function if it's not nil.
function preload_tp.execute(parameters)
	-- Copy table so we don't end up modifying the original.
	parameters = table.copy(parameters)

	-- Set default parameters.
	parameters.player_name = parameters.player_name or ""
	parameters.target_position = parameters.target_position or {x=0, y=0, z=0}
	parameters.emerge_radius = parameters.emerge_radius or 16
	parameters.pre_teleport_callback = parameters.pre_teleport_callback or nil
	parameters.post_teleport_callback = parameters.post_teleport_callback or nil
	parameters.callback_param = parameters.callback_param or nil
	parameters.force_teleport = parameters.force_teleport or false
	parameters.teleport_sound = parameters.teleport_sound or nil
	parameters.send_blocks = parameters.send_blocks or false
	parameters.particle_effects = parameters.particle_effects or false

	local pname = parameters.player_name
	local tpos = parameters.target_position
	local radius = parameters.emerge_radius
	local pre_cb = parameters.pre_teleport_callback
	local post_cb = parameters.post_teleport_callback
	local cb_param = parameters.callback_param
	local force = parameters.force_teleport
	local tpsound = parameters.teleport_sound
	local sendblocks = parameters.send_blocks
	local pfx = parameters.particle_effects

	local player = minetest.get_player_by_name(pname)
	if not player or not player:is_player() then
		return
	end

	local tp = table.copy(tpos)
	local pp = player:get_pos()
	local start_time = os.time()

	-- Time to teleport depends on distance.
	-- But allow calling code to override this for special cases.
	local total_time = math_floor(vector_distance(pp, tp) / 1000)
	if parameters.spinup_time then
		total_time = parameters.spinup_time
	end
	if total_time < 2 then
		total_time = 2
	end

	parameters.start_position = pp
	parameters.start_time = start_time
	parameters.total_time = total_time

	minetest.log("action", pname .. " initiates teleport to " .. minetest.pos_to_string(tp))

	if pfx then
		preload_tp.spawn_spinup_particles(vector_round(pp), total_time + 2)
		preload_tp.spawn_spinup_particles(vector_round(tp), total_time + 1)
	end

	-- Build callback function. When the map is loaded, we can teleport the player.
	local cb = function(blockpos, action, calls_remaining, parameters)
		-- Check if there was an error.
		-- This avoids false error reports if the area to be generated exceeds the max map edge.
		-- Update: actually it doesn't?
		if action == core.EMERGE_CANCELLED or action == core.EMERGE_ERRORED then
			minetest.chat_send_player(pname, "# Server: Internal error, try again or report.")
			return
		end

		-- Send blocks to client as soon as they're available; looks better that way.
		if sendblocks then
			if blockpos then
				local pref = minetest.get_player_by_name(pname)
				if pref then
					pref:send_mapblock(blockpos)
				end
			end
		end

		-- We don't do anything until the last callback.
		if calls_remaining ~= 0 then
			return
		end

		if not force then
			preload_tp.wait_for_timeout(parameters)
			return
		end

		-- Forced teleport always teleports as soon as possible!
		preload_tp.finalize(parameters)
	end

	local minp = vector.add(tp, vector.new(-radius, -radius, -radius))
	local maxp = vector.add(tp, vector.new(radius, radius, radius))

	-- Emerge the target area. Once emergence is complete player can be teleported.
	minetest.chat_send_player(pname, "# Server: Spatially translating! Stand by.")
	minetest.emerge_area(minp, maxp, cb, parameters)
end



local particles = {
	amount = 20,
	time = 1,
--  ^ If time is 0 has infinite lifespan and spawns the amount on a per-second base
	minpos = {x=0, y=0, z=0},
	maxpos = {x=0, y=0, z=0},
	minvel = {x=0, y=6, z=0},
	maxvel = {x=0, y=9, z=0},
	minacc = {x=0, y=2, z=0},
	maxacc = {x=0, y=4, z=0},
	minexptime = 0.5,
	maxexptime = 1,
	minsize = 1.0,
	maxsize = 1.0,
--  ^ The particle's properties are random values in between the bounds:
--  ^ minpos/maxpos, minvel/maxvel (velocity), minacc/maxacc (acceleration),
--  ^ minsize/maxsize, minexptime/maxexptime (expirationtime)
	collisiondetection = false,
--  ^ collisiondetection: if true uses collision detection
	collision_removal = false,
--  ^ collision_removal: if true then particle is removed when it collides,
--  ^ requires collisiondetection = true to have any effect
	--attached = ObjectRef,
--  ^ attached: if defined, particle positions, velocities and accelerations
--  ^ are relative to this object's position and yaw.
	vertical = false,
--  ^ vertical: if true faces player using y axis only

	texture = "nether_particle_anim1.png",
	animation = {
		type = "vertical_frames",
		aspect_w = 7,
		aspect_h = 7,

		-- Disabled for now due to causing older clients to hang.
		--length = -1,
		length = 0.3,
	},
	glow = 14,
}

function preload_tp.spawn_particles(pos)
	particles.minpos = vector.add(pos, {x=-1.0, y=-1.0, z=-1.0})
	particles.maxpos = vector.add(pos, {x=1.0, y=-1.0, z=1.0})
	minetest.add_particlespawner(particles)
end



if not preload_tp.run_once then
	local c = "preload_tp:core"
	local f = preload_tp.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	preload_tp.run_once = true
end
