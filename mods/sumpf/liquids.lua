
local ani = {type="vertical_frames", aspect_w=16, aspect_h=16, length=1.5}--17
minetest.register_node("sumpf:dirtywater_flowing", {
	drawtype = "flowingliquid",
	tiles = {"default_water.png"},
	special_tiles = {
		{name="sumpf_water_flowing.png", backface_culling=false,	animation=ani},
		{name="sumpf_water_flowing.png", backface_culling=true,	animation=ani}
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	drop = "",
	liquidtype = "flowing",
	liquid_alternative_flowing = "sumpf:dirtywater_flowing",
	liquid_alternative_source = "sumpf:dirtywater_source",
	liquid_viscosity = 1,
	post_effect_color = {a=64, r=70, g=90, b=120},
	groups = {water=3, liquid=3, puts_out_fire=1, not_in_creative_inventory=1},
})

minetest.register_node("sumpf:dirtywater_source", {
	description = "swampwater",
	drawtype = "liquid",
	tiles = {
		{name="sumpf_water_source.png", animation=ani},
		{name="sumpf_water_source.png", animation=ani},
		{name="sumpf_water_flowing.png", animation=ani}
	},
	special_tiles = {{name="sumpf_water_source.png", animation=ani, backface_culling=false},},
	use_texture_alpha = "blend",
	paramtype = "light",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	liquidtype = "source",
	liquid_alternative_flowing = "sumpf:dirtywater_flowing",
	liquid_alternative_source = "sumpf:dirtywater_source",
	liquid_viscosity = 1,
	post_effect_color = {a=64, r=70, g=90, b=120},
	groups = {water=3, liquid=3, puts_out_fire=1},
})

if minetest.global_exists("bucket") then
	bucket.register_liquid(
		"sumpf:dirtywater_source",
		"sumpf:dirtywater_flowing",
		"sumpf:bucket_dirtywater",
		"bucket.png^sumpf_bucket_dirtywater.png",
		"swampwater bucket"
	)
end
