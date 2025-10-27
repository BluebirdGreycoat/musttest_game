
-- Minetest 0.4 mod: "playermod" Name change required due to EXCESSIVE use of
-- "player" as a variable name throughout the codebase, leading to a sitation
-- where somebody, somewhere, is changing its value.
-- See README.txt for licensing and other information.
if not minetest.global_exists("playermod") then playermod = {} end
playermod.modpath = minetest.get_modpath("player")

dofile(playermod.modpath .. "/hotbar.lua")

-- Player animation blending
-- Note: This is currently broken due to a bug in Irrlicht, leave at 0
local animation_blend = 0

playermod.registered_player_models = {}

-- Local for speed.
local models = playermod.registered_player_models



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



function default.player_get_animation(pref)
	local name = pref:get_player_name()
	return {
		model = player_model[name],
		textures = player_textures[name],
		animation = player_anim[name],
	}
end



-- Called when a player's appearance needs to be updated
function default.player_set_model(pref, model_name)
	local name = pref:get_player_name()
	local model = models[model_name]

	if player_model[name] == model_name then
		return
	end

	pova.set_override(pref, "properties", {
		mesh = model_name,
		textures = player_textures[name] or model.textures,
		visual = "mesh",
		visual_size = model.visual_size or {x=1, y=1, z=1},
	})

	default.player_set_animation(pref, "stand")
	player_model[name] = model_name
end



function default.player_set_textures(pref, textures)
	local name = pref:get_player_name()
	player_textures[name] = textures
	pova.set_override(pref, "properties", {textures = textures})
end



function default.player_set_animation(pref, anim_name, speed)
	local name = pref:get_player_name()
	if player_anim[name] == anim_name then
		return
	end
	local model = player_model[name] and models[player_model[name]]
	if not (model and model.animations[anim_name]) then
		return
	end
	local anim = model.animations[anim_name]
	player_anim[name] = anim_name
	pref:set_animation(anim, speed or model.animation_speed, animation_blend)
end



-- Update appearance when the player joins
minetest.register_on_joinplayer(function(pref)
	local pname = pref:get_player_name()
	default.player_attached[pname] = false

	pref:set_local_animation(
		{x=0, y=79}, {x=168, y=187}, {x=189, y=198}, {x=200, y=219}, 30)

	-- Big hot-bar is revoked for cheaters.
  if minetest.check_player_privs(pref, {big_hotbar=true}) and
			not sheriff.is_cheater(pname) then
		local meta = pref:get_meta()
		if meta:get_int("show_big_hotbar") == 1 then
			playermod.set_big_hotbar(pref)
		else
			playermod.set_small_hotbar(pref)
		end
  else
		playermod.set_small_hotbar(pref)
  end
  
	pref:hud_set_hotbar_selected_image("hud_hotbar_selected.png")

	-- Update player velocity if available.
	if player_velocity[pname] then
		pref:add_velocity(player_velocity[pname])
		player_velocity[pname] = nil
	end
end)



minetest.register_on_leaveplayer(function(pref)
	local name = pref:get_player_name()
	player_model[name] = nil
	player_anim[name] = nil
	player_textures[name] = nil

	-- Save player velocity. If they login again, I will be able to restore it.
	player_velocity[name] = pref:get_velocity()
end)



-- Localize for better performance.
local player_set_animation = default.player_set_animation
local player_attached = default.player_attached

-- Check each player and apply animations
minetest.register_globalstep(function(dtime)
	for _, pref in pairs(minetest.get_connected_players()) do
		local pname = pref:get_player_name()
		local model_name = player_model[pname]
		local model = model_name and models[model_name]
		if model and not player_attached[pname] then
			local controls = pref:get_player_control()
			local walking = false
			local animation_speed_mod = model.animation_speed or 30

			-- Determine if the player is walking
			if controls.up or controls.down or controls.left or controls.right then
				walking = true
			end

			-- Determine if the player is sneaking, and reduce animation speed if so
			if controls.sneak then
				animation_speed_mod = animation_speed_mod / 2

				pova.set_modifier(pref, "properties",
					{makes_footstep_sound = false}, "footstep_sneaking")
			else
				pova.remove_modifier(pref, "properties", "footstep_sneaking")
			end

			-- Apply animations based on what the player is doing
			if pref:get_hp() == 0 then
				player_set_animation(pref, "lay")
			elseif walking then
				if player_sneak[pname] ~= controls.sneak then
					player_anim[pname] = nil
					player_sneak[pname] = controls.sneak
				end
				if controls.LMB then
					player_set_animation(pref, "walk_mine", animation_speed_mod)
				else
					player_set_animation(pref, "walk", animation_speed_mod)
				end
			elseif controls.LMB then
				player_set_animation(pref, "mine")
			else
				player_set_animation(pref, "stand", animation_speed_mod)
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
minetest.register_on_joinplayer(function(pref)
	set_prng(pref)

	pova.set_override(pref, "properties", {
		infotext = rename.gpn(pref:get_player_name()),
	})
	pova.set_override(pref, "nametag", {
		color = {a=255, r=0, g=255, b=255},
		text = rename.gpn(pref:get_player_name()),
		bgcolor = false,
	})

	local pmeta = pref:get_meta()
	local random_seed = pmeta:get_int("random_seed")
	local prng = PseudoRandom(random_seed)

	-- The max diff in either direction should be 0.1, otherwise players will
	-- be too oversized or undersized.
	local nsize = 1+(prng:next(-10, 10)/100)

	-- Adjust base speed. Max range diff is 0.05 either direction.
	local nspeed = 1+(prng:next(-10, 10)/200)

	-- Adjust base jump. Max range diff is 0.05 either direction.
	local njump = 1+(prng:next(-10, 10)/100)

	pova.set_modifier(pref, "properties",
		{visual_size={x=nsize, y=nsize}},
	"notbornequal", {priority=-999})

	pova.set_modifier(pref, "physics",
		{speed=nspeed, jump=njump},
	"notbornequal", {priority=-999})

	-- Disable the minimap. Cheaters will of course be able to enable it.
	-- Can be reenabled via item in-game.
	pref:hud_set_flags({
		minimap = false,
		minimap_radar = false,

		-- At last! The custom coordinate system is now First Class!
		basic_debug = false,
	})

	-- Finally! Minetest has shadow support!
	-- check if function is supported by server (old versions 5.5.0)
	if pref["set_lighting"] ~= nil then
		pref:set_lighting({
			shadows = {intensity=0.3},
			volumetric_light = {strength=0.2},
			bloom = {intensity=0.05},
		})
	else
		minetest.log("WARNING", "This server does not support player:lighting !");
	end
end)



