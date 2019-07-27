
portal_sickness = portal_sickness or {}
portal_sickness.players = portal_sickness.players or {}

-- Localize.
local players = portal_sickness.players

function portal_sickness.init_if_needed(pname)
	if not players[pname] then
		players[pname] = {
			count = 0,
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

	players[pname].count = players[pname].count + 1
end

function portal_sickness.on_use_bed(pname)
	portal_sickness.init_if_needed(pname)

	players[pname].count = 0
end

function portal_sickness.on_leave_player(pname)
	players[pname] = nil
end

if not portal_sickness.registered then
	minetest.register_on_leaveplayer(function(player)
		portal_sickness.on_leave_player(player:get_player_name())
	end)

	portal_sickness.registered = true
end
