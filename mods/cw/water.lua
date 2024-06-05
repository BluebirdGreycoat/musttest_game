
-- Basically just a copy of regular water, with damage_per_second.
local sdef = table.copy(minetest.registered_nodes["default:water_source"])
local fdef = table.copy(minetest.registered_nodes["default:water_flowing"])

sdef.damage_per_second = 1*500
fdef.damage_per_second = 1*500

sdef._damage_per_second_type = "fleshy"
fdef._damage_per_second_type = "fleshy"

sdef._death_message = "the piranha got <player>."
fdef._death_message = "the piranha got <player>."

sdef.liquid_alternative_flowing = "cw:water_flowing"
sdef.liquid_alternative_source = "cw:water_source"

fdef.liquid_alternative_flowing = "cw:water_flowing"
fdef.liquid_alternative_source = "cw:water_source"

minetest.register_node("cw:water_source", sdef)
minetest.register_node("cw:water_flowing", fdef)
