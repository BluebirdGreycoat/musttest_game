
portal_sickness = portal_sickness or {}
portal_sickness.players = portal_sickness.players or {}

-- Localize.
local players = portal_sickness.players
local alert_color = core.get_color_escape_sequence("#ff0000")

local function portal_sicken(pname)
	local msg = "# Server: <" .. rename.gpn(pname) .. "> succumbed to PORTAL SICKNESS."
	hb4.delayed_harm({name=pname, step=30, min=1, max=3, msg=msg, poison=true})
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

function portal_sickness.init_if_needed(pname)
	if not players[pname] then
		players[pname] = {
			count = 0,
			sick = false,
		}
	end
end

function portal_sickness.on_use_portal(pname)
	local player = minetest.get_player_by_name(pname)
	if not player or not player:is_player() then
		return
	end

	sprint.set_stamina(player, 0)

	portal_sickness.init_if_needed(pname)

	if players[pname].sick then
		portal_sicken(pname)
		players[pname].sick = false
		return
	end

	players[pname].count = players[pname].count + 1
	local max = 10 - players[pname].count
	if max < 1 then
		max = 1
	end

	if (math.random(1, max) == 1) then
		minetest.chat_send_player(pname, alert_color .. "# Server: WARNING: You have contracted PORTAL SICKNESS! You must sleep it off to be cured.")
		players[pname].sick = true
		sicken_sound(pname)
	end
end

function portal_sickness.on_use_bed(pname)
	portal_sickness.init_if_needed(pname)

	players[pname].count = 0
	players[pname].sick = false

	minetest.chat_send_player(pname, "# Server: You no longer have portal sickness.")
end

function portal_sickness.check_sick(pname)
	minetest.after(2, function()
		local player = minetest.get_player_by_name(pname)
		if not player or not player:is_player() then
			return
		end

		portal_sickness.init_if_needed(pname)
		if players[pname].sick then
			minetest.chat_send_player(pname, alert_color .. "# Server: WARNING: You still have PORTAL SICKNESS!")
		end
	end)
end

function portal_sickness.on_join_player(pname)
	portal_sickness.check_sick(pname)
end

function portal_sickness.on_leave_player(pname)
	portal_sickness.init_if_needed(pname)

	-- Only erase data if player is not sick.
	-- Once player gets sick, relogging doesn't remove the sickness!
	if not players[pname].sick then
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
