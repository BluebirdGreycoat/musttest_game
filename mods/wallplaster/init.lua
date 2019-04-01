
-- Wallplaster by Nakilashiva
-- All code and textures by Nakilashiva with SOME help from MustTest
-- (Aside from initial texture taken from google heh heh heh.)

local items = {
  {name="white", capitalized="White"},
  {name="blue", capitalized="Blue"},
  {name="pink", capitalized="Pink"},
  {name="yellow", capitalized="Yellow"},
  {name="grey", capitalized="Grey"},
  {name="green", capitalized="Green"},
  {name="orange", capitalized="Orange"},
  {name="purple", capitalized="Purple"},
}

for k, v in ipairs(items) do
  minetest.register_node("wallplaster:" .. v.name, {
		description = v.capitalized .. " Wall Plaster",
		tiles = {"wallplaster_" .. v.name .. ".png"},
		groups = utility.dig_groups("wood", {flammable = 3}),
		sounds = default.node_sound_wood_defaults(),
  })

	stairs.register_stair_and_slab(
		"wallplaster_" .. v.name,
		"wallplaster:" .. v.name,
		utility.dig_groups("wood", {flammable = 3}),
		{"wallplaster_" .. v.name .. ".png"},
		v.capitalized .. " Wall Plaster",
		default.node_sound_wood_defaults()
	)
end



local crafts = {
  {name="white", dye="white"},
  {name="blue", dye="cyan"},
  {name="pink", dye="pink"},
  {name="yellow", dye="yellow"},
  {name="grey", dye="grey"},
  {name="green", dye="green"},
  {name="orange", dye="orange"},
  {name="purple", dye="violet"},
}

for k, v in ipairs(crafts) do
  minetest.register_craft({
		output = 'wallplaster:' .. v.name,
		type = "shapeless",
		recipe = {'basictrees:aspen_wood', 'default:clay_lump', "dye:" .. v.dye}
  })
end
