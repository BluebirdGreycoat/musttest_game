
-- Stairs.
local register_stairs = function(basename)
	local ndef = minetest.registered_nodes["darkage:" .. basename]
	if ndef then
		local groups = utility.copy_builtin_groups(ndef.groups)
		local datatable = {}

		if basename == "straw_bale" then
			datatable.exclude_pillars = true
		end

		stairs.register_stair_and_slab(
			basename,
			"darkage:" .. basename,
			groups,
			ndef.tiles, 
			ndef.description,
			ndef.sounds,
			datatable
		)
	end
end


register_stairs("basaltic")
register_stairs("basaltic_brick")
register_stairs("basaltic_rubble")

register_stairs("chalked_bricks")

register_stairs("gneiss")
register_stairs("gneiss_brick")
register_stairs("gneiss_rubble")

register_stairs("marble")

register_stairs("tuff")
register_stairs("tuff_bricks")
register_stairs("old_tuff_bricks")

register_stairs("ors")
register_stairs("ors_brick")
register_stairs("ors_rubble")

register_stairs("rhyolitic_tuff")
register_stairs("rhyolitic_tuff_bricks")

register_stairs("schist")
register_stairs("shale")
register_stairs("slate")
register_stairs("slate_brick")
register_stairs("slate_rubble")
register_stairs("slate_tile")
register_stairs("stone_brick")

-- Special: stairs ONLY, no walls/castle stuff!
register_stairs("marble_tile")
register_stairs("straw_bale")

minetest.register_alias("stairs:panel_straw_bale_pcend", "stairs:panel_wood_pcend")
minetest.register_alias("stairs:panel_straw_bale_pillar", "stairs:panel_wood_pillar")

