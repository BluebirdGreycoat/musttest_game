
portal_sickness = portal_sickness or {}
portal_sickness.players = portal_sickness.players or {}
portal_sickness.version = portal_sickness.version or 1

-- Localize.
local players = portal_sickness.players
local alert_color = core.get_color_escape_sequence("#ff0000")

local function portal_sicken(pname, count)
	if count < 1 then
		count = 1
	end

	-- Length of sickness increases based on how many times player has teleported
	-- since the last sickness.
	local step = count * 10

	local msg = "# Server: <" .. rename.gpn(pname) .. "> succumbed to PORTAL SICKNESS."
	hb4.delayed_harm({name=pname, step=step, min=1, max=3, msg=msg, poison=true})

	minetest.chat_send_all("# Server: <" .. rename.gpn(pname) .. "> has contracted portal sickness!")
end

local function sicken_sound(pname)
	minetest.after(1, function()
		local player = minetest.get_player_by_name(pname)
		if not player or not player:is_player() then
			return
		end
		ambiance.sound_play("hungry_games_death", player:get_pos(), 1.0, 30)
	end)
end

function portal_sickness.reset(pname)
	portal_sickness.init_if_needed(pname)
	players[pname].sick = 0
	players[pname].count = 0
	players[pname].time = os.time()
end

function portal_sickness.init_if_needed(pname)
	if not players[pname] then
		players[pname] = {
			count = 0,
			sick = 0,
			time = os.time(),
			version = portal_sickness.version,
		}
	end

	-- If stored data has old version, then reset it.
	if players[pname] then
		if not players[pname].version or players[pname].version < portal_sickness.version then
			players[pname] = {
				count = 0,
				sick = 0,
				time = os.time(),
				version = portal_sickness.version,
			}
		end
	end
end

function portal_sickness.on_use_portal(pname)
	local player = minetest.get_player_by_name(pname)
	if not player or not player:is_player() then
		return
	end

	sprint.set_stamina(player, 0)

	portal_sickness.init_if_needed(pname)

	local rand_time_add = (players[pname].count - 6) * 10
	local t1 = players[pname].time
	local t2 = os.time()
	local mt = math.random(30, math.random(40, 140 + rand_time_add))
	local max_time = math.random(60*10, 60*20)

	-- If player waits long enough, they don't sicken, but neither does the
	-- sickness go away!
	if (t2 - t1) < max_time then
		if players[pname].sick >= 2 then
			portal_sicken(pname, players[pname].count)

			-- Reset!
			players[pname].sick = 0
			players[pname].count = 0
			players[pname].time = t2
			return
		end
	end

	if (t2 - t1) < mt then
		players[pname].count = players[pname].count + 1
		local max = 8 - players[pname].count
		if max < 1 then
			max = 1
		end
		--minetest.chat_send_player("MustTest", "# Server: sickness probability: 1 in " .. max .. ".")

		if (math.random(1, max) == 1) or players[pname].sick == 1 then
			if players[pname].sick == 0 then
				minetest.chat_send_player(pname, alert_color .. "# Server: WARNING: You are feeling queasy!")
				players[pname].sick = 1
			elseif players[pname].sick == 1 then
				minetest.chat_send_player(pname, alert_color .. "# Server: WARNING: You have contracted PORTAL SICKNESS! You must sleep it off to be cured.")
				players[pname].sick = 2
				sicken_sound(pname)
			end
		end
	else
		portal_sickness.check_sick(pname)
	end

	-- Update time since last use of portal.
	players[pname].time = t2
end

function portal_sickness.on_use_bed(pname)
	portal_sickness.init_if_needed(pname)

	local was_ill = (players[pname].count > 0 or players[pname].sick > 0)

	players[pname].count = 0
	players[pname].sick = 0
	players[pname].time = os.time()

	if was_ill then
		minetest.after(2, function()
			minetest.chat_send_player(pname, "# Server: You feel refreshed. The queasiness from portal sickness has gone.")
		end)
	end
end

function portal_sickness.on_die_player(pname)
	portal_sickness.reset(pname)
end

function portal_sickness.check_sick(pname)
	minetest.after(2, function()
		local player = minetest.get_player_by_name(pname)
		if not player or not player:is_player() then
			return
		end

		portal_sickness.init_if_needed(pname)
		if players[pname].sick >= 2 then
			minetest.chat_send_player(pname, alert_color .. "# Server: WARNING: You still have PORTAL SICKNESS!")
		elseif players[pname].sick == 1 then
			minetest.chat_send_player(pname, alert_color .. "# Server: WARNING: You are still feeling queasy!")
		end
	end)
end

function portal_sickness.on_join_player(pname)
	portal_sickness.check_sick(pname)
end

function portal_sickness.on_leave_player(pname)
	portal_sickness.init_if_needed(pname)

	-- Only erase data if player is not sick or queasy.
	-- Once player gets sick, relogging doesn't remove the sickness!
	if players[pname].sick == 0 then
		players[pname] = nil
	end
end

if not portal_sickness.registered then
	minetest.register_on_joinplayer(function(player)
		portal_sickness.on_join_player(player:get_player_name())
	end)

	minetest.register_on_leaveplayer(function(player)
		portal_sickness.on_leave_player(player:get_player_name())
	end)

	portal_sickness.registered = true
end
