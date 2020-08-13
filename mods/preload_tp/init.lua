
preload_tp = preload_tp or {}
preload_tp.modpath = minetest.get_modpath("preload_tp")



function preload_tp.finalize(pname, action, force, pp, tp, pre_cb, post_cb, cb_param, tpsound)
	-- Check if there was an error on the LAST call.
	-- This avoids false error reports if the area to be generated exceeds the max map edge.
	-- Update: actually it doesn't?
	if action == core.EMERGE_CANCELLED or action == core.EMERGE_ERRORED then
		minetest.chat_send_player(pname, "# Server: Internal error, try again or report.")
		return
	end

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
		if vector.distance(pp, player:get_pos()) > 1.5 then
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
	preload_tp.spawn_particles(pp)

	ambiance.sound_play(thesound, tp, 1.0, 50)
	preload_tp.spawn_particles(tp)

	preload_tp.spawn_spinup_particles(vector.round(tp), 3)
end



function preload_tp.wait_for_timeout(start_time, total_time, pname, action, force, pp, tp, pre_cb, post_cb, cb_param, tpsound)
	local end_time = os.time()
	if (end_time - start_time) < total_time then
		minetest.after(1, function()
			preload_tp.wait_for_timeout(start_time, total_time, pname, action, force, pp, tp, pre_cb, post_cb, cb_param, tpsound)
		end)
		return
	end

	preload_tp.finalize(pname, action, force, pp, tp, pre_cb, post_cb, cb_param, tpsound)
end



function preload_tp.spawn_spinup_particles(pos, time)
	local xd = 1
	local zd = 1

	minetest.add_particlespawner({
		amount = 160,
		time = time,
		minpos = {x=pos.x-xd, y=pos.y-0, z=pos.z-zd},
		maxpos = {x=pos.x+xd, y=pos.y+2, z=pos.z+zd},
		minvel = {x=0, y=-1, z=0},
		maxvel = {x=0, y=1, z=0},
		minacc = {x=0, y=-1, z=0},
		maxacc = {x=0, y=1, z=0},
		minexptime = 0.5,
		maxexptime = 1.5,
		minsize = 0.5,
		maxsize = 2,
		collisiondetection = false,
		vertical = true,
		texture = "default_coal_lump.png",
		glow = 14,
	})
	minetest.add_particlespawner({
		amount = 160,
		time = time,
		minpos = {x=pos.x-xd, y=pos.y-0, z=pos.z-zd},
		maxpos = {x=pos.x+xd, y=pos.y+2, z=pos.z+zd},
		minvel = {x=-1, y=-1, z=-1},
		maxvel = {x=1, y=1, z=1},
		minacc = {x=-1, y=-1, z=-1},
		maxacc = {x=1, y=1, z=1},
		minexptime = 0.5,
		maxexptime = 1.5,
		minsize = 0.5,
		maxsize = 2,
		collisiondetection = false,
		texture = "default_mese_crystal.png",
		glow = 14,
	})
end



-- API function. Preload the area, then teleport the player there
-- only if they have not moved during the preload. After a successful
-- teleport, execute the callback function if it's not nil.
function preload_tp.preload_and_teleport(pname, tpos, radius, pre_cb, post_cb, cb_param, force, tpsound)
	local player = minetest.get_player_by_name(pname)
	if not player or not player:is_player() then
		return
	end

	-- We need to copy the position table to avoid it being modified on us.
	local tp = table.copy(tpos)
	local pp = player:get_pos()
	local start_time = os.time()

	-- Time to teleport depends on distance.
	local total_time = math.floor(vector.distance(pp, tp) / 1000)
	if total_time < 2 then
		total_time = 2
	end

	minetest.log("action", pname .. " initiates teleport to " .. minetest.pos_to_string(tp))

	preload_tp.spawn_spinup_particles(vector.round(pp), total_time + 2)
	preload_tp.spawn_spinup_particles(vector.round(tp), total_time + 1)

	-- Build callback function. When the map is loaded, we can teleport the player.
	local tbparam = {}
	local cb = function(blockpos, action, calls_remaining, param)
		-- We don't do anything until the last callback.
		if calls_remaining ~= 0 then
			return
		end

		if not force then
			preload_tp.wait_for_timeout(start_time, total_time, pname, action, force, pp, tp, pre_cb, post_cb, cb_param, tpsound)
			return
		end

		-- Forced teleport always teleports as soon as possible!
		preload_tp.finalize(pname, action, force, pp, tp, pre_cb, post_cb, cb_param, tpsound)
	end

	local minp = vector.add(tp, vector.new(-radius, -radius, -radius))
	local maxp = vector.add(tp, vector.new(radius, radius, radius))

	-- Emerge the target area. Once emergence is complete player can be teleported.
	minetest.chat_send_player(pname, "# Server: Spatially translating! Stand by.")
	minetest.emerge_area(minp, maxp, cb, tbparam)
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
	minsize = 0.2,
	maxsize = 0.8,
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
	texture = "teleports_teleport_top.png",
--  ^ Uses texture (string)
	--playername = "singleplayer"
--  ^ Playername is optional, if specified spawns particle only on the player's client
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
