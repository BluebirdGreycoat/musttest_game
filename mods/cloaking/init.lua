
-- Cloaking system for players.
-- Note: admin has special invisibility system in gdac_invis directory.
cloaking = cloaking or {}
cloaking.modpath = minetest.get_modpath("cloaking")
cloaking.players = cloaking.players or {}

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

	if not cloaking.players[pname] then
		-- Enable cloak.
		cloaking.players[pname] = true
		player_labels.disable_nametag(pname)

		-- Notify so health gauges can be removed.
		gauges.on_teleport()

		player:set_properties({
			visual_size = {x=0, y=0},
			is_visible = false,
		})

		minetest.chat_send_player(pname, "# Server: Cloak activated.")
	else
		-- Disable cloak.
		cloaking.players[pname] = nil
		player_labels.enable_nametag(pname)

		-- Restore player properties.
		player:set_properties({
			visual_size = {x=1, y=1},
			is_visible = true,
		})

		minetest.chat_send_player(pname, "# Server: Cloak offline.")
	end
end

-- Disable cloak if player dies.
function cloaking.on_dieplayer(player, reason)
	local pname = player:get_player_name()
	if cloaking.is_cloaked(pname) then
		cloaking.toggle_cloak(pname)
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
