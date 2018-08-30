tnt = {}

local enable_tnt = true
local tnt_radius = 3

-- Fill a list with data for content IDs, after all nodes are registered

function tnt.burn(pos)
	local name = minetest.get_node(pos).name
	local group = minetest.get_item_group(name, "tnt")
	if group > 0 then
		minetest.sound_play("tnt_ignite", {pos = pos})
		minetest.set_node(pos, {name = name .. "_burning"})
		minetest.get_node_timer(pos):start(1)
	elseif name == "tnt:gunpowder" then
		minetest.set_node(pos, {name = "tnt:gunpowder_burning"})
	end
end

reload.register_file("tnt:boom", minetest.get_modpath("tnt").."/tnt_boom.lua")

minetest.register_node("tnt:boom", {
	drawtype = "airlike",
	light_source = default.LIGHT_MAX - 1,
	walkable = false,
	drop = "",
	groups = {dig_immediate = 3},
  pointable = false,
  buildable_to = true,
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(0.5)
	end,
	on_timer = function(pos, elapsed)
		minetest.remove_node(pos)
	end,
  
  -- TNT chain-reactions cause slowness problems for the server.
  on_blast = function(pos)
    minetest.remove_node(pos)
  end,
})

-- overriden to add additional functionality in real_torch
minetest.register_node("tnt:gunpowder", {
	description = "Gun Powder",
	drawtype = "raillike",
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	tiles = {
    "tnt_gunpowder_straight.png", 
    "tnt_gunpowder_curved.png", 
    "tnt_gunpowder_t_junction.png", 
    "tnt_gunpowder_crossing.png",
  },
	inventory_image = "tnt_gunpowder_inventory.png",
	wield_image = "tnt_gunpowder_inventory.png",
	selection_box = {
		type = "fixed",
		fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
	},
	groups = {
    level = 1, 
    dig_immediate = 2, 
    attached_node = 1, 
    connect_to_raillike = minetest.raillike_group("gunpowder"),
  },
	sounds = default.node_sound_leaves_defaults(),

  on_punch = function(pos, node, puncher)
    local wielded = puncher:get_wielded_item():get_name()
    if wielded == "torches:torch_floor" or
       wielded == "torches:iron_torch" or
       wielded == "torches:kalite_torch_floor" then
      tnt.burn(pos)
      minetest.log("action", puncher:get_player_name() ..
        " ignites tnt:gunpowder at " ..
        minetest.pos_to_string(pos))
    end
  end,
  
  -- Chain-reactions cause slowness problems for the server.
  on_blast = function(pos)
    minetest.remove_node(pos)
  end,
})

minetest.register_node("tnt:gunpowder_burning", {
	drawtype = "raillike",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	light_source = 5,
	tiles = {{
		name = "tnt_gunpowder_burning_straight_animated.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 1,
		}
	},
	{
		name = "tnt_gunpowder_burning_curved_animated.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 1,
		}
	},
	{
		name = "tnt_gunpowder_burning_t_junction_animated.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 1,
		}
	},
	{
		name = "tnt_gunpowder_burning_crossing_animated.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 1,
		}
	}},
	selection_box = {
		type = "fixed",
		fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
	},
	drop = "",
	groups = {level = 1, dig_immediate = 2, attached_node = 1, connect_to_raillike = minetest.raillike_group("gunpowder")},
	sounds = default.node_sound_leaves_defaults(),
	on_timer = function(pos, elapsed)
		for dx = -1, 1 do
		for dz = -1, 1 do
		for dy = -1, 1 do
			if not (dx == 0 and dz == 0) then
				tnt.burn({
					x = pos.x + dx,
					y = pos.y + dy,
					z = pos.z + dz,
				})
			end
		end
		end
		end
		minetest.remove_node(pos)
	end,
  
  -- TNT chain-reactions cause slowness problems for the server.
  on_blast = function(pos)
    minetest.remove_node(pos)
  end,
          
	on_construct = function(pos)
		minetest.sound_play("tnt_gunpowder_burning", {pos = pos, gain = 2})
		minetest.get_node_timer(pos):start(1)
	end,
})

minetest.register_craft({
	output = "tnt:gunpowder 6",
	type = "shapeless",
	recipe = {"default:coal_lump", "default:gravel", "sulfur:dust"}
})

if enable_tnt then
	minetest.register_craft({
		output = "tnt:tnt",
		recipe = {
			{"group:wood", "tnt:gunpowder", "group:wood"},
			{"tnt:gunpowder", "tnt:gunpowder", "tnt:gunpowder"},
			{"group:wood", "tnt:gunpowder", "group:wood"},
		}
	})

	minetest.register_abm({
		label = "TNT ignition",
		nodenames = {"group:tnt", "tnt:gunpowder"},
		neighbors = {"group:igniter"},
		interval = 4 * default.ABM_TIMER_MULTIPLIER,
		chance = 1 * default.ABM_CHANCE_MULTIPLIER,
		action = tnt.burn,
	})
end

minetest.register_privilege("tnt",
  {description="Player can place TNT anywhere.", give_to_singleplayer=false})

function tnt.register_tnt(def)
	local name
	if not def.name:find(':') then
		name = "tnt:" .. def.name
	else
		name = def.name
		def.name = def.name:match(":([%w_]+)")
	end
	if not def.tiles then def.tiles = {} end
	local tnt_top = def.tiles.top or def.name .. "_top.png"
	local tnt_bottom = def.tiles.bottom or def.name .. "_bottom.png"
	local tnt_side = def.tiles.side or def.name .. "_side.png"
	local tnt_burning = def.tiles.burning or def.name .. "_top_burning_animated.png"
	if not def.damage_radius then def.damage_radius = def.radius * 2 end

    minetest.register_node(":" .. name, {
        description = def.description,
        tiles = {tnt_top, tnt_bottom, tnt_side},
        is_ground_content = false,
        groups = {level = 1, choppy = 3, dig_immediate = 2, mesecon = 2, tnt = 1},
        sounds = default.node_sound_wood_defaults(),
        
        on_punch = function(pos, node, puncher)
            local wielded = puncher:get_wielded_item():get_name()
            if wielded == "torches:torch_floor" or
               wielded == "torches:iron_torch" or
               wielded == "torches:kalite_torch_floor" then
                minetest.set_node(pos, {name = name .. "_burning"})
                minetest.log("action", puncher:get_player_name() ..
                  " ignites " .. node.name .. " at " ..
                  minetest.pos_to_string(pos))
            end
        end,
        
        -- TNT chain-reactions cause slowness problems for the server.
        on_blast = function(pos)
          minetest.remove_node(pos)
        end,

				on_place = function(itemstack, placer, pointed_thing)
					local pos = pointed_thing.under
					if not placer then return end
					if not placer:is_player() then return end
					local pname = placer:get_player_name()

					-- Players without the TNT priv go through checks.
					if not minetest.check_player_privs(placer, {tnt=true}) then
						if pos.y > -100 then
							minetest.chat_send_player(pname, "# Server: Use of TNT near ground level is forbidden.")
							return itemstack
						end
						if city_block:in_no_tnt_zone(pos) then
							minetest.chat_send_player(pname, "# Server: Too close to a residential zone for TNT!")
							return itemstack
						end
					end

					-- All checks passed.
					return minetest.item_place(itemstack, placer, pointed_thing)
				end,
    })

	minetest.register_node(":" .. name .. "_burning", {
		tiles = {
			{
				name = tnt_burning,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 1,
				}
			},
			tnt_bottom, tnt_side
			},
		light_source = 5,
		drop = "",
		sounds = default.node_sound_wood_defaults(),
		groups = {falling_node = 1},
		on_timer = function(pos, elapsed)
			tnt.boom(pos, def)
		end,
    
    -- No chain-reactions.
		on_blast = function(pos)
      minetest.remove_node(pos)
    end,
    
		on_construct = function(pos)
			minetest.sound_play("tnt_ignite", {pos = pos})
			minetest.get_node_timer(pos):start(5)
			minetest.check_for_falling(pos)
		end,
	})
end

tnt.register_tnt({
	name = "tnt:tnt",
	description = "Explosive TNT",
	radius = tnt_radius,
})
