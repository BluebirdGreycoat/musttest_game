
minetest.register_tool("moreores:pick_silver", {
	description = "Silver Pickaxe\n\nUse this pick to gently excavate things.",
	inventory_image = "moreores_tool_silverpick.png",
	tool_capabilities = tooldata["pick_silver"],
    sounds = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool("moreores:pick_mithril", {
	description = "Mithril Pickaxe",
	inventory_image = "moreores_tool_mithrilpick.png",
	tool_capabilities = tooldata["pick_mithril"],
    sounds = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool("moreores:shovel_silver", {
	description = "Silver Shovel",
	inventory_image = "moreores_tool_silvershovel.png",
	tool_capabilities = tooldata["shovel_silver"],
    sounds = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool("moreores:shovel_mithril", {
	description = "Mithril Shovel",
	inventory_image = "moreores_tool_mithrilshovel.png",
	tool_capabilities = tooldata["shovel_mithril"],
    sounds = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool("moreores:axe_silver", {
	description = "Silver Axe",
	inventory_image = "moreores_tool_silveraxe.png",
	tool_capabilities = tooldata["axe_silver"],
	sounds = {
		breaks = "basictools_tool_breaks",
		punch_use_air = "sword_swipe_metal",
		_punch_mob = "sword_flesh",
	},
})

minetest.register_tool("moreores:axe_mithril", {
	description = "Mithril Axe",
	inventory_image = "moreores_tool_mithrilaxe.png",
	tool_capabilities = tooldata["axe_mithril"],
	sounds = {
		breaks = "basictools_tool_breaks",
		punch_use_air = "sword_swipe_metal",
		_punch_mob = "sword_flesh",
	},
})

minetest.register_tool("moreores:sword_silver", {
	description = "Silver Sword",
	inventory_image = "moreores_tool_silversword.png",
	tool_capabilities = tooldata["sword_silver"],
	sounds = {
		breaks = "basictools_tool_breaks",
		punch_use_air = "sword_swipe_metal",
		_punch_mob = "sword_flesh",
	},
})

minetest.register_tool("moreores:sword_mithril", {
	description = "Mithril Sword",
	inventory_image = "moreores_tool_mithrilsword.png",
	tool_capabilities = tooldata["sword_mithril"],
	sounds = {
		breaks = "basictools_tool_breaks",
		punch_use_air = "sword_swipe_metal",
		_punch_mob = "sword_flesh",
	},
})

farming.register_hoe("moreores:hoe_silver", {
	description = "Silver Hoe",
	inventory_image = "moreores_tool_silverhoe.png",
	max_uses = 300,
	material = "moreores:silver_ingot"
})

farming.register_hoe("moreores:hoe_mithril", {
	description = "Mithril Hoe",
	inventory_image = "moreores_tool_mithrilhoe.png",
	max_uses = 600,
	material = "moreores:mithril_ingot"
})

minetest.register_craft({
    output = "moreores:pick_silver",
    recipe = {
        {"moreores:silver_ingot", "moreores:silver_ingot", "moreores:silver_ingot"},
        {"", "group:stick", ""},
        {"", "group:stick", ""},
    },
})

minetest.register_craft({
    output = "moreores:pick_mithril",
    recipe = {
        {"moreores:mithril_ingot", "moreores:mithril_ingot", "moreores:mithril_ingot"},
        {"", "group:stick", ""},
        {"", "group:stick", ""},
    },
})

minetest.register_craft({
    output = "moreores:axe_silver",
    recipe = {
        {"moreores:silver_ingot", "moreores:silver_ingot", ""},
        {"moreores:silver_ingot", "group:stick", ""},
        {"", "group:stick", ""},
    },
})

minetest.register_craft({
    output = "moreores:axe_silver",
    recipe = {
        {"moreores:silver_ingot", "moreores:silver_ingot", ""},
        {"group:stick", "moreores:silver_ingot", ""},
        {"group:stick", "", ""},
    },
})

minetest.register_craft({
    output = "moreores:axe_mithril",
    recipe = {
        {"moreores:mithril_ingot", "moreores:mithril_ingot", ""},
        {"moreores:mithril_ingot", "group:stick", ""},
        {"", "group:stick", ""},
    },
})

minetest.register_craft({
    output = "moreores:axe_mithril",
    recipe = {
        {"moreores:mithril_ingot", "moreores:mithril_ingot", ""},
        {"group:stick", "moreores:mithril_ingot", ""},
        {"group:stick", "", ""},
    },
})

minetest.register_craft({
    output = "moreores:shovel_silver",
    recipe = {
        {"", "moreores:silver_ingot", ""},
        {"", "group:stick", ""},
        {"", "group:stick", ""},
    },
})

minetest.register_craft({
    output = "moreores:shovel_mithril",
    recipe = {
        {"", "moreores:mithril_ingot", ""},
        {"", "group:stick", ""},
        {"", "group:stick", ""},
    },
})

minetest.register_craft({
    output = "moreores:sword_silver",
    recipe = {
        {"", "moreores:silver_ingot", ""},
        {"", "moreores:silver_ingot", ""},
        {"", "group:stick", ""},
    },
})

minetest.register_craft({
    output = "moreores:sword_mithril",
    recipe = {
        {"", "moreores:mithril_ingot", ""},
        {"", "moreores:mithril_ingot", ""},
        {"", "group:stick", ""},
    },
})


