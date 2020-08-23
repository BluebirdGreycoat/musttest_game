
-- Base mese burntime.
-- Warning: this affects how much energy machines produce from mese.
local bmb = 60 -- Coal lumps burn for 40.

-- Localize for performance.
local math_floor = math.floor

minetest.register_craft({
  type = "mesefuel",
  recipe = 'default:mese_crystal_fragment',
  burntime = math_floor(bmb/12),
})

minetest.register_craft({
  type = "mesefuel",
  recipe = 'default:mese_crystal',
  burntime = bmb,
})

minetest.register_craft({
  type = "mesefuel",
  recipe = 'default:mese',
  burntime = math_floor(bmb*12),
})
