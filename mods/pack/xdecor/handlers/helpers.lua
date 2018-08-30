-- Returns the greatest numeric key in a table.
function xdecor.maxn(T)
	local n = 0
	for k in pairs(T) do
		if k > n then n = k end
	end
	return n
end

-- Returns the length of an hash table.
function xdecor.tablelen(T)
	local n = 0
	for _ in pairs(T) do n = n + 1 end
	return n
end

-- Deep copy of a table. Borrowed from mesecons mod (https://github.com/Jeija/minetest-mod-mesecons).
function xdecor.tablecopy(T)
	if type(T) ~= "table" then return T end -- No need to copy.
	local new = {}

	for k, v in pairs(T) do
		if type(v) == "table" then
			new[k] = xdecor.tablecopy(v)
		else
			new[k] = v
		end
	end
	return new
end

function xdecor.stairs_valid_def(def)
	if def.nostairs then
		return false
	end
	if def.drawtype then
		if def.drawtype ~= "normal" and def.drawtype:sub(1, 5) ~= "glass" then
			return false
		end
	end
	if def.on_construct or def.after_place_node or def.on_rightclick or def.on_blast or def.allow_metadata_inventory_take then
		return false
	end
	if def.mesecons then
		return false
	end
	if not def.description or def.description == "" then
		return false
	end
	if def.light_source and def.light_source ~= 0 then
		return false
	end
	if def.groups then
		if def.groups.wool then
			return false
		end
		if def.groups.not_in_creative_inventory or def.groups.not_cuttable then
			return false
		end
		if not def.groups.cracky and not def.groups.choppy then
			return false
		end
	end
	if def.tiles and type(def.tiles[1]) == "string" then
		if def.tiles[1]:find("default_mineral") then
			return false
		end
	end
	return true -- All tests passed.
end


