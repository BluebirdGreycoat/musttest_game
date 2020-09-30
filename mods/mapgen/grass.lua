
local find_surface = function(xz, b, t)
  for j=t, b, -1 do
    local pos = {x=xz.x, y=j, z=xz.z}
    local n = minetest.get_node(pos).name
    if snow.is_snow(n) then
      local pb = {x=pos.x, y=pos.y-1, z=pos.z}
      local nb = minetest.get_node(pb).name
      if nb == "default:stone" then
        return pos, pb -- Position, position below.
      else
        break
      end
    elseif n == "default:stone" then
      break
    end
  end
end

local plants = {
	"default:junglegrass",
	"default:coarsegrass",
	"default:dry_grass_5",
	"default:grass_5",
	"pumpkin:plant_8",
	"tomato:plant_7",
	"carrot:plant_8",
	"blueberries:plant_4",
	"coffee_bush:plant_4",
	"raspberries:plant_4",
	"potatoes:potato_4",
	"onions:allium_sprouts_4",
	"cucumber:cucumber_4",
}

mapgen.generate_grass = function(minp, maxp, seed)
  -- Don't generate underground, don't generate in highlands.
  if maxp.y < -50 or minp.y > 300 then
    return
  end

  local pr = PseudoRandom(seed + 6402)
  local count = pr:next(1, 2)

  -- 1 in 2 chance per mapchunk.
  if count == 1 then
    local xz = {x=pr:next(minp.x, maxp.x), z=pr:next(minp.z, maxp.z)}
    local pos, posb = find_surface(xz, minp.y, maxp.y)

    -- Highlands only.
    if pos then
      if pos.y < 10 then return end
      local which = plants[pr:next(1, #plants)]

			--if which == "default:coarsegrass" then
			--	minetest.chat_send_all(minetest.pos_to_string(pos))
			--end

      minetest.set_node(posb, {name="default:mossycobble"})
      minetest.set_node(pos, {name=which})
    end
  end
end







