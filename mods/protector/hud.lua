
protector = protector or {}
protector.hud = protector.hud or {}

-- Localize.
local hud = protector.hud
hud.players = {}

function protector.update_nearby_players(pos)
	local players = minetest.get_connected_players()
	for _, player in ipairs(players) do
		local p1 = player:get_pos()
		if vector.distance(pos, p1) <= 6 then
			local pname = player:get_player_name()
			hud.players[pname].moved = true -- Will trigger a HUD update.
		end
	end
end

local gs_timer = 0.0
local gs_timestep = 1.5

minetest.register_globalstep(function(dtime)
	gs_timer = gs_timer + dtime
	if gs_timer < gs_timestep then return end
	gs_timer = 0.0

	local allplayers = minetest.get_connected_players()
	for _, player in ipairs(allplayers) do
		local control = player:get_player_control()
		local pname = player:get_player_name()

		-- Is the player currently moving?
		local moving = (control.sneak or control.jump or control.left or control.right or control.up or control.down)
		local timer = hud.players[pname].timer

		-- Detect if the player moved through some other means.
		local pos = vector.round(player:get_pos())
		if not vector.equals(hud.players[pname].pos, pos) then
			moving = true
		end
		hud.players[pname].pos = pos
			
		local owner_str = hud.players[pname].owner

		-- Advance clock if player is not moving.
		if moving then
			timer = 0
			owner_str = "Pending"
			hud.players[pname].moved = true
		else
			if hud.players[pname].moved then
				timer = timer + gs_timestep
				owner_str = "Checking"
			end
		end

		if timer > 5 then
			-- Player position has already been obtained.
			local owner = protector.get_node_owner(pos)

			if owner and owner ~= "" then
				owner_str = "<" .. rename.gpn(owner) .. ">"
			else
				owner_str = "Nobody"
			end

			timer = 0
			hud.players[pname].moved = false
		end

		local hud_text = "Realm: " .. rc.pos_to_name(pos) .. "\nPos: " .. rc.pos_to_string(pos) .. "\nOwner: " .. owner_str

		if hud_text ~= hud.players[pname].text then
			if not hud.players[pname].id then
				hud.players[pname].id = player:hud_add({
					hud_elem_type = "text",
					name = "Protector Area",
					number = 0xFFFFFF, --0xFFFF22,
					position = {x=0, y=0.8},
					offset = {x=16, y=0},
					text = hud_text,
					alignment = {x=1, y=1},
				})
			else
				player:hud_change(hud.players[pname].id, "text", hud_text)
			end
			hud.players[pname].text = hud_text
			hud.players[pname].owner = owner_str
		end

		-- Store timer.
		hud.players[pname].timer = timer
	end
end)

minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()
	hud.players[pname] = {
		timer = 0,
		text = "", -- Keep track of last displayed text.
		owner = "",
		moved = true,
		pos = {x=0, y=0, z=0},
	}
end)

minetest.register_on_leaveplayer(function(player, timedout)
	local pname = player:get_player_name()
	hud.players[pname] = nil
end)


