
if not minetest.global_exists("protector") then protector = {} end
protector.hud = protector.hud or {}

-- Localize.
local hud = protector.hud
hud.players = hud.players or {}

-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round



function protector.update_nearby_players(pos)
	local players = minetest.get_connected_players()
	for _, player in ipairs(players) do
		local p1 = player:get_pos()
		if vector_distance(pos, p1) <= 6 then
			local pname = player:get_player_name()
			hud.players[pname].moved = true -- Will trigger a HUD update.
		end
	end
end



local function wielding_compass(player)
	local stack = player:get_wielded_item()
	if stack:get_name() == "default:compass" then
		return true
	end
end



local gs_timer = 0.0
local gs_timestep = 0.5

function hud.globalstep(dtime)
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
		local pos = vector_round(player:get_pos())
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

		if timer > 1 then
			-- Player position has already been obtained.
			-- Note: 'owner' will be nil if area is unprotected by an owner.
			local owner = protector.get_node_owner(pos)
			local cblock = city_block:nearest_named_region(pos, owner)

			local city = ""
			if cblock and cblock[1] and cblock[1].area_name then
				city = cblock[1].area_name .. " / "
			end

			if owner and owner ~= "" then
				owner_str = city .. "<" .. rename.gpn(owner) .. ">"
			else
				owner_str = "Nobody"
			end

			timer = 0
			hud.players[pname].moved = false
		end

		local has_key = passport.player_has_key(pname, player)
		local has_compass = wielding_compass(player)
		local in_fort = not fortress.can_teleport_at(pos)

		local coord_str = ""
		if has_key or has_compass then
			if in_fort then
				coord_str = "\nCoords: Indeterminate"
			else
				coord_str = "\nCoords: " .. rc.pos_to_string(pos):gsub(",", ", ")
			end
		end

		local hud_text = "Realm: " .. rc.pos_to_name(pos) ..
			coord_str ..
			"\nClaim: " .. owner_str

		if hud_text ~= hud.players[pname].text then
			if not hud.players[pname].id then
				hud.players[pname].id = player:hud_add({
					hud_elem_type = "text",
					name = "Protector Area",
					number = 0xFFFFFF, --0xFFFF22,
					position = {x=0, y=1},
					offset = {x=16, y=-130},
					text = hud_text,
					alignment = {x=1, y=1},
				})
			else
				player:hud_change(hud.players[pname].id, "text", hud_text)
			end
			hud.players[pname].text = hud_text
			hud.players[pname].owner = owner_str
		end

		local dir_text = ""
		if has_key or has_compass then
			local yaw = (player:get_look_horizontal() * 180.0) / math.pi

			local div = 360 / 8
			local dir = "N/A"
			yaw = yaw + (360 / 16)
			if yaw > 360 then
				yaw = yaw - 360
			end
			if yaw < div*1 then
				dir = "N [+Z]"
			elseif yaw < div*2 then
				dir = "NW [-X +Z]"
			elseif yaw < div*3 then
				dir = "W [-X]"
			elseif yaw < div*4 then
				dir = "SW [-X -Z]"
			elseif yaw < div*5 then
				dir = "S [-Z]"
			elseif yaw < div*6 then
				dir = "SE [+X -Z]"
			elseif yaw < div*7 then
				dir = "E [+X]"
			elseif yaw < div*8 then
				dir = "NE [+X +Z]"
			elseif yaw < div*9 then
				dir = "N [+Z]"
			end

			if in_fort then
				dir_text = "Facing: ???"
			else
				dir_text = "Facing: " .. dir
			end
		end

		if dir_text ~= hud.players[pname].dir then
			if not hud.players[pname].id2 then
				hud.players[pname].id2 = player:hud_add({
					hud_elem_type = "text",
					number = 0xFFFFFF,
					position = {x=1, y=1},
					offset = {x=-16, y=-130 + 18*2},
					text = dir_text,
					alignment = {x=-1, y=1},
				})
			else
				player:hud_change(hud.players[pname].id2, "text", dir_text)
			end
			hud.players[pname].dir = dir_text
		end

		-- Store timer.
		hud.players[pname].timer = timer
	end
end



function hud.joinplayer(player)
	local pname = player:get_player_name()
	hud.players[pname] = {
		timer = 0,
		text = "", -- Keep track of last displayed text.
		owner = "",
		dir = "",
		moved = true,
		pos = {x=0, y=0, z=0},
	}
end



function hud.leaveplayer(player, timedout)
	local pname = player:get_player_name()
	hud.players[pname] = nil
end



if not hud.registered then
	minetest.register_globalstep(function(...) return hud.globalstep(...) end)
	minetest.register_on_joinplayer(function(...) return hud.joinplayer(...) end)
	minetest.register_on_leaveplayer(function(...) return hud.leaveplayer(...) end)

	local c = "protector:hud"
	local f = protector.modpath .. "/hud.lua"
	reload.register_file(c, f, false)

	hud.registered = true
end
