
if not minetest.global_exists("lava") then lava = {} end
lava.modpath = minetest.get_modpath("lava")



if not lava.run_once then
	dofile(lava.modpath .. "/basalt_and_pumice.lua")

	minetest.register_node(":default:lava_source", {
		description = "Lava Source",
		drawtype = "liquid",
		tiles = {
			{
				name = "default_lava_source_animated.png",
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 3.0,
				},
			},
		},
		special_tiles = {
			-- New-style lava source material (mostly unused)
			{
				name = "default_lava_source_animated.png",
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 3.0,
				},
				backface_culling = false,
			},
		},
		paramtype = "light",
		light_source = default.LIGHT_MAX - 2,

		-- Players can't destroy lava by drowning in it or dropping gravel into it. By MustTest
		walkable = true,

		pointable = false,
		diggable = false,

		-- Liquids cannot be floodable.
		--floodable = true,

		-- Players can't destroy lava by building to it. By MustTest
		buildable_to = false,

		is_ground_content = false,
		drop = "",
		drowning = 1,
		liquidtype = "source",
		liquid_alternative_flowing = "default:lava_flowing",
		liquid_alternative_source = "default:lava_source",
		liquid_viscosity = 7,
		liquid_renewable = false,
		damage_per_second = 4 * 2,
		post_effect_color = {a = 191, r = 255, g = 64, b = 0},
		groups = -- comment
		{
			lava = 3,
			liquid = 2,
			igniter = 1,
			disable_jump = 1,
			melt_around = 3,
		},

		on_player_walk_over = function(pos, player)
			if not gdac.player_is_admin(player) then
				local pname = player:get_player_name()
				if player:get_hp() > 0 and not heatdamage.is_immune(pname) then
					local pa = vector.add(pos, {x=0, y=1, z=0})
					if minetest.get_node(pa).name == "air" then
						minetest.add_node(pa, {name="fire:basic_flame"})
					end
					minetest.chat_send_all("# Server: <" .. rename.gpn(pname) .. "> walked on lava.")
					player:set_hp(0)
				end
			end
		end,

		on_collapse_to_entity = function(pos, node)
			-- Do not allow player to obtain the node itself.
  	end,
	})

	minetest.register_node(":default:lava_flowing", {
		description = "Flowing Lava",
		drawtype = "flowingliquid",
		tiles = {"default_lava.png"},
		special_tiles = {
			{
				name = "default_lava_flowing_animated.png",
				backface_culling = false,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 3.3,
				},
			},
			{
				name = "default_lava_flowing_animated.png",
				backface_culling = true,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 3.3,
				},
			},
		},
		paramtype = "light",
		paramtype2 = "flowingliquid",
		light_source = default.LIGHT_MAX - 2,

			-- It is possible to destroy flowing nodes with gravel or by drowning in it. By MustTest
		walkable = false,

		pointable = false,
		diggable = false,

		-- Players can't destroy lava by building to it. By MustTest
		buildable_to = false,

		-- Liquids cannot be floodable.
		--floodable = true,

		is_ground_content = false,
		drop = "",
		drowning = 1,
		liquidtype = "flowing",
		liquid_alternative_flowing = "default:lava_flowing",
		liquid_alternative_source = "default:lava_source",
		liquid_viscosity = 7,
		liquid_renewable = false,
		damage_per_second = 4 * 2,
		post_effect_color = {a = 191, r = 255, g = 64, b = 0},

		groups = -- comment
		{
			lava = 3,
			liquid = 2,
			igniter = 1,
			not_in_creative_inventory = 1,
			disable_jump = 1,
			melt_around = 3,
		},

		on_player_walk_over = function(pos, player)
			if not gdac.player_is_admin(player) then
				local pname = player:get_player_name()
				if player:get_hp() > 0 and not heatdamage.is_immune(pname) then
					local pa = vector.add(pos, {x=0, y=1, z=0})
					if minetest.get_node(pa).name == "air" then
						minetest.add_node(pa, {name="fire:basic_flame"})
					end
					minetest.chat_send_all("# Server: <" .. rename.gpn(pname) .. "> walked on lava.")
					player:set_hp(0)
				end
			end
		end,

		on_collapse_to_entity = function(pos, node)
			-- Do not allow player to obtain the node itself.
  	end,
	})

	local c = "lava:core"
	local f = lava.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	lava.run_once = true
end
