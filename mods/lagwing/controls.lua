
lagwing.control_schemes = {
	["DragonsVolcanoDance"] = {
		left = "left",
		right = "right",
		up = "down",
		down = "up",
		jump = "sneak",
		sneak = "jump",
	},

	["Enyekala"] = {
		left = "left",
		right = "right",
		up = "up",
		down = "down",
		jump = "jump",
		sneak = "sneak",
	},
}

-- Control scheme requested by players.
function lagwing.apply_control_scheme(pname, ctrl)
	local data = lagwing.control_schemes[pname]

	-- If no control scheme defined, return the controls as-is.
	if not data then
		return ctrl
	end

	local c = {}

	for k, v in pairs(ctrl) do
		-- Note: controls NOT pressed will be 'false'.
		-- Thus, this check is needed.
		if v then
			if data[k] then
				c[data[k] ] = true
			else
				-- For controls not specifically remapped.
				c[k] = true
			end
		end
	end

	return c
end
