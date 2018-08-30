
image = {}
local find = string.find

local replacements = {
	["default_stone.png"] = "tsa.png^[sheet:16x16:0,0",
	["default_snow.png"] = "tsa.png^[sheet:16x16:1,0",
	["default_ice.png"] = "tsa.png^[sheet:16x16:1,1",
	["default_cobble.png"] = "tsa.png^[sheet:16x16:2,0",
	["default_gravel.png"] = "tsa.png^[sheet:16x16:3,0",
	["default_dirt.png"] = "tsa.png^[sheet:16x16:4,0",
}

function image.get(fn)
	-- Minetest does not actually support tilesheets at this time.
	-- Therefore this function actually does nothing.

	-- Names with modifiers already in place are not supported.
	-- We cannot safely replace them with images from a tilesheet.
	--if find(fn, "%^") then
	--	return fn
	--end

	-- Use named replacement if available.
	--if replacements[fn] then
	--	return replacements[fn]
	--end

	-- If we found no replacement, just use name as-is.
	return fn
end
