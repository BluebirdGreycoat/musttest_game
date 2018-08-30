
-- Walls.
local register_wall = function(basename)
	local ndef = minetest.registered_nodes["darkage:" .. basename]
	if ndef then
		local image = ndef.tiles[1]
		if type(image) == "string" then
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

register_wall("basaltic_rubble")
register_wall("ors_rubble")
register_wall("stone_brick")
register_wall("slate_rubble")
register_wall("tuff_bricks")
register_wall("old_tuff_bricks")
register_wall("rhyolitic_tuff_bricks")

