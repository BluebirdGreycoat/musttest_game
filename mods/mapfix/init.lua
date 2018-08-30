
mapfix = mapfix or {}
mapfix.modpath = minetest.get_modpath("mapfix")

mapfix.do_mapfix = function(minp, maxp)
  local vm = minetest.get_voxel_manip(minp, maxp)
  vm:update_liquids()
  vm:write_to_map()
  vm:update_map()
end

local previous = os.time()

-- Settings.
local default_size = tonumber(minetest.setting_get("mapfix_default_size")) or 30
local max_size = tonumber(minetest.setting_get("mapfix_max_size")) or 50
local delay = tonumber(minetest.setting_get("mapfix_delay")) or 15

-- Function shall be callable from other mods.
mapfix.do_command = function(name, param)
  local pos = minetest.get_player_by_name(name):getpos()
  local size = tonumber(param) or default_size
  local privs = minetest.check_player_privs(name, {server=true})
  local time = os.time()

  if not privs then
    if size > max_size then
      minetest.chat_send_player(name, "# Server: You need privileges to exceed the radius of " .. max_size .. " meters.")
      return
    elseif time - previous < delay then
      minetest.chat_send_player(name, "# Server: Wait at least " .. math.ceil(delay) .. " seconds before running this command.")
      return
    end
    previous = time
  end

  local minp = vector.round(vector.subtract(pos, size - 0.5))
  local maxp = vector.round(vector.add(pos, size + 0.5))

  minetest.log("action", name .. " uses mapfix at " .. minetest.pos_to_string(vector.round(pos)) .. " with radius " .. size)
  mapfix.do_mapfix(minp, maxp)
  minetest.chat_send_player(name, "# Server: Liquid & light map update done!")
end

-- Allow players to use command from chat console.
minetest.register_chatcommand("mapfix", {
  params = "<size>",
  description = "Recalculate liquids and light in a mapchunk.",
  func = function(name, param)
    mapfix.do_command(name, param)
    return true
  end,
})
