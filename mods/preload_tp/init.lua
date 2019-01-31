
preload_tp = preload_tp or {}
preload_tp.modpath = minetest.get_modpath("preload_tp")



-- API function. Preload the area, then teleport the player there
-- only if they have not moved during the preload. After a successful
-- teleport, execute the callback function if it's not nil.
function preload_tp.preload_and_teleport(pname, tpos, radius, pre_cb, post_cb, cb_param, force, tpsound)
	local player = minetest.get_player_by_name(pname)
	if not player then
		return
	end

	-- We need to copy the position table to avoid it being modified on us.
	local tp = table.copy(tpos)
	local pp = player:get_pos()

	-- Build callback function. When the map is loaded, we can teleport the player.
	local tbparam = {}
	local cb = function(blockpos, action, calls_remaining, param)
		-- We don't do anything until the last callback.
		if calls_remaining ~= 0 then
			return
		end

		-- Check if there was an error on the LAST call.
		-- This avoids false error reports if the area to be generated exceeds the max map edge.
		if action == core.EMERGE_CANCELLED or action == core.EMERGE_ERRORED then
			minetest.chat_send_player(pname, "# Server: Internal error, try again or report.")
			return
		end

		-- Find the player.
		local player = minetest.get_player_by_name(pname)
		if not player then
			-- The player left, or something. Do not teleport them.
			return
		end

		-- The player may optionally be force-teleported.
		if not force then
			-- Did the player move?
			if vector.distance(pp, player:get_pos()) > 0.1 then
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

		-- Teleport player only if they didn't move (or teleporting is forced).
		player:set_pos(tp)
		wield3d.on_teleport()
		rc.notify_realm_update(player, tp)

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
	end

	local minp = vector.add(tp, vector.new(-radius, -radius, -radius))
	local maxp = vector.add(tp, vector.new(radius, radius, radius))

	-- Emerge the target area. Once emergence is complete player can be teleported.
	minetest.chat_send_player(pname, "# Server: Loading target location. Please stand by.")
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
