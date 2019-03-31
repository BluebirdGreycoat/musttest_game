
-- Stairs.
local register_stairs = function(basename)
	local ndef = minetest.registered_nodes["darkage:" .. basename]
	if ndef then
		local groups = {}
		groups.level = ndef.groups.level or 1
		if ndef.groups.crumbly then
			groups.crumbly = ndef.groups.crumbly
		end
		if ndef.groups.cracky then
			groups.cracky = ndef.groups.cracky
		end
		if ndef.groups.snappy then
			groups.snappy = ndef.groups.snappy
		end
		if ndef.groups.choppy then
			groups.choppy = ndef.groups.choppy
		end
		if ndef.groups.oddly_breakable_by_hand then
			groups.oddly_breakable_by_hand = ndef.groups.oddly_breakable_by_hand
		end
		if ndef.groups.flammable then
			groups.flammable = ndef.groups.flammable
		end
		if ndef.groups.dig_immediate then
			groups.dig_immediate = ndef.groups.dig_immediate
		end

		stairs.register_stair_and_slab(
			basename,
			"darkage:" .. basename,
			groups,
			ndef.tiles, 
			ndef.description,
			ndef.sounds
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

