
local groups = utility.dig_groups("mineral", {glowmineral=1})

local nodes = {
	{name="glowstone_luxore", item="glowstone:luxore", texture="default_stone.png^glowstone_glowore.png", desc="Lux Ore", groups=groups},
	{name="glowstone_cobble", item="glowstone:cobble", texture="glowstone_cobble.png", desc="Sunstone Deposit", groups=groups},
	{name="glowstone_minerals", item="glowstone:minerals", texture="glowstone_minerals.png", desc="Radiant Minerals", groups=groups},
	{name="glowstone_glowtox", item="glowstone:glowstone", texture="glowstone_glowstone.png", desc="Toxic Glowstone", groups=groups},
}

for k, v in ipairs(nodes) do
	stairs.register_stair_and_slab(
		v.name,
		v.item,
		table.copy(v.groups),
		{v.texture},
		v.desc,
		default.node_sound_stone_defaults()
	)
end
