
cable = cable or {}
cable.modpath = minetest.get_modpath("cable")

cable_hv = cable_hv or {}
cable_mv = cable_mv or {}
cable_lv = cable_lv or {}

cb2_hv = cb2_hv or {}
cb2_mv = cb2_mv or {}
cb2_lv = cb2_lv or {}

-- Ensure tables exist.
stat2 = stat2 or {}
stat2_hv = stat2_hv or {}
stat2_mv = stat2_mv or {}
stat2_lv = stat2_lv or {}



-- API function. Get max length of cable, per tier.
cable.get_max_length =
function(tier)
	-- Fixed lengths! Network caching code relies on these values.
  if tier == "lv" then
    return 16
  elseif tier == "mv" then
    return 24
  elseif tier == "hv" then
    return 32
  end
  return 0
end



-- Register cable functions.
for k, v in ipairs({
  {tier="hv"},
  {tier="mv"},
  {tier="lv"},
}) do
  _G["cable_" .. v.tier].after_place_node =
  function(pos, placer, itemstack, pointed_thing)
    networks.invalidate_hubs(pos, v.tier)
  end

  _G["cable_" .. v.tier].on_destruct =
  function(pos)
    networks.invalidate_hubs(pos, v.tier)
  end

  _G["cable_" .. v.tier].on_rotate =
  function(pos, node, user, mode, new_param2)
    networks.invalidate_hubs(pos, v.tier)
    return nil -- Screwdriver may rotate.
  end
end



local function choose_rotation(pos, tier)
	local positions = {
		{pos={x=pos.x+1, y=pos.y, z=pos.z}, param2=0},
		{pos={x=pos.x-1, y=pos.y, z=pos.z}, param2=2},
		{pos={x=pos.x, y=pos.y+1, z=pos.z}, param2=5},
		{pos={x=pos.x, y=pos.y-1, z=pos.z}, param2=7},
		{pos={x=pos.x, y=pos.y, z=pos.z+1}, param2=1},
		{pos={x=pos.x, y=pos.y, z=pos.z-1}, param2=3},
	}

	local rn = "cb2:" .. tier
	for k, v in ipairs(positions) do
		local node = minetest.get_node(v.pos)
		if node.name == rn then
			local n2 = minetest.get_node(pos)
			n2.param2 = node.param2
			minetest.set_node(pos, n2)
			return
		end
	end

	local sn = "stat2:" .. tier
	for k, v in ipairs(positions) do
		local node = minetest.get_node(v.pos)
		if node.name == sn then
			local n2 = minetest.get_node(pos)
			n2.param2 = v.param2
			minetest.set_node(pos, n2)
			return
		end
	end
end



-- Register NEW cable functions.
for k, v in ipairs({
  {tier="hv"},
  {tier="mv"},
  {tier="lv"},
}) do
  _G["cb2_" .. v.tier].after_place_node =
  function(pos, placer, itemstack, pointed_thing)
		choose_rotation(pos, v.tier)
		stat2.invalidate_hubs(pos, v.tier)
  end

  _G["cb2_" .. v.tier].on_destruct =
  function(pos)
		stat2.invalidate_hubs(pos, v.tier)
  end

  _G["cb2_" .. v.tier].on_rotate =
  function(pos, node, user, mode, new_param2)
		stat2.invalidate_hubs(pos, v.tier)
    return nil -- Screwdriver may rotate.
  end
end



if not cable.run_once then
  for k, v in ipairs({
    {tier="hv", name="HV Cable", tile="cable_hv.png", boxd=6},
    {tier="mv", name="MV Cable", tile="cable_mv.png", boxd=7},
    {tier="lv", name="LV Cable", tile="cable_lv.png", boxd=8},
  }) do
    -- Which function table do we use?
    local functable = _G["cable_" .. v.tier]
    
    minetest.register_node("cable:" .. v.tier, {
      description = v.name .. " [Max length: " .. cable.get_max_length(v.tier) .. " meters.]",
      tiles = {v.tile},
      
      groups = {
        level=1, dig_immediate=2,
        immovable = 1,
      },
			drop = "cb2:" .. v.tier,
      
      paramtype = "light",
      drawtype = "nodebox",
      node_box = {
        type = "fixed",
        fixed = {-0.5, -1/v.boxd, -1/v.boxd, 0.5, 1/v.boxd, 1/v.boxd},
      },
      
      paramtype2 = "facedir",
      is_ground_content = false,
      sounds = default.node_sound_wood_defaults(),
      
      on_rotate = function(...)
        return functable.on_rotate(...) end,
      after_place_node = function(...)
        return functable.after_place_node(...) end,
      on_destruct = function(...)
        return functable.on_destruct(...) end,
    })
  end
  
  minetest.register_alias("switching_station:cable", "cable:hv")
  
  minetest.register_craft({
    output = "cb2:hv 3",
    recipe = {
      {'plastic:plastic_sheeting', 'plastic:plastic_sheeting', 'plastic:plastic_sheeting'},
      {'cb2:mv', 'cb2:mv', 'cb2:mv'},
      {'plastic:plastic_sheeting', 'plastic:plastic_sheeting', 'plastic:plastic_sheeting'},
    },
  })
  
  minetest.register_craft({
    output = "cb2:mv 3",
    recipe = {
      {'rubber:rubber_fiber', 'rubber:rubber_fiber', 'rubber:rubber_fiber'},
      {'cb2:lv', 'cb2:lv', 'cb2:lv'},
      {'rubber:rubber_fiber', 'rubber:rubber_fiber', 'rubber:rubber_fiber'},
    },
  })
  
  minetest.register_craft({
    output = "cb2:lv 3",
    recipe = {
      {'default:paper', 'default:paper', 'default:paper'},
      {'default:copper_ingot', 'default:copper_ingot', 'default:copper_ingot'},
      {'default:paper', 'default:paper', 'default:paper'},
    },
  })
  
	-- New cable types.
  for k, v in ipairs({
    {tier="hv", name="HV Cable", tile="cable_hv.png", w=5},
    {tier="mv", name="MV Cable", tile="cable_mv.png", w=5.5},
    {tier="lv", name="LV Cable", tile="cable_lv.png", w=6},
  }) do
    -- Which function table do we use?
    local functable = _G["cb2_" .. v.tier]

		local function transform(nodebox)
			for k, v in ipairs(nodebox) do
				for m, n in ipairs(v) do
					local p = nodebox[k][m]
					p = p / 16
					p = p - 0.5
					nodebox[k][m] = p
				end
			end
		end

		local nodebox = {
			{-2, v.w, v.w, 18, 16-v.w, 16-v.w},
		}
		local selectionbox = {
			{0, v.w, v.w, 16, 16-v.w, 16-v.w},
		}
		transform(nodebox)
		transform(selectionbox)

    minetest.register_node(":cb2:" .. v.tier, {
      description = v.name .. " [Max Length: " .. cable.get_max_length(v.tier) .. " Meters.]",
      tiles = {v.tile},

      groups = {level=1, dig_immediate=2},

      paramtype = "light",
      drawtype = "nodebox",
      node_box = {
        type = "fixed",
        fixed = nodebox,
      },
			selection_box = {
				type = "fixed",
				fixed = selectionbox,
			},

      paramtype2 = "facedir",
      is_ground_content = false,
      sounds = default.node_sound_wood_defaults(),

      on_rotate = function(...)
        return functable.on_rotate(...) end,
      after_place_node = function(...)
        return functable.after_place_node(...) end,
      on_destruct = function(...)
        return functable.on_destruct(...) end,
    })
  end

  local c = "cable:core"
  local f = cable.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
  cable.run_once = true
end
