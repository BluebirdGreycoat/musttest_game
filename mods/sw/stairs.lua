
-- Basic stair and slab nodes ONLY.
-- We must conserve content IDs!

stairs.register_stair_and_slab(
	"sw_teststone1",
	"sw:teststone1",
	utility.dig_groups("obsidian"),
	{{name="sw_teststone_1.png", align_style="world", scale=4}},
	"Irx Stone",
	default.node_sound_stone_defaults(),
	{stair_and_slab_only=true}
)

stairs.register_stair_and_slab(
	"sw_teststone2",
	"sw:teststone2",
	utility.dig_groups("stone"),
	{{name="sw_teststone_2.png", align_style="world", scale=4}},
	"Fractured Irx",
	default.node_sound_stone_defaults(),
	{stair_and_slab_only=true}
)

stairs.register_stair_and_slab(
	"sw_teststone1brick",
	"sw:teststone1brick",
	utility.dig_groups("hardstone"),
    {{name="xen_stone_brick.png"}},
	"Irx Brick",
	default.node_sound_stone_defaults(),
	{stair_and_slab_only=true}
)

stairs.register_stair_and_slab(
	"sw_teststone1block",
	"sw:teststone1block",
	utility.dig_groups("hardstone"),
	{{name="xen_stone_block.png"}},
	"Irx Block",
	default.node_sound_stone_defaults(),
	{stair_and_slab_only=true}
)