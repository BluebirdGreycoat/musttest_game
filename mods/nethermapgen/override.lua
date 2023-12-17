
-- Prevent the carving of water/lava caves in these materials.
minetest.override_item("rackstone:rackstone", {
  is_ground_content = false,
})
minetest.override_item("rackstone:redrack", {
  is_ground_content = false,
})

-- We need 2 types of nether stone, 1 type for below the brimstone ocean,
-- and the second type for the nether above. The second type allows caves
-- to be carved through it. That is the main reason for having a new
-- node definition.

-- Make a mapgen-specific copy of this nodetype.
local rdef = table.copy(minetest.registered_nodes["rackstone:redrack"])
rdef.is_ground_content = true
rdef._is_bulk_mapgen_stone = true
rdef.drop = "rackstone:redrack_cobble"
rdef.after_place_node = function(pos) -- In case player manages to obtain.
  minetest.swap_node(pos, {name="rackstone:redrack_cobble"})
end

--[[
	rdef.drawtype = "airlike"
	rdef.paramtype = "light"
	rdef.sunlight_propagates = true
	rdef.light_source = 15
	rdef.pointable = false
--]]

minetest.register_node(":rackstone:mg_redrack", rdef)

-- Make a mapgen-specific copy of this nodetype.
local ddef = table.copy(minetest.registered_nodes["rackstone:rackstone"])
ddef.is_ground_content = true
ddef._is_bulk_mapgen_stone = true
ddef.drop = "rackstone:cobble"
ddef.after_place_node = function(pos) -- In case player manages to obtain.
  minetest.swap_node(pos, {name="rackstone:cobble"})
end
minetest.register_node(":rackstone:mg_rackstone", ddef)

