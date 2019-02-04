
teleports = teleports or {}



minetest.register_node("teleports:teleport", {
  description = "Teleport Machine\n\nWarning: device is sensitive to shocks.\nIt will be destroyed if dug.",
  drawtype = "normal",
  tiles = {"teleports_teleport_top.png"},
  groups = {
    cracky=2, level=3,
    immovable=1,
  },
  drop = 'default:diamond 8',
  sounds = default.node_sound_metal_defaults(),
  
  can_dig = function(...) return teleports.can_dig(...) end,
  after_place_node = function(...) return teleports.after_place_node(...) end,
  on_destruct = function(...) return teleports.on_destruct(...) end,
  on_punch = function(...) return teleports.on_punch(...) end,
  on_receive_fields = function(...) return teleports.on_receive_fields(...) end,
  allow_metadata_inventory_put = function(...) return teleports.allow_metadata_inventory_put(...) end,
  allow_metadata_inventory_take = function(...) return teleports.allow_metadata_inventory_take(...) end,
  allow_metadata_inventory_move = function(...) return teleports.allow_metadata_inventory_move(...) end,

	-- Called by rename LBM.
	_on_rename_check = function(pos)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		-- Nobody placed this block.
		if owner == "" then
			return
		end
		local dname = rename.gpn(owner)

		meta:set_string("rename", dname)
		-- Update infotext.
		teleports.write_infotext(pos)
	end,
})



-- Redefine diamond.
minetest.override_item("default:diamondblock", {
  on_place = function(...) return teleports.on_diamond_place(...) end,
})
