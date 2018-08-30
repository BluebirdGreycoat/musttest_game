
function mese_crystals.get_grow_time()
	return mese_crystals.growtime + math.random(1, 30)
	--return mese_crystals.growtime
end

function mese_crystals.get_long_grow_time()
	return mese_crystals.longgrowtime + math.random(1, 30)
	--return mese_crystals.longgrowtime
end



local check_lava = function(pos)
  local name = minetest.get_node(pos).name
  if minetest.get_item_group(name, "lava") > 0 then 
    return 1
  else
    return 0
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

  if node.name == "mese_crystals:mese_crystal_ore3" then
    node.name = "mese_crystals:mese_crystal_ore4"
    minetest.swap_node(pos, node)
		-- Last stage, does not need node timer.
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

