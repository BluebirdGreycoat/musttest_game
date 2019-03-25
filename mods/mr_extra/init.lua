
mr_extra = mr_extra or {}
mr_extra.modpath = minetest.get_modpath("mr_extra")

local rocks = {
	"serpentine",
	"marble_pink",
	"marble_white",
	"marble",
	"marble_bricks",
	"granite",
}

for k, v in ipairs(rocks) do
	local basename = "morerocks:" .. v
	local ndef = minetest.registered_nodes[basename]
	if ndef then
		-- Stairs.
		stairs.register_stair_and_slab(
			"morerocks_" .. v,
			basename,
			ndef.groups,
			ndef.tiles, -- Accepts a table.
			ndef.description,
			ndef.sounds
		)

		-- Walls/castle stuff.
		local image = ndef.tiles[1]
		if type(image) == "string" then
			walls.register(
				"morerocks_ " .. v,
				ndef.description,
				image, -- Only accepts a string!
				basename,
				ndef.sounds
			)
		end
	end
end


