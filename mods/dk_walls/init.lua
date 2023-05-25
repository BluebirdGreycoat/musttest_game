
-- Walls.
local register_wall = function(basename)
	local ndef = minetest.registered_nodes["darkage:" .. basename]
	if ndef then
		local image = ndef.tiles[1]
		if type(image) == "string" or type(image) == "table" then
			walls.register(
				basename,
				ndef.description,
				image,
				"darkage:" .. basename,
				ndef.sounds
			)
		end
	end	
end

register_wall("basaltic")
register_wall("basaltic_brick")
register_wall("basaltic_rubble")

register_wall("chalked_bricks")

register_wall("gneiss")
register_wall("gneiss_brick")
register_wall("gneiss_rubble")

register_wall("marble")

register_wall("tuff")
register_wall("tuff_bricks")
register_wall("old_tuff_bricks")

register_wall("ors")
register_wall("ors_brick")
register_wall("ors_rubble")

register_wall("rhyolitic_tuff")
register_wall("rhyolitic_tuff_bricks")

register_wall("schist")
register_wall("shale")
register_wall("slate")
register_wall("slate_brick")
register_wall("slate_rubble")
register_wall("slate_tile")
register_wall("stone_brick")

