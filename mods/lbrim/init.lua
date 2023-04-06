
if not minetest.global_exists("lbrim") then lbrim = {} end
lbrim.modpath = minetest.get_modpath("lbrim")



minetest.register_node("lbrim:lava_source", {
  description = "Nether Lava Source",
  drawtype = "liquid",
  tiles = {
    {
      name = "lbrim_source.png",
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
      name = "lbrim_source.png",
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

  walkable = true,
  pointable = false,
  diggable = false,
  buildable_to = false,

	-- Liquids cannot be floodable.
	--floodable = true,

  is_ground_content = false,
  drop = "",
  drowning = 1,
  liquidtype = "source",
  liquid_alternative_flowing = "lbrim:lava_flowing",
  liquid_alternative_source = "lbrim:lava_source",
  liquid_viscosity = 7,
  liquid_renewable = true,
  damage_per_second = 16,
  post_effect_color = {a = 191, r = 255, g = 64, b = 0},
  
  groups = -- comment
	{
    lava = 3, 
    liquid = 2, 
    igniter = 1, 
    disable_jump = 1, 
    melt_around = 3
  },
  
  on_blast = function(pos, intensity) end,

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

minetest.register_node("lbrim:lava_flowing", {
  description = "Flowing Nether Lava",
  drawtype = "flowingliquid",
  tiles = {"lbrim_lava.png"},
  special_tiles = {
    {
      name = "lbrim_flowing.png",
      backface_culling = false,
      animation = {
        type = "vertical_frames",
        aspect_w = 16,
        aspect_h = 16,
        length = 3.3,
      },
    },
    {
      name = "lbrim_flowing.png",
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

  walkable = false,
  pointable = false,
  diggable = false,
  buildable_to = false,

	-- Liquids cannot be floodable.
	--floodable = true,

  is_ground_content = false,
  drop = "",
  drowning = 1,
  liquidtype = "flowing",
  liquid_alternative_flowing = "lbrim:lava_flowing",
  liquid_alternative_source = "lbrim:lava_source",
  liquid_viscosity = 7,
  liquid_renewable = true,
  damage_per_second = 16,
  post_effect_color = {a = 191, r = 255, g = 64, b = 0},
  
  groups = -- comment
	{
    lava = 3, 
    liquid = 2, 
    igniter = 1,
    not_in_creative_inventory = 1, 
    disable_jump = 1, 
    melt_around = 3
  },
  
  on_blast = function(pos, intensity) end,

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



