
minetest.register_craft({
    output = "morechests:woodchest_public",
    recipe = {
        {"group:wood_dark", "group:wood_dark", "group:wood_dark"},
        {"group:wood_dark", "",                "group:wood_dark"},
        {"group:wood_dark", "group:wood_dark", "group:wood_dark"},
    }
})

minetest.register_craft({
    output = "morechests:woodchest_locked",
    recipe = {
        {"group:wood_dark", "group:wood_dark",    "group:wood_dark"},
        {"group:wood_dark", "group:ingot",        "group:wood_dark"},
        {"group:wood_dark", "group:wood_dark",    "group:wood_dark"},
    }
})

minetest.register_craft( {
	type = "shapeless",
	output = "morechests:woodchest_locked",
	recipe = {"morechests:woodchest", "group:ingot"},
})



-- Helper function to reduce code duplication.
local register_metal_chest = function(ingot, chestpublic, chestlocked)
    minetest.register_craft({
        output = chestpublic,
        recipe = {
            {ingot,    ingot,                           ingot},
            {ingot,    "morechests:woodchest_public",   ingot},
            {ingot,    ingot,                           ingot},
        }
    })

    minetest.register_craft({
        output = chestpublic,
        recipe = {
            {ingot,    ingot,                   ingot},
            {ingot,    "chests:chest_public",   ingot},
            {ingot,    ingot,                   ingot},
        }
    })

    minetest.register_craft({
        output = chestlocked,
        recipe = {
            {ingot,    ingot,                           ingot},
            {ingot,    "morechests:woodchest_locked",   ingot},
            {ingot,    ingot,                           ingot},
        }
    })

    minetest.register_craft({
        output = chestlocked,
        recipe = {
            {ingot,    ingot,                   ingot},
            {ingot,    "chests:chest_locked",   ingot},
            {ingot,    ingot,                   ingot},
        }
    })

    minetest.register_craft( {
        type = "shapeless",
        output = chestlocked,
        recipe = {chestpublic, "group:ingot"},
    })
end



-- Metalic chests crafts.
register_metal_chest("default:copper_ingot",    "morechests:copperchest_public",    "morechests:copperchest_locked")
register_metal_chest("cast_iron:ingot",         "morechests:ironchest_public",      "morechests:ironchest_locked")
register_metal_chest("default:gold_ingot",      "morechests:goldchest_public",      "morechests:goldchest_locked")
register_metal_chest("moreores:silver_ingot",   "morechests:silverchest_public",    "morechests:silverchest_locked")
register_metal_chest("moreores:mithril_ingot",  "morechests:mithrilchest_public",   "morechests:mithrilchest_locked")




