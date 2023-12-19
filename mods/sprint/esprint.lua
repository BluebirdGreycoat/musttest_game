--[[
Sprint mod for Minetest by GunshipPenguin

To the extent possible under law, the author(s)
have dedicated all copyright and related and neighboring rights 
to this software to the public domain worldwide. This software is
distributed without any warranty. 
]]

sprint.players = sprint.players or {}
sprint.stamina_hud = sprint.stamina_hud or {}

-- Localize.
local players = sprint.players
local staminaHud = sprint.stamina_hud
local floor = math.floor
local math_random = math.random



function sprint.on_joinplayer(player)
	local playerName = player:get_player_name()

	players[playerName] = {
		sprinting = false,
		timeOut = 0, 
		stamina = 0,
		shouldSprint = false,
		bars = 0,
	}

	-- Background images.
	-- Add them first, since draw order is determined by ID.
	player:hud_add({
		hud_elem_type = "statbar",
		position = {x=0.5,y=1},
		size = {x=16, y=16},
		text = "sprint_stamina_icon_bg.png",
		number = SPRINT_HUD_ICONS,
		alignment = {x=0,y=1},
		offset = {x=-((16*23)/2), y=-87},
	})

	-- Main stat icons.
	players[playerName].hud = player:hud_add({
		hud_elem_type = "statbar",
		position = {x=0.5,y=1},
		size = {x=16, y=16},
		text = "sprint_stamina_icon.png",
		number = 0,
		alignment = {x=0,y=1},
		offset = {x=-((16*23)/2), y=-87},
	})

	sprint.set_stamina(player, 0)
end

function sprint.on_leaveplayer(player, timedout)
	local playerName = player:get_player_name()
	players[playerName] = nil
end

-- Public API function.
function sprint.set_stamina(player, sta)
	local pname = player:get_player_name()
	if players[pname] then
		if sta > SPRINT_STAMINA then sta = SPRINT_STAMINA end
		local hp_max = player:get_properties().hp_max
		local maxstamina = floor((player:get_hp() / hp_max) * SPRINT_STAMINA)
		if sta > maxstamina then
			sta = maxstamina
		end
		players[pname]["stamina"] = sta
		local numBars = floor((sta/SPRINT_STAMINA)*SPRINT_HUD_ICONS)
		player:hud_change(players[pname]["hud"], "number", numBars)
	end
end

-- Public API function.
function sprint.add_stamina(player, sta)
	local pname = player:get_player_name()
	if players[pname] then
		local stamina = players[pname]["stamina"]
		stamina = stamina + sta
		if stamina > SPRINT_STAMINA then stamina = SPRINT_STAMINA end
		if stamina < 0 then stamina = 0 end
		local hp_max = player:get_properties().hp_max
		local maxstamina = floor((player:get_hp() / hp_max) * SPRINT_STAMINA)
		if stamina > maxstamina then
			stamina = maxstamina
		end
		players[pname]["stamina"] = stamina
		local numBars = floor((stamina/SPRINT_STAMINA)*SPRINT_HUD_ICONS)
		player:hud_change(players[pname]["hud"], "number", numBars)
	end
end

function sprint.get_stamina(player)
	local pname = player:get_player_name()
	if players[pname] then
		local stamina = players[pname]["stamina"]
		return stamina
	end
	return 0
end

function sprint.on_respawnplayer(player)
	sprint.set_stamina(player, 0)
	return true
end



local hunger_timer = 0
local particle_timer = 0

function sprint.globalstep(dtime)
	local do_hunger = false
	local do_particle = false
	hunger_timer = hunger_timer + dtime
	particle_timer = particle_timer + dtime
	if hunger_timer > 5 then
		hunger_timer = 0
		do_hunger = true
	end
	if particle_timer > 0.5 then
		particle_timer = 0
		do_particle = true
	end

	--Loop through all connected players
	for playerName, playerInfo in pairs(players) do
		local player = minetest.get_player_by_name(playerName)
		if player ~= nil then
			--Check if the player should be sprinting
			local control = player:get_player_control()
			if control["aux1"] and control["up"] then
				players[playerName]["shouldSprint"] = true
			else
				players[playerName]["shouldSprint"] = false
			end
			
			--If the player is sprinting, create particles behind him/her 
			if do_particle and playerInfo["sprinting"] == true then
				if not gdac_invis.is_invisible(playerName) then
					local numParticles = math_random(1, 2)
					local playerPos = player:get_pos()
					local playerNode = minetest.get_node({x=playerPos["x"], y=playerPos["y"]-1, z=playerPos["z"]})
					if playerNode["name"] ~= "air" then
						for i=1, numParticles, 1 do
							minetest.add_particle({
								pos = {x=playerPos["x"]+math_random(-1,1)*math_random()/2,y=playerPos["y"]+0.1,z=playerPos["z"]+math_random(-1,1)*math_random()/2},
								velocity = {x=0, y=5, z=0},
								acceleration = {x=0, y=-13, z=0},
								expirationtime = math_random(),
								size = math_random()+0.5,
								collisiondetection = true,
								vertical = false,
								texture = "sprint_particle.png",
							})
						end
					end
				end
			end

			-- Player is sprinting?
			if do_hunger and playerInfo["sprinting"] == true then
				hunger.increase_hunger(player, 1)
				hunger.increase_exhaustion(player, 6)
			end

			-- Player moving in water? Increase hunger and exhaustion.
			if do_hunger and (control.jump or control.left or control.right or control.up or control.down) then
				local node_inside = sky.get_last_walked_nodeabove(playerName)
				local ndef = minetest.reg_ns_nodes[node_inside]
				if ndef and ndef.groups and ndef.groups.liquid then
					hunger.increase_hunger(player, 1)
					hunger.increase_exhaustion(player, 10)
				elseif control.jump then
					-- Player is probably climbing a ladder.
					hunger.increase_exhaustion(player, 7)
				end
			end

			--Adjust player states
			if players[playerName]["shouldSprint"] == true then --Stopped
				sprint.set_sprinting(playerName, true)
			elseif players[playerName]["shouldSprint"] == false then
				sprint.set_sprinting(playerName, false)
			end
			
			--Lower the player's stamina by dtime if he/she is sprinting and set his/her state to 0 if stamina is zero
			if playerInfo["sprinting"] == true then 
				playerInfo["stamina"] = playerInfo["stamina"] - (dtime * SPRINT_USE_RATE)
				if playerInfo["stamina"] <= 0 then
					playerInfo["stamina"] = 0
					sprint.set_sprinting(playerName, false)
				end
			
			--Increase player's stamina if he/she is not sprinting and his/her stamina is less than SPRINT_STAMINA
			elseif playerInfo["sprinting"] == false and playerInfo["stamina"] < SPRINT_STAMINA then
				if hunger.get_hunger(player) >= 10 then
					local mult = 0.4

					-- If moving, stamina comes back more slowly.
					if control.up or control.left or control.right or control.down then
						mult = 0.01
					end

					-- If player is not hungry, they get stamina quicker.
					if hunger.get_hunger(player) >= 30 then
						mult = mult + 0.5
					end

					-- If player is in good health, they regain stamina more quickly.
					local max_hp = player:get_properties().hp_max
					if player:get_hp() >= max_hp then
						mult = mult + 0.3
					elseif player:get_hp() >= (max_hp * 0.9) then
						mult = mult + 0.2
					end

					-- Cloaking device uses energy from YOU.
					-- Rate is equal to whatever your stamina-regain rate is.
					if cloaking.is_cloaked(playerName) then
						mult = 0
					end

					mult = mult * hunger.get_stamina_boost(playerName)

					playerInfo["stamina"] = playerInfo["stamina"] + (dtime * mult)
				end
			end

			-- Cap stamina at SPRINT_STAMINA
			if playerInfo["stamina"] > SPRINT_STAMINA then
				playerInfo["stamina"] = SPRINT_STAMINA
			end

			local hp_max = player:get_properties().hp_max
			local maxstamina = floor((player:get_hp() / hp_max) * SPRINT_STAMINA)
			if playerInfo["stamina"] > maxstamina then
				playerInfo["stamina"] = maxstamina
			end
			
			-- Update the players's hud sprint stamina bar
			local numBars = floor((playerInfo["stamina"]/SPRINT_STAMINA)*SPRINT_HUD_ICONS)

			-- Don't send hud update every frame.
			if numBars ~= playerInfo["bars"] then
				player:hud_change(playerInfo["hud"], "number", numBars)
				playerInfo["bars"] = numBars
				--minetest.chat_send_all("# Server: Updating HUD!")
			end
		end
	end
end



function sprint.set_sprinting(playerName, sprinting) --Sets the state of a player (0=stopped/moving, 1=sprinting)
	local player = minetest.get_player_by_name(playerName)
	
	-- Speed multiplier based on player's health relative to max.
	-- This is as good a place as any to run this computation.
	local hp = player:get_hp()
	local max_hp = player:get_properties().hp_max

	local hp_mult = 1
	if hp <= (max_hp * 0.2) then
		hp_mult = 0.8
	elseif hp <= (max_hp * 0.5) then
		hp_mult = 0.9
	elseif hp >= (max_hp * 0.95) then
		hp_mult = 1.1
	end

	if players[playerName] then
		players[playerName]["sprinting"] = sprinting

		if sprinting == true then
			pova.set_physics_modifier(player, {
				speed = SPRINT_SPEED * hp_mult,
				jump = SPRINT_JUMP * hp_mult,
			}, "sprinting")
		elseif sprinting == false then
			pova.set_physics_modifier(player, {
				speed = hp_mult,
				jump = hp_mult,
			}, "sprinting")
		end

		return true
	end

	return false
end

