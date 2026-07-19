
function formspec.parse_documentation(wanted)
	local lines = formspec.RAW_MARKDOWN

	if not lines or #lines == 0 then
		return ""
	end

	local tagkey = "%f[%w]" .. wanted .. "%f[%W]"
	local outlines = {}
	local start
	local finish

	for k, v in ipairs(lines) do
		if v:find("^%*") then
			if v:find(tagkey) and not start then
				start = k
			else
				if start and not finish then
					finish = k - 1
				end
			end
		end
	end

	if start and finish then
		for i = start, finish, 1 do
			local g = lines[i]

			table.insert(outlines, g)
		end
	end

	return table.concat(outlines, "\n")
end
