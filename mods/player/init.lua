
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

-- Default player appearance
-- Controled by 3d_armor mod!
--[[
default.player_register_model("character_musttest.b3d", {
	animation_speed = 30,
	textures = {"character.png", },
	animations = {
		-- Standard animations.
		stand     = { x=  0, y= 79, },
		lay       = { x=162, y=166, },
		walk      = { x=168, y=187, },
		mine      = { x=189, y=198, },
		walk_mine = { x=200, y=219, },
		-- Extra animations (not currently used by the game).
		sit       = { x= 81, y=160, },
        nod       = { x=221, y=251, },
	},
})
--]]

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
	if model then
		if player_model[name] == model_name then
			return
		end
		player:set_properties({
			mesh = model_name,
			textures = player_textures[name] or model.textures,
			visual = "mesh",
			visual_size = model.visual_size or {x=1, y=1},
		})
		default.player_set_animation(player, "stand")
	else
		player:set_properties({
			textures = { "player.png", "player_back.png", },
			visual = "upright_sprite",
		})
	end
	player_model[name] = model_name
end

function default.player_set_textures(player, textures)
	local name = player:get_player_name()
	player_textures[name] = textures
	player:set_properties({textures = textures,})
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
	--default.player_set_model(player, "character_musttest.b3d")
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
		local name = player:get_player_name()
		local model_name = player_model[name]
		local model = model_name and models[model_name]
		if model and not player_attached[name] then
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
			end

			-- Apply animations based on what the player is doing
			if player:get_hp() == 0 then
				player_set_animation(player, "lay")
			elseif walking then
				if player_sneak[name] ~= controls.sneak then
					player_anim[name] = nil
					player_sneak[name] = controls.sneak
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

-- Disable the "sneak glitch" for all players.
-- Note: 'sneak=false' interferes with footstep sounds when walking on snow.
minetest.register_on_joinplayer(function(player)
	player:set_physics_override({
		sneak_glitch = false,
		sneak = true,
		gravity = 1.0,
	})

	player:set_properties({
		infotext = rename.gpn(player:get_player_name()),
	})
	
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
			shadows = {intensity=0.5},
		})
	else
		minetest.log("WARNING", "This server does not support player:lighting !");
	end
end)



