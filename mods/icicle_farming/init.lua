
if not minetest.global_exists("icicle_farming") then icicle_farming = {} end
icicle_farming.modpath = minetest.get_modpath("icicle_farming")



local function can_grow(pos)
  -- Can't grow in nether, too hot so everything just melts.
  if pos.y < -22000 then return false end
  
  -- Grow underground, temperature is above freezing but not too hot.
  if pos.y < -48 then return true end
  
  -- If above-ground or near surface, then generally too cold,
  -- unless there is a heat-source nearby or at daytime.
  local light = minetest.get_node_light(pos)
  if not light then return false end -- Can't get light level.
      
  -- Light level 10 is chosen to be above the amount of light produced
  -- by glowing icicles. This way, glowing icicles do not count as a
  -- heat source. Players must use torches or better.
  if light >= 10 then return true end -- Grow in warmer area.
  
  return false -- Cannot grow.
end



local function grow_icicle(pos, node)
  if not can_grow(pos) then return end
  -- We've already determined that there is water nearby.
  local pbelow = {x=pos.x, y=pos.y-1, z=pos.z}
  local nbelow = minetest.get_node(pbelow)
  if nbelow.name == "air" then -- Grow icicle down.
    if minetest.find_node_near(pos, 1, "glowstone:minerals") then
      minetest.add_node(pbelow, {name="cavestuff:icicle_down_glowing"})
    else
      minetest.add_node(pbelow, {name="cavestuff:icicle_down"})
    end
  else -- Cannot grow below, try growing up.
    local pabove = {x=pos.x, y=pos.y+1, z=pos.z}
    local nabove = minetest.get_node(pabove)
    if nabove.name == "air" then -- Grow icicle up.
      if minetest.find_node_near(pos, 1, "glowstone:minerals") then
        minetest.add_node(pabove, {name="cavestuff:icicle_up_glowing"})
      else
        minetest.add_node(pabove, {name="cavestuff:icicle_up"})
      end
    end
  end
end



minetest.register_abm({
  label = "Grow Icicles",
  nodenames = {"ice:thin_ice"},
  neighbors = {"group:water"},
  interval = 20 * default.ABM_TIMER_MULTIPLIER,
  chance = 50 * default.ABM_CHANCE_MULTIPLIER,
  catch_up = false,
  action = grow_icicle,
})
