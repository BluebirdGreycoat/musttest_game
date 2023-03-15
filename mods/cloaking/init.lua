
-- Cloaking system for players.
-- Note: admin has special invisibility system in gdac_invis directory.
cloaking = cloaking or {}
cloaking.modpath = minetest.get_modpath("cloaking")
cloaking.players = cloaking.players or {}

-- Localize for speed.
local math_random = math.random
local vector_round = vector.round
local vector_add = vector.add

function cloaking.spawn_wisp(pos)
	local minp = vector_add(pos, -5)
	local maxp = vector_add(pos, 5)

	local positions = minetest.find_nodes_in_area(minp, maxp, "air")

	if #positions > 0 then
		local p = positions[math_random(1, #positions)]
		pm.spawn_random_wisp(p)
	end
end

function cloaking.particle_effect(pos)
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
	minetest.add_particlespawner(particles)
end

function cloaking.hud_effect(pname)
	local pref = minetest.get_player_by_name(pname)
	if pref then
		if cloaking.is_cloaked(pname) then
			--minetest.chat_send_all('testing')

			local color = "white"

			local pdata = cloaking.players[pname]
			if (pdata.decloak_timer or 0) > 0 then
				color = "red"
			end

			local pos = pref:get_pos()
			local r = 10
			local particles = {
				amount = 300,
				time = 1.1,
				--minpos = vector.add(pos, {x=-0.1, y=-0.1, z=-0.1}),
				--maxpos = vector.add(pos, {x=0.1, y=0.1, z=0.1}),
				minpos = {x=-r, y=-r/2, z=-r},
				maxpos = {x=r, y=r/2, z=r},
				minvel = vector.new(0, -1.5, 0),
				maxvel = vector.new(0, 1.5, 0),
				minacc = {x=0, y=0, z=0},
				maxacc = {x=0, y=0, z=0},
				minexptime = 1.5,
				maxexptime = 2.0,
				minsize = 1.0,
				maxsize = 1.0,
				collisiondetection = false,
				collision_removal = false,
				vertical = false,

				texture = "nether_particle_anim3.png" ..
					"^[colorize:" .. color .. ":alpha",

				animation = {
					type = "vertical_frames",
					aspect_w = 7,
					aspect_h = 7,

					-- Disabled for now due to causing older clients to hang.
					--length = -1,
					length = 1,
				},

				glow = 14,
				attached = pref,
				playername = pname,
			}
			-- Cannot use the overriden version of minetest.add_particlespawner()
			-- because sending multiple attached particle-spawners to different players
			-- is broken.
			utility.original_add_particlespawner(particles)

			minetest.after(1, cloaking.hud_effect, pname)
		end
	end
end

function cloaking.do_scan(pname)
	-- If player is cloaked, check for reasons to disable the cloak.
	if cloaking.players[pname] then
		local pref = minetest.get_player_by_name(pname)
		if pref then
			local pos = pref:get_pos()

			local player_count = 0
			local mob_count = 0

			-- If there are nearby entities, disable the cloak.
			local objs = minetest.get_objects_inside_radius(pos, 5)
			for i = 1, #objs, 1 do
				if objs[i]:is_player() and objs[i]:get_hp() > 0 then
					if not gdac.player_is_admin(objs[i]) then
						player_count = player_count + 1
					end
				else
					local ent = objs[i]:get_luaentity()
					if ent and ent.mob then
						mob_count = mob_count + 1
					end
				end
			end

			-- There will always be at least one player (themselves).
			if player_count > 1 or mob_count > 0 then
				local pdata = cloaking.players[pname]
				pdata.decloak_timer = (pdata.decloak_timer or 0) + 1
				if pdata.decloak_timer > 7 then
					cloaking.toggle_cloak(pname)
				end
			else
				local pdata = cloaking.players[pname]
				pdata.decloak_timer = 0
			end

			-- Randomly sometimes spawn wisps.
			if math_random(1, 1000) == 1 then
				cloaking.spawn_wisp(vector_round(pos))
			end
		end
	end

	-- If cloak still enabled for this player, then check again in 1 second.
	if cloaking.players[pname] then
		minetest.after(1, cloaking.do_scan, pname)
	end
end

function cloaking.is_cloaked(pname)
	if cloaking.players[pname] then
		return true
	end
	return false
end

function cloaking.toggle_cloak(pname)
  local player = minetest.get_player_by_name(pname)
  if not player or not player:is_player() then
		return
	end

	if gdac_invis.is_invisible(pname) then
		minetest.chat_send_player(pname, "# Server: You are using the admin invisibility system! Invisibility mode will be disabled, first.")
		minetest.chat_send_player(pname, "# Server: The delay involved in switching invisibility systems may allow you to be briefly seen.")
		gdac_invis.toggle_invisibility(pname, "")
	end

	if not cloaking.players[pname] then
		-- Enable cloak.
		cloaking.players[pname] = {}
		player_labels.disable_nametag(pname)

		-- Notify so health gauges can be removed.
		gauges.on_teleport()

		player:set_properties({
			visual_size = {x=0, y=0},
			is_visible = false,
			pointable = false,
			show_on_minimap = false,
		})

		cloaking.particle_effect(utility.get_middle_pos(player:get_pos()))
		minetest.chat_send_player(pname, "# Server: Cloak activated.")

		-- Enable scanning for reasons to cancel the cloak.
		minetest.after(1, cloaking.do_scan, pname)
		minetest.after(1, cloaking.hud_effect, pname)
	else
		-- Disable cloak.
		cloaking.players[pname] = nil
		player_labels.enable_nametag(pname)

		-- Restore player properties.
		player:set_properties({
			visual_size = {x=1, y=1},
			is_visible = true,
			pointable = true,
			show_on_minimap = true,
		})

		cloaking.particle_effect(utility.get_middle_pos(player:get_pos()))
		minetest.chat_send_player(pname, "# Server: Cloak offline.")
	end
end

-- Disable cloak if player dies.
function cloaking.on_dieplayer(player, reason)
	local pname = player:get_player_name()
	if cloaking.is_cloaked(pname) then
		-- Ensure cloak is disabled *after* player is dead (and bones spawned), not before!
		minetest.after(0, cloaking.toggle_cloak, pname)
	end
end

-- Cleanup player info on leave game.
function cloaking.on_leaveplayer(player, timeout)
	local pname = player:get_player_name()
	cloaking.players[pname] = nil
end

if not cloaking.registered then
	minetest.register_on_dieplayer(function(...)
		cloaking.on_dieplayer(...)
	end)

	minetest.register_on_leaveplayer(function(...)
		cloaking.on_leaveplayer(...)
	end)

	local c = "cloaking:core"
	local f = cloaking.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	cloaking.registered = true
end
