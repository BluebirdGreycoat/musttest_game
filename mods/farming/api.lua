
-- Localize for performance.
local math_random = math.random

function farming.notify_soil(pos)
	local minp = vector.add(pos, -4)
	local maxp = vector.add(pos, 4)
	local soils = minetest.find_nodes_in_area(minp, maxp, "group:field")
	if soils and #soils > 0 then
		for i=1, #soils do
			local timer = minetest.get_node_timer(soils[i])
			if timer and not timer:is_started() then
				timer:start(math_random(1, 60))
			end
		end
	end
end

function farming.notify_soil_single(pos)
	local timer = minetest.get_node_timer(pos)
  if timer and not timer:is_started() then
  	timer:start(math_random(1, 60))
	end
end

-- Wear out hoes, place soil
-- TODO Ignore group:flower
farming.hoe_on_use = function(itemstack, user, pointed_thing, uses)
	local pt = pointed_thing
	-- check if pointing at a node
	if not pt then
		return
	end
	if pt.type ~= "node" then
		return
	end

	local under = minetest.get_node(pt.under)
  
  -- Let hoes be used to get resources back from planted mese crystals.
  -- Note that harvesting a crystal completely yeilds more fragments,
  -- but there is a risk that the you won't be able to restore the plant when you're done.
  if string.find(under.name, "^mese_crystals:mese_crystal_ore%d") then
    user:get_inventory():add_item("main", "default:mese_crystal_fragment 3")
    ambiance.sound_play("default_break_glass", pt.under, 0.3, 10)
    minetest.remove_node(pt.under)
    -- 1/2 chance to get bluerack back; this is because 1 bluerack makes 2 seeds.
    -- This way, we don't make it possible to magically duplicate resources.
    if math_random(1, 2) == 1 then
      local p = {x=pt.under.x, y=pt.under.y-1, z=pt.under.z}
      if minetest.get_node(p).name == "default:obsidian" then
        minetest.add_node(p, {name="rackstone:bluerack"})
        ambiance.sound_play("default_dig_cracky", pt.under, 1.0, 10)
      end
    end
    return
  end
  
	local p = {x=pt.under.x, y=pt.under.y+1, z=pt.under.z}
	local above = minetest.get_node(p)

	-- return if any of the nodes is not registered
	if not minetest.reg_ns_nodes[under.name] then
		return
	end
	if not minetest.reg_ns_nodes[above.name] then
		return
	end

	-- check if the node above the pointed thing is air
	if above.name ~= "air" then
		return
	end

	-- check if pointing at soil
	if minetest.get_item_group(under.name, "soil") ~= 1 then
		return
	end

	-- check if (wet) soil defined
	local ndef = minetest.reg_ns_nodes[under.name]
	if ndef.soil == nil or ndef.soil.wet == nil or ndef.soil.dry == nil then
		return
	end

	if minetest.is_protected(pt.under, user:get_player_name()) then
		minetest.record_protection_violation(pt.under, user:get_player_name())
		return
	end
	if minetest.is_protected(pt.above, user:get_player_name()) then
		minetest.record_protection_violation(pt.above, user:get_player_name())
		return
	end

	-- turn the node into soil and play sound
	minetest.add_node(pt.under, {name = ndef.soil.dry})
	minetest.sound_play("default_dig_crumbly", {
		pos = pt.under,
		gain = 0.5,
	})
	farming.notify_soil_single(pt.under)

	if not minetest.setting_getbool("creative_mode") then
		-- wear tool
		local wdef = itemstack:get_definition()
		itemstack:add_wear(65535/(uses-1))
        -- tool break sound
		if itemstack:get_count() == 0 and wdef.sound and wdef.sound.breaks then
			minetest.sound_play(wdef.sound.breaks, {pos = pt.above, gain = 0.5})
		end
	end
	return itemstack
end

-- Register new hoes
farming.register_hoe = function(name, def)
	-- Check for : prefix (register new hoes in your mod's namespace)
	if name:sub(1,1) ~= ":" then
		name = ":" .. name
	end
	-- Check def table
	if def.description == nil then
		def.description = "Hoe"
	end
	if def.inventory_image == nil then
		def.inventory_image = "unknown_item.png"
	end
	if def.recipe == nil then
		def.recipe = {
			{"air","air",""},
			{"","group:stick",""},
			{"","group:stick",""}
		}
	end
	if def.max_uses == nil then
		def.max_uses = 30
	end
	-- Register the tool
	minetest.register_tool(name, {
		description = def.description,
		inventory_image = def.inventory_image,
		on_use = function(itemstack, user, pointed_thing)
			return farming.hoe_on_use(itemstack, user, pointed_thing, def.max_uses)
		end,
        groups = def.groups,
        sound = {breaks = "default_tool_breaks"},
	})
	-- Register its recipe
	if def.material == nil then
		minetest.register_craft({
			output = name:sub(2),
			recipe = def.recipe
		})
	else
		minetest.register_craft({
			output = name:sub(2),
			recipe = {
				{def.material, def.material, ""},
				{"", "group:stick", ""},
				{"", "group:stick", ""}
			}
		})
		-- Reverse Recipe
		minetest.register_craft({
			output = name:sub(2),
			recipe = {
				{"", def.material, def.material},
				{"", "group:stick", ""},
				{"", "group:stick", ""}
			}
		})
	end
end

local function tick_multiplier(pos)
	local minp = vector.subtract(pos, 2)
	local maxp = vector.add(pos, 2)

	local mult = 1

	local cold = minetest.find_nodes_in_area(minp, maxp, "group:cold")
	mult = mult + (#cold / 2)

	minp = vector.subtract(pos, 3)
	maxp = vector.add(pos, 3)

	local minerals = minetest.find_nodes_in_area(minp, maxp, "glowstone:minerals")
	mult = mult - (#minerals / 4)

	-- Multiplier cannot be less than 0.3.
	if mult < 0.2 then mult = 0.2 end
	return mult
end

-- how often node timers for plants will tick, +/- some random value
local function tick(pos)
	local mult = tick_multiplier(pos)
	local min = 200 * mult
	local max = 350 * mult
  minetest.get_node_timer(pos):start(math_random(min, max))

  --minetest.get_node_timer(pos):start(1.0) -- Debug
end

-- how often a growth failure tick is retried (e.g. too dark)
local function tick_again(pos)
	local min = 40
	local max = 80
  minetest.get_node_timer(pos):start(math_random(min, max))

  --minetest.get_node_timer(pos):start(1.0) -- Debug
end

-- Seed placement
farming.place_seed = function(itemstack, placer, pointed_thing, plantname)
	local pt = pointed_thing
	-- check if pointing at a node
	if not pt then
		return itemstack
	end
	if pt.type ~= "node" then
		return itemstack
	end

	local under = minetest.get_node(pt.under)
  
  -- Pass through interactions to nodes that define them (like chests).
  do
    local pdef = minetest.reg_ns_nodes[under.name]
    if pdef and pdef.on_rightclick and not placer:get_player_control().sneak then
      return pdef.on_rightclick(pt.under, under, placer, itemstack, pt)
    end
  end

	local above = minetest.get_node(pt.above)

	-- Permit player to place seed on protected soil (by commenting this code).
	-- This allows players to build public farms.
	--if minetest.is_protected(pt.under, placer:get_player_name()) then
	--	minetest.record_protection_violation(pt.under, placer:get_player_name())
	--	return
	--end

	if minetest.is_protected(pt.above, placer:get_player_name()) then
		minetest.record_protection_violation(pt.above, placer:get_player_name())
		return
	end

	-- return if any of the nodes is not registered
	if not minetest.reg_ns_nodes[under.name] then
		return itemstack
	end
	if not minetest.reg_ns_nodes[above.name] then
		return itemstack
	end

	-- check if pointing at the top of the node
	if pt.above.y ~= pt.under.y+1 then
		return itemstack
	end

	-- check if you can replace the node above the pointed node
	local ndef = minetest.reg_ns_nodes[above.name]
	if not ndef or not ndef.buildable_to then
		return itemstack
	end

	-- check if pointing at soil
	if minetest.get_item_group(under.name, "soil") < 2 then
		return itemstack
	end

	-- add the node and remove 1 item from the itemstack
	-- note: use of `add_node` automatically invokes droplift + dirtspread notifications.
	minetest.add_node(pt.above, {name = plantname, param2 = 1})
	tick(pt.above)
  itemstack:take_item()
	return itemstack
end

-- This should only ever be called from the `on_timer' callback of a node.
farming.grow_plant = function(pos, elapsed)
	local node = minetest.get_node(pos)
	local name = node.name
	local def = minetest.reg_ns_nodes[name]
  
	if not def.next_plant then
		-- disable timer for fully grown plant
		return
	end

	-- grow seed
	if minetest.get_item_group(node.name, "seed") and def.fertility then
		local soil_node = minetest.get_node_or_nil({x = pos.x, y = pos.y - 1, z = pos.z})
		if not soil_node then
			tick_again(pos)
			return
		end
		-- omitted is a check for light, we assume seeds can germinate in the dark.
		for _, v in pairs(def.fertility) do
			if minetest.get_item_group(soil_node.name, v) ~= 0 then
				local placenode = {name = def.next_plant}
				if def.place_param2 then
					placenode.param2 = def.place_param2
				end
				minetest.swap_node(pos, placenode)
				if minetest.reg_ns_nodes[def.next_plant].next_plant then
					tick(pos)
					return
				end
			end
		end

		return
	end
  
	-- check if on wet soil
	local below = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})
	if minetest.get_item_group(below.name, "soil") < 3 then
		tick_again(pos)
		return
	end
  
	-- check light
	local light = minetest.get_node_light(pos)
	if not light or light < def.minlight or light > def.maxlight then
		tick_again(pos)
		return
	end
  
	-- grow
	local placenode = {name = def.next_plant}
	if def.place_param2 then
		placenode.param2 = def.place_param2
	end
	minetest.swap_node(pos, placenode)
  
	-- new timer needed?
	if minetest.reg_ns_nodes[def.next_plant].next_plant then
		tick(pos)
	end
  
	return
end

-- Register plants
farming.register_plant = function(name, def)
	local mname = name:split(":")[1]
	local pname = name:split(":")[2]

	-- Check def table
	if not def.description then
		def.description = "Seed"
	end
	if not def.inventory_image then
		def.inventory_image = "unknown_item.png"
	end
	if not def.steps then
		return nil
	end
	if not def.minlight then
		def.minlight = 1
	end
	if not def.maxlight then
		def.maxlight = 14
	end
	if not def.fertility then
		def.fertility = {}
	end

	-- Register seed
	local g = {level = 1, seed = 1, seed_oil = 1, snappy = 3, attached_node = 1, flammable = 2, notify_destruct = 1}
	for k, v in pairs(def.fertility) do
		g[v] = 1
	end
	minetest.register_node(":" .. mname .. ":seed_" .. pname, {
		description = def.description,
		tiles = {def.inventory_image},
		inventory_image = def.inventory_image,
		wield_image = def.inventory_image,
		drawtype = "signlike",
		groups = g,
		paramtype = "light",
		paramtype2 = "wallmounted",
    place_param2 = def.place_param2 or nil, -- this isn't actually used for placement
		walkable = false,
		sunlight_propagates = true,
		selection_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
		},
		fertility = def.fertility,
		sounds = default.node_sound_dirt_defaults({
			dug = {name = "default_grass_footstep", gain = 0.2},
			place = {name = "default_place_node", gain = 0.25},
		}),

		on_place = function(itemstack, placer, pointed_thing)
      local under = pointed_thing.under
			local node = minetest.get_node(under)
			local udef = minetest.reg_ns_nodes[node.name]
			if udef and udef.on_rightclick and
					not (placer and placer:get_player_control().sneak) then
				return udef.on_rightclick(under, node, placer, itemstack,
					pointed_thing) or itemstack
			end

			return farming.place_seed(itemstack, placer, pointed_thing, mname .. ":seed_" .. pname)
		end,
		next_plant = mname .. ":" .. pname .. "_1",
		on_timer = farming.grow_plant,
		minlight = def.minlight,
		maxlight = def.maxlight,
	})

	-- Register harvest
	minetest.register_craftitem(":" .. mname .. ":" .. pname, {
		description = pname:gsub("^%l", string.upper),
		inventory_image = mname .. "_" .. pname .. ".png",
		groups = {flammable = 2},

		-- Pass through flowerpot data if available.
		flowerpot_insert = def.flowerpot_insert,
	})

	-- Register growing steps
	for i = 1, def.steps do
		local drop = {
			items = {
				{items = {mname .. ":" .. pname}, rarity = 9 - i},
				{items = {mname .. ":" .. pname}, rarity= 18 - i * 2},
				{items = {mname .. ":seed_" .. pname}, rarity = 9 - i},
				{items = {mname .. ":seed_" .. pname}, rarity = 18 - i * 2},
			}
		}
		local nodegroups = utility.dig_groups("crop", {flammable = 2, plant = 1, not_in_creative_inventory = 1, attached_node = 1, notify_destruct = 1})
		nodegroups[pname] = i

		local next_plant = nil

		if i < def.steps then
			next_plant = mname .. ":" .. pname .. "_" .. (i + 1)
		end

		minetest.register_node(mname .. ":" .. pname .. "_" .. i, {
			drawtype = "plantlike",
			waving = 1,
			tiles = {mname .. "_" .. pname .. "_" .. i .. ".png"},
			paramtype = "light",
      paramtype2 = def.paramtype2 or nil,
			place_param2 = def.place_param2 or nil,
			walkable = false,
			buildable_to = true,
			drop = drop,
			selection_box = {
				type = "fixed",
				fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
			},
			groups = nodegroups,
			sounds = default.node_sound_leaves_defaults(),
			next_plant = next_plant,
			on_timer = farming.grow_plant,
			minlight = def.minlight,
			maxlight = def.maxlight,
			movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

			-- Pass through flowerpot data if available.
			flowerpot_drop = def.flowerpot_drop,
		})
	end

	-- Return
	local r = {
		seed = mname .. ":seed_" .. pname,
		harvest = mname .. ":" .. pname
	}
	return r
end
