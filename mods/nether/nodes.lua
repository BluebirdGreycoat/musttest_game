
local box = {
	type = "fixed",
	fixed = {-0.5, -0.5, (-0.5/8)*4, 0.5, 0.5, (0.5/8)*4},
}

local anim = {
	type = "vertical_frames",
	aspect_w = 16,
	aspect_h = 16,
	length = 0.9
}

minetest.register_node("nether:portal_liquid", {
  description = 'Portal Liquid (You Hacker, You!)',
	paramtype2 = "colorfacedir",
  groups = {unbreakable=1, immovable=1, not_in_creative_inventory=1},
  drop = "",
  drawtype = "nodebox",
  paramtype = "light",
	palette = "nether_portals_palette.png",
  tiles = {
		'nether_transparent.png',
		'nether_transparent.png',
		'nether_transparent.png',
		'nether_transparent.png',
		{name='nether_portal.png', animation=anim},
		{name='nether_portal.png', animation=anim},
	},
  node_box = box,
  use_texture_alpha = "blend",
  walkable = false,
  pointable = false,

  -- Necessary to allow bone placement, and to let players "pop" the portal by
  -- e.g., placing a torch inside.
  buildable_to = true,

  is_ground_content = false,
  diggable = false,
  light_source = 5,
  sunlight_propagates = true,
  post_effect_color = {a = 160, r = 128, g = 0, b = 80},
  on_rotate = false,

	on_destruct = function(pos)
		-- This is transient damage! The gate can be reactivated.
		obsidian_gateway.on_damage_gate(pos, true)
	end,

	-- Slow down player movement.
	movement_speed_multiplier = default.SLOW_SPEED_NETHER,
	liquid_viscosity = 8,
  liquidtype = "source",
  liquid_alternative_flowing = "nether:portal_liquid",
  liquid_alternative_source = "nether:portal_liquid",
  liquid_renewable = false,
  liquid_range = 0,

  -- Timer function should execute once per second.
  on_timer = function(pos, elapsed)
		if math.random(1, 3) == 1 then
			ambiance.sound_play("nether_portal_ambient", pos, 1.0, 10)
		end

		local meta = minetest.get_meta(pos)
		local color = meta:get_string("color")

		if not color or color == "" then
			color = "gold"
		end

		local image = "nether_particle_anim3.png"
		local pref = hb4.nearest_player(pos)
		if pref then
			-- Player inside node? Show bubbles instead of sparks.
			if vector.distance(pref:get_pos(), pos) < 1 then
				image = "nether_particle_anim2.png"
			end
		end

		local d = 0.5
		minetest.add_particlespawner({
			amount = 5,
			time = 1.1,
			minpos = {x=pos.x-d, y=pos.y-d, z=pos.z-d},
			maxpos = {x=pos.x+d, y=pos.y+d, z=pos.z+d},
			minvel = {x=0, y=-d, z=0},
			maxvel = {x=0, y=d, z=0},
			minacc = {x=0, y=0, z=0},
			maxacc = {x=0, y=0, z=0},
			minexptime = 1.5,
			maxexptime = 2.5,
			minsize = 1,
			maxsize = 1.5,
			collisiondetection = true,
			collision_removal = true,
			texture = image .. "^[colorize:" .. color .. ":alpha",
			vertical = false,

			animation = {
				type = "vertical_frames",
				aspect_w = 7,
				aspect_h = 7,

				-- Disabled for now due to causing older clients to hang.
				--length = -1,
				length = 1.0,
			},

			glow = 14,
		})

		-- Keep running.
		return true
  end,
})
