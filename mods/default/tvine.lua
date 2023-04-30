
-- Twisted Vine Mod
-- Idea and textures by alauer/Dresdan
-- Code by MustTest

if not minetest.global_exists("tvine") then tvine = {} end
tvine.modpath = minetest.get_modpath("default")
tvine.steptime = {min=60*5, max=60*20}
--tvine.steptime = {min=1, max=1}
tvine.maxheight = 16
tvine.minlight = 10
tvine.maxlight = 15
tvine.light_source = 9

-- Localize for performance.
local math_floor = math.floor
local math_random = math.random

function tvine.is_plant_name(name)
    if name == "default:tvine" then
        return true
    elseif name == "default:tvine_alt" then
        return true
    elseif name == "default:tvine_top" then
        return true
    elseif name == "default:tvine_top_alt" then
        return true
    end
    
    return false
end

function tvine.is_stalk_name(name)
    if name == "default:tvine" then
        return true
    elseif name == "default:tvine_alt" then
        return true
    end
    
    return false
end

function tvine.is_top_name(name)
    if name == "default:tvine_top" then
        return true
    elseif name == "default:tvine_top_alt" then
        return true
    end
    
    return false
end

-- Should return a random height for an individual plant to grow.
function tvine.random_height()
	local m = tvine.maxheight
	local h = math_floor(m / 2)
	local x = 2
	if h < x then h = x end
	if m < h then m = h end
	return math_floor(math_random(math_random(x, h), math_random(h, m)))
end

function tvine.is_dirt_name(name)
	if name == "default:dirt_with_grass" or 
        name == "default:dirt" or 
        name == "moregrass:darkgrass" or 
        name == "talinite:ore" or
        name == "talinite:desert_ore" or
        minetest.get_item_group(name, "soil") > 1 then
		return true
	end
end

function tvine.has_dirt(pos)
	local p = vector.add(pos, {x=0, y=-1, z=0})
	local name = minetest.get_node(p).name
	-- Must be on dirt or grass.
	if tvine.is_dirt_name(name) then
		return true
	end
end

function tvine.can_grow(pos)
	-- Must have dirt nearby.
	if not tvine.has_dirt(pos) then
		return
	end

	-- Must have water nearby.
	local p = vector.add(pos, {x=0, y=-1, z=0})
	if not minetest.find_node_near(p, 3, {"group:water"}) then
		return
	end

	-- Also needs minerals.
	if not minetest.find_node_near(p, 3, {"glowstone:minerals"}) then
		return
	end

	return true
end

-- Obtain growth height from soil, initializing it if not done yet.
function tvine.get_grow_height(pos)
	local meta = minetest.get_meta({x=pos.x, y=pos.y-1, z=pos.z})
	local maxh = meta:get_int("tvine_height")
	if maxh == 0 then
		maxh = tvine.random_height()
		meta:set_int("tvine_height", maxh)
		meta:mark_as_private("tvine_height")
	end
	return maxh
end

-- Should be called when plant is dug.
function tvine.reset_grow_height_and_timer(pos)
	-- Find soil node below plant.
	local p = vector.new(pos)
	local name = minetest.get_node(p).name
	local d = 0
	while not tvine.is_dirt_name(name) and d < tvine.maxheight do
		-- All except bottom-most node must be plant.
		if not tvine.is_plant_name(name) then
			return
		end
		p.y = p.y - 1
		d = d + 1
		name = minetest.get_node(p).name
	end
	-- Must be on dirt or grass.
	if tvine.is_dirt_name(name) then
		local meta = minetest.get_meta(p)
		local maxh = tvine.random_height()
		meta:set_int("tvine_height", maxh)
		meta:mark_as_private("tvine_height")
	else
		return
	end
	-- Restart timer for plant directly above soil.
	p.y = p.y + 1
	if not tvine.is_plant_name(minetest.get_node(p).name) then
		return
	end
	local min = tvine.steptime.min
	local max = tvine.steptime.max
	minetest.get_node_timer(p):start(math_random(min, max))
end

-- Attempt to grow tvine.
-- Return 0 means nothing to report.
-- 10 means plant has reached max height.
function tvine.grow(pos, node)
	-- Check if we can grow.
	if not tvine.can_grow(pos) then
		return 0
	end

	if minetest.find_node_near(pos, 2, "group:cold") then
		return 12
	end

	-- Get how high we can grow.
	local maxh = tvine.get_grow_height(pos)
	-- Find current height of plant.
	local height = 0
	while tvine.is_plant_name(node.name) and height < maxh do
		height = height + 1
		pos.y = pos.y + 1
		node = minetest.get_node(pos)
	end
	if height >= maxh then
		-- Plant has reached max height.
		return 10
	end
	-- Check if we have room to grow some more.
	if not (node.name == "air") then
		return 0
	end
	-- Check if we have enough light.
	if minetest.get_node_light(pos) < tvine.minlight then
		return 0
	end
    
	-- Grow!
	local p2 = {x=pos.x, y=pos.y-1, z=pos.z}
	local n2 = minetest.get_node(p2)
	if tvine.is_plant_name(n2.name) then
			minetest.swap_node(p2, {name = tvine.chose_bot_name(p2), param2=n2.param2})
	end
	minetest.swap_node(pos, {name = tvine.chose_top_name(pos), param2=n2.param2})
    
	return 0
end

function tvine.chose_name(pos)
    local p = {x=pos.x, y=pos.y-1, z=pos.z}
    local n = minetest.get_node(p).name
    
    if n == "default:tvine" then
        return "default:tvine_alt"
    elseif n == "default:tvine_alt" then
        return "default:tvine"
    end
    
    return "default:tvine"
end

function tvine.chose_top_name(pos)
    local p = {x=pos.x, y=pos.y-1, z=pos.z}
    local n = minetest.get_node(p).name
    
    if n == "default:tvine" then
        return "default:tvine_top_alt"
    elseif n == "default:tvine_alt" then
        return "default:tvine_top"
    end
    
    return "default:tvine"
end

function tvine.chose_bot_name(pos)
    local p = {x=pos.x, y=pos.y-1, z=pos.z}
    local n = minetest.get_node(p).name
    
    if n == "default:tvine" then
        return "default:tvine_alt"
    elseif n == "default:tvine_alt" then
        return "default:tvine"
    elseif n == "default:tvine_top" then
        return "default:tvine_alt"
    elseif n == "default:tvine_top_alt" then
        return "default:tvine"
    end
    
    if math_random(1, 2) == 1 then
        return "default:tvine"
    end
    return "default:tvine_alt"
end

function tvine.on_construct(pos)
	local p = {x=pos.x, y=pos.y-1, z=pos.z}
	local n = minetest.get_node(p)

	if not tvine.is_plant_name(n.name) then
		if math_random(1, 2) == 1 then
			minetest.swap_node(pos, {name="default:tvine_top", param2=math_random(0, 239)})
		else
			minetest.swap_node(pos, {name="default:tvine_top_alt", param2=math_random(0, 239)})
		end
	else
		local n2 = minetest.get_node(pos)
		n2.param2 = n.param2
		minetest.swap_node(pos, n2)
	end
end

function tvine.on_seed_timer(pos, elapsed)
	if math_random(1, 2) == 1 then
		minetest.set_node(pos, {name = "default:tvine_top"})
	else
		minetest.set_node(pos, {name = "default:tvine_top_alt"})
	end

	-- Only the ground-level plant piece should have nodetimer.
	-- If plant is not placed on soil, it will never have nodetimer.
	if tvine.has_dirt(pos) then
		local min = tvine.steptime.min
		local max = tvine.steptime.max
		minetest.get_node_timer(pos):start(math_random(min, max))
	end
end

function tvine.on_destruct(pos)
	tvine.reset_grow_height_and_timer(pos)
end

function tvine.on_timer(pos, elapsed)
	--minetest.chat_send_all("# Server: Plant timer @ " .. minetest.pos_to_string(pos) .. "!")
	local p = vector.new(pos)
	local node = minetest.get_node(pos)
	local result = tvine.grow(pos, node)
	-- Plant has reached max height.
	if result == 10 then return end
	-- Plant cannot grow because of ice.
	if result == 12 then return end

	local min = tvine.steptime.min
	local max = tvine.steptime.max
	minetest.get_node_timer(p):start(math_random(min, max))
	--return true
end

function tvine.after_dig_node(pos, node, metadata, digger)
	tvine.dig_up(pos, node, digger)
	-- No return value.
end

function tvine.dig_up(pos, node, digger)
  if digger == nil then return end
  local np = {x = pos.x, y = pos.y + 1, z = pos.z}
  local nn = minetest.get_node(np)
  if tvine.is_plant_name(nn.name) then
    minetest.node_dig(np, nn, digger)
  end
end

function tvine.on_display_construct(pos)
	local n = minetest.get_node(pos)
	n.param2 = math_random(0, 239)
	minetest.swap_node(pos, n)
end

if not tvine.run_once then
	-- This version is for display only - does not grow or provide seeds.
	minetest.register_node("default:tvine_display", {
		description = "Twisted Vine",
		drawtype = "plantlike",
		tiles = {"default_tvine_display.png"},
		inventory_image = "default_tvine_display.png",
		wield_image = "default_tvine_display.png",
		paramtype = "light",
		paramtype2 = "degrotate",
		sunlight_propagates = true,
		light_source = tvine.light_source,
		walkable = false,
		waving = 1,
		-- Manually placed vines are not climbable.
		selection_box = {
			type = "fixed",
			fixed = {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3}
		},
		groups = utility.dig_groups("plant", {flammable = 2}),
		sounds = default.node_sound_leaves_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

		on_construct = function(...) return tvine.on_display_construct(...) end,
	})

	minetest.register_node("default:tvine_seed", {
		description = "Twisted Vine Seed",
		tiles = {"tvine_seed.png"},
		wield_image = "tvine_seed.png",
		inventory_image = "tvine_seed.png",
		drawtype = "signlike",
		paramtype = "light",
		paramtype2 = "wallmounted",
		walkable = false,
		sunlight_propagates = true,
		selection_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5}
		},
		groups = utility.dig_groups("seeds", {seed = 1, attached_node = 1, flammable = 2, notify_destruct = 1}),
		on_place = function(itemstack, placer, pointed_thing)
			return farming.place_seed(itemstack, placer, pointed_thing, "default:tvine_seed")
		end,
		soil_nodes = {
			"default:dirt_with_grass",
			"default:dirt",
			"moregrass:darkgrass",
			"talinite:ore",
			"talinite:desert_ore",
		},
		on_timer = function(...) return farming.grow_plant(...) end,
		minlight = tvine.minlight,
		maxlight = tvine.maxlight,
		_farming_next_plant = {"default:tvine_stunted"},
		sounds = default.node_sound_dirt_defaults({
			dug = {name = "default_grass_footstep", gain = 0.2},
			place = {name = "default_place_node", gain = 0.25},
		}),
		farming_minerals_unused = true,
	})

	-- This version provides seeds!
	minetest.register_node("default:tvine_stunted", {
		description = "Twisted Vine (Hacker!)",
		drawtype = "plantlike",
		tiles = {"default_tvine_display.png"},
		inventory_image = "default_tvine.png",
		wield_image = "default_tvine.png",
		paramtype = "light",
		paramtype2 = "degrotate",
		sunlight_propagates = true,
		light_source = tvine.light_source,
		walkable = false,
		waving = 1,
		-- Manually placed vines are not climbable.
		selection_box = {
			type = "fixed",
			fixed = {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3}
		},
		drop = "default:tvine_seed",
		groups = utility.dig_groups("plant", {flammable = 2}),
		sounds = default.node_sound_leaves_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

		_farming_next_plant = {"default:tvine_top", "default:tvine_top_alt"},
		on_timer = function(...) return farming.grow_plant(...) end,
		minlight = tvine.minlight,
		maxlight = tvine.maxlight,
		soil_nodes = {
			"default:dirt_with_grass",
			"default:dirt",
			"moregrass:darkgrass",
			"talinite:ore",
			"talinite:desert_ore",
		},
		farming_minerals_unused = true,
		farming_growing_time_min = 60*10,
		farming_growing_time_max = 60*40,

		on_collapse_to_entity = function(pos, node)
			minetest.add_item(pos, {name="default:tvine_display"})
		end,
	})

	stalk_drops = {
		max_items = 1,
		items = {
			{items = {'talinite:dust'}, rarity = 2},
		},
	}

	minetest.register_node("default:tvine", {
		description = "Twisted Vine (Hacker!)",
		drawtype = "plantlike",
		tiles = {"default_tvine.png"},
		inventory_image = "default_tvine.png",
		wield_image = "default_tvine.png",
		paramtype = "light",
		paramtype2 = "degrotate",
		sunlight_propagates = true,
		light_source = tvine.light_source,
		walkable = false,
		climbable = true,
		drop = stalk_drops,
		selection_box = {
			type = "fixed",
			fixed = {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3}
		},
		groups = utility.dig_groups("plant", {flammable = 2}),
		sounds = default.node_sound_leaves_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

		on_construct = function(...)
			return tvine.on_construct(...)
		end,

		on_destruct = function(...)
			return tvine.on_destruct(...)
		end,

		on_timer = function(...)
			return tvine.on_timer(...)
		end,

		after_dig_node = function(...)
			return tvine.after_dig_node(...)
		end,

		on_finish_collapse = function(pos, node)
			minetest.swap_node(pos, {name="default:tvine_display", param2=math_random(0, 239)})
		end,

		on_collapse_to_entity = function(pos, node)
			minetest.add_item(pos, {name="default:tvine_display"})
		end,
	})

	minetest.register_node("default:tvine_alt", {
		description = "Twisted Vine (Hacker!)",
		drawtype = "plantlike",
		tiles = {"default_tvine_alt.png"},
		inventory_image = "default_tvine.png",
		wield_image = "default_tvine.png",
		paramtype = "light",
		paramtype2 = "degrotate",
		sunlight_propagates = true,
		light_source = tvine.light_source,
		walkable = false,
		climbable = true,
		drop = stalk_drops,
		selection_box = {
			type = "fixed",
			fixed = {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3}
		},
		groups = utility.dig_groups("plant", {flammable = 2}),
		sounds = default.node_sound_leaves_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

		on_construct = function(...)
			return tvine.on_construct(...)
		end,

		on_destruct = function(...)
			return tvine.on_destruct(...)
		end,

		on_timer = function(...)
			return tvine.on_timer(...)
		end,

		after_dig_node = function(...)
			return tvine.after_dig_node(...)
		end,

		on_finish_collapse = function(pos, node)
			minetest.swap_node(pos, {name="default:tvine_display", param2=math_random(0, 239)})
		end,

		on_collapse_to_entity = function(pos, node)
			minetest.add_item(pos, {name="default:tvine_display"})
		end,
	})

	top_drops = {
		max_items = 2,
		items = {
			{items = {'default:tvine_display'}, rarity = 5},
			{items = {'default:tvine_seed'}},
			{items = {'default:tvine_seed'}, rarity = 10},
		},
	}

	minetest.register_node("default:tvine_top", {
		description = "Twisted Vine (Hacker!)",
		drawtype = "plantlike",
		tiles = {"default_tvine_top.png"},
		inventory_image = "default_tvine.png",
		wield_image = "default_tvine.png",
		paramtype = "light",
		paramtype2 = "degrotate",
		sunlight_propagates = true,
		light_source = tvine.light_source,
		walkable = false,
		waving = 1,
		drop = top_drops,
		selection_box = {
			type = "fixed",
			fixed = {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3}
		},
		groups = utility.dig_groups("plant", {flammable = 2}),
		sounds = default.node_sound_leaves_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

		on_construct = function(...)
			return tvine.on_construct(...)
		end,

		on_destruct = function(...)
			return tvine.on_destruct(...)
		end,

		on_timer = function(...)
			return tvine.on_timer(...)
		end,

		after_dig_node = function(...)
			return tvine.after_dig_node(...)
		end,

		on_finish_collapse = function(pos, node)
			minetest.swap_node(pos, {name="default:tvine_display", param2=math_random(0, 239)})
		end,

		on_collapse_to_entity = function(pos, node)
			minetest.add_item(pos, {name="default:tvine_display"})
		end,

		-- Instruct farming mod to restart the timer.
		-- Otherwise, after growing the last plant, the timer would halt.
		_farming_restart_timer = true,
		farming_growing_time_min = tvine.steptime.min,
		farming_growing_time_max = tvine.steptime.max,
	})

	minetest.register_node("default:tvine_top_alt", {
		description = "Twisted Vine (Hacker!)",
		drawtype = "plantlike",
		tiles = {"default_tvine_top_alt.png"},
		inventory_image = "default_tvine.png",
		wield_image = "default_tvine.png",
		paramtype = "light",
		paramtype2 = "degrotate",
		sunlight_propagates = true,
		light_source = tvine.light_source,
		walkable = false,
		waving = 1,
		drop = top_drops,
		selection_box = {
			type = "fixed",
			fixed = {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3}
		},
		groups = utility.dig_groups("plant", {flammable = 2}),
		sounds = default.node_sound_leaves_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

		on_construct = function(...)
			return tvine.on_construct(...)
		end,

		on_destruct = function(...)
			return tvine.on_destruct(...)
		end,

		on_timer = function(...)
			return tvine.on_timer(...)
		end,

		after_dig_node = function(...)
			return tvine.after_dig_node(...)
		end,

		on_finish_collapse = function(pos, node)
			minetest.swap_node(pos, {name="default:tvine_display", param2=math_random(0, 239)})
		end,

		on_collapse_to_entity = function(pos, node)
			minetest.add_item(pos, {name="default:tvine_display"})
		end,

		-- Instruct farming mod to restart the timer.
		-- Otherwise, after growing the last plant, the timer would halt.
		_farming_restart_timer = true,
		farming_growing_time_min = tvine.steptime.min,
		farming_growing_time_max = tvine.steptime.max,
	})

	minetest.register_craft({
		type = "extracting",
		output = 'talinite:dust 4',
		recipe = 'default:tvine_display',
		time = 5,
	})

	local c = "tvine:core"
	local f = tvine.modpath .. "/tvine.lua"
	reload.register_file(c, f, false)

	tvine.run_once = true
end
