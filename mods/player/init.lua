
-- Minetest 0.4 mod: player
-- See README.txt for licensing and other information.
if not minetest.global_exists("player") then player = {} end
player.modpath = minetest.get_modpath("player")

-- Player animation blending
-- Note: This is currently broken due to a bug in Irrlicht, leave at 0
local animation_blend = 0

player.registered_player_models = { }

-- Local for speed.
local models = player.registered_player_models



function default.player_register_model(name, def)
	models[name] = def
end



-- Player stats and animations
local player_model = {}
local player_textures = {}
local player_anim = {}
local player_sneak = {}
local player_velocity = {}
default.player_attached = {}



function default.player_get_animation(player)
	local name = player:get_player_name()
	return {
		model = player_model[name],
		textures = player_textures[name],
		animation = player_anim[name],
	}
end



-- Called when a player's appearance needs to be updated
function default.player_set_model(player, model_name)
	local name = player:get_player_name()
	local model = models[model_name]

	if player_model[name] == model_name then
		return
	end

	pova.set_override(player, "properties", {
		mesh = model_name,
		textures = player_textures[name] or model.textures,
		visual = "mesh",
		visual_size = model.visual_size or {x=1, y=1, z=1},
	})

	default.player_set_animation(player, "stand")
	player_model[name] = model_name
end



function default.player_set_textures(player, textures)
	local name = player:get_player_name()
	player_textures[name] = textures
	pova.set_override(player, "properties", {textures = textures})
end



function default.player_set_animation(player, anim_name, speed)
	local name = player:get_player_name()
	if player_anim[name] == anim_name then
		return
	end
	local model = player_model[name] and models[player_model[name]]
	if not (model and model.animations[anim_name]) then
		return
	end
	local anim = model.animations[anim_name]
	player_anim[name] = anim_name
	player:set_animation(anim, speed or model.animation_speed, animation_blend)
end



-- Update appearance when the player joins
minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()
	default.player_attached[pname] = false

	player:set_local_animation({x=0, y=79}, {x=168, y=187}, {x=189, y=198}, {x=200, y=219}, 30)

	-- Big hot-bar is revoked for cheaters.
  if minetest.check_player_privs(player, {big_hotbar=true}) and not sheriff.is_cheater(pname) then
    player:hud_set_hotbar_image("gui_hotbar2.png")
    player:hud_set_hotbar_itemcount(16)
  else
    player:hud_set_hotbar_image("gui_hotbar.png")
    player:hud_set_hotbar_itemcount(8)
  end
  
	player:hud_set_hotbar_selected_image("hud_hotbar_selected.png")

	-- Update player velocity if available.
	if player_velocity[pname] then
		player:add_velocity(player_velocity[pname])
		player_velocity[pname] = nil
	end
end)



minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	player_model[name] = nil
	player_anim[name] = nil
	player_textures[name] = nil

	-- Save player velocity. If they login again, I will be able to restore it.
	player_velocity[name] = player:get_velocity()
end)



-- Localize for better performance.
local player_set_animation = default.player_set_animation
local player_attached = default.player_attached

-- Check each player and apply animations
minetest.register_globalstep(function(dtime)
	for _, player in pairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local model_name = player_model[pname]
		local model = model_name and models[model_name]
		if model and not player_attached[pname] then
			local controls = player:get_player_control()
			local walking = false
			local animation_speed_mod = model.animation_speed or 30

			-- Determine if the player is walking
			if controls.up or controls.down or controls.left or controls.right then
				walking = true
			end

			-- Determine if the player is sneaking, and reduce animation speed if so
			if controls.sneak then
				animation_speed_mod = animation_speed_mod / 2

				pova.set_modifier(player, "properties",
					{makes_footstep_sound = false}, "footstep_sneaking")
			else
				pova.remove_modifier(player, "properties", "footstep_sneaking")
			end

			-- Apply animations based on what the player is doing
			if player:get_hp() == 0 then
				player_set_animation(player, "lay")
			elseif walking then
				if player_sneak[pname] ~= controls.sneak then
					player_anim[pname] = nil
					player_sneak[pname] = controls.sneak
				end
				if controls.LMB then
					player_set_animation(player, "walk_mine", animation_speed_mod)
				else
					player_set_animation(player, "walk", animation_speed_mod)
				end
			elseif controls.LMB then
				player_set_animation(player, "mine")
			else
				player_set_animation(player, "stand", animation_speed_mod)
			end
		end
	end
end)



-- Each player gets assigned a unique random seed. Once set, this seed number
-- shall never change.
local function set_prng(pref)
	local pmeta = pref:get_meta()
	local s = "random_seed"
	local rand = pmeta:get_int(s)

	-- I would have liked to use SecureRandom() but I don't feel like doing the
	-- skunkwork to convert a byte string into a random seed. I've done it before,
	-- in C++. It wasn't fun.
	if rand == 0 then
		pmeta:set_int(s, math.random(1000, 10000))
	end
end



-- Disable the "sneak glitch" for all players.
-- Note: 'sneak=false' interferes with footstep sounds when walking on snow.
minetest.register_on_joinplayer(function(player)
	set_prng(player)

	pova.set_override(player, "properties", {
		infotext = rename.gpn(player:get_player_name()),
	})
	pova.set_override(player, "nametag", {
		color = {a=255, r=0, g=255, b=255},
		text = rename.gpn(player:get_player_name()),
		bgcolor = false,
	})

	local pmeta = player:get_meta()
	local random_seed = pmeta:get_int("random_seed")
	local prng = PseudoRandom(random_seed)

	-- The max diff in either direction should be 0.1, otherwise players will
	-- be too oversized or undersized.
	local nsize = 1+(prng:next(-10, 10)/100)

	-- Adjust base speed. Max range diff is 0.05 either direction.
	local nspeed = 1+(prng:next(-10, 10)/200)

	-- Adjust base jump. Max range diff is 0.05 either direction.
	local njump = 1+(prng:next(-10, 10)/100)

	pova.set_modifier(player, "properties",
		{visual_size={x=nsize, y=nsize}},
	"notbornequal", {priority=-999})

	pova.set_modifier(player, "physics",
		{speed=nspeed, jump=njump},
	"notbornequal", {priority=-999})

	-- Disable the minimap. Cheaters will of course be able to enable it.
	-- Can be reenabled via item in-game.
	player:hud_set_flags({
		minimap = false,
		minimap_radar = false,

		-- At last! The custom coordinate system is now First Class!
		basic_debug = false,
	})

	-- Finally! Minetest has shadow support!
	-- check if function is supported by server (old versions 5.5.0)
	if player["set_lighting"] ~= nil then
		player:set_lighting({
			shadows = {intensity=0.3},
		})
	else
		minetest.log("WARNING", "This server does not support player:lighting !");
	end
end)



