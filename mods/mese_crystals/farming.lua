
-- Localize for performance.
local math_random = math.random

-- For testing.
local FAST_CRYSTAL_GROWTH = false

-- Crystals are NOT plants, they're more "like" stony material.
-- They should take a long time to grow.
function mese_crystals.get_grow_time()
  if FAST_CRYSTAL_GROWTH then
    return 5
  end
	return 60*math.random(15, 30)
end
function mese_crystals.get_long_grow_time()
  if FAST_CRYSTAL_GROWTH then
    return 5
  end
	return 60*math.random(60, 120)
end



local check_lava = function(pos)
  local name = minetest.get_node(pos).name
  if minetest.get_item_group(name, "lava") > 0 then 
    return 1
  else
    return 0
  end
end



-- Get the location of a valid glow mineral.
local function get_glowminerals(pos)
  local t = {
    vector.offset(pos, 0, -2, 0),
    vector.offset(pos, 1, -1, 0),
    vector.offset(pos, -1, -1, 0),
    vector.offset(pos, 0, -1, 1),
    vector.offset(pos, 0, -1, -1),
  }

  for k = 1, #t do
    local n = minetest.get_node(t[k])
    if n.name == "glowstone:minerals" then
      return t[k]
    end
  end
end



local grow_mese_crystal_ore = function(pos, node)
	-- Crystals grown outside the nether should grow much slower.
	local nether = true
  if pos.y > -30770 then
		nether = false
	end

  local pos1 = {x = pos.x, y = pos.y, z = pos.z}
  pos1.y = pos1.y - 1
  local name = minetest.get_node(pos1).name
  if name ~= "default:obsidian" then
		-- Cannot grow, do not restart timer.
    return
  end

  local lava_count = 0
  pos1.z = pos.z - 1
  lava_count = lava_count + check_lava(pos1)
  pos1.z = pos.z + 1
  lava_count = lava_count + check_lava(pos1)
  pos1.z = pos.z
  pos1.x = pos.x - 1
  lava_count = lava_count + check_lava(pos1)
  pos1.x = pos.x + 1
  lava_count = lava_count + check_lava(pos1)
	pos1.x = pos.x
	pos1.y = pos1.y -1
	lava_count = lava_count + check_lava(pos1)

	-- Not enough lava!
  if lava_count < 2 then
		minetest.get_node_timer(pos):start(mese_crystals.get_long_grow_time())
    return
  end

	local keepgrowing = false

  if node.name == "mese_crystals:mese_crystal_ore4" then
    local gm = get_glowminerals(pos)
    if gm then
      node.name = "mese_crystals:mese_crystal_ore5"
      minetest.swap_node(pos, node)
      minetest.set_node(gm, {name="cavestuff:coal_dust"}) -- Black sand.
      minetest.check_single_for_falling(gm)
      -- Last stage, does not need node timer.
    end
  elseif node.name == "mese_crystals:mese_crystal_ore3" then
    node.name = "mese_crystals:mese_crystal_ore4"
    minetest.swap_node(pos, node)
		keepgrowing = true
  elseif node.name == "mese_crystals:mese_crystal_ore2" then
    node.name = "mese_crystals:mese_crystal_ore3"
    minetest.swap_node(pos, node)
		keepgrowing = true
  elseif node.name == "mese_crystals:mese_crystal_ore1" then
    node.name = "mese_crystals:mese_crystal_ore2"
    minetest.swap_node(pos, node)
		keepgrowing = true
  end

	if keepgrowing then
		if nether then
			minetest.get_node_timer(pos):start(mese_crystals.get_grow_time())
		else
			minetest.get_node_timer(pos):start(mese_crystals.get_long_grow_time())
		end
	end
end



function mese_crystals.on_timer(pos, elapsed)
	local node = minetest.get_node(pos)
	return grow_mese_crystal_ore(pos, node)
end

