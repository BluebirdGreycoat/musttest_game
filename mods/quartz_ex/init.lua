
-- Stairs & Slabs
stairs.register_stair_and_slab("quartzblock", "quartz:block",
		{level=1, cracky=3},
		{"quartz_block.png"},
		"Quartz",
		default.node_sound_glass_defaults())

stairs.register_stair_and_slab("chiseledquartzblock", "quartz:chiseled",
		{level=1, cracky=3},
		{"quartz_chiseled.png"},
		"Chiseled Quartz",
		default.node_sound_glass_defaults())

stairs.register_stair_and_slab("quartzstair", "quartz:pillar",
		{level=1, cracky=3},
		{"quartz_pillar_top.png", "quartz_pillar_top.png", "quartz_pillar_side.png"},
		"Quartz Pillar",
		default.node_sound_glass_defaults())


walls.register(
	"quartz_block",
	"Quartz",
	"quartz_block.png",
	"quartz:block",
	default.node_sound_glass_defaults()
)

walls.register(
	"quartz_chiseled",
	"Chiseled Quartz",
	"quartz_chiseled.png",
	"quartz:chiseled",
	default.node_sound_glass_defaults()
)

walls.register(
	"quartz_pillar",
	"Grooved Quartz",
	"quartz_pillar_side.png",
	"quartz:pillar",
	default.node_sound_glass_defaults()
)





