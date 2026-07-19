
-- This function combines split lines into single lines.
local function collate_lines(lines)
	local newlines = {}

	for i = 1, #lines, 1 do
		local g = lines[i]

		local p = g:find("%*")

		if p then
			table.insert(newlines, g)
		else
			-- If line does NOT begin with a * we assume it belongs to the previous line.
			newlines[#newlines] = newlines[#newlines] .. " " .. g:trim()
		end
	end

	return newlines
end



local function find_last_split(str, max)
	local last
	local p = 0

	while true do
		p = str:find(" ", p + 1)
		if not p or p > max then
			break
		end
		last = p
	end

	return last
end



local function split_line(str, max)
	local newlines = {}

	-- Calculate initial indent.
	local indent = str:find("%S")
	if indent then
		indent = (" "):rep(indent + 1)
	else
		indent = ""
	end

	local first = true

	-- While there's still characters left
	while str:len() > 0 do
		local s

		if first then
			-- Get max, or less if there's a word boundary.
			local nmax = find_last_split(str, max) or max

			s = str:sub(1, nmax) -- Take the beginning.
			str = str:sub(nmax + 1) -- Trim off the beginning.
		else
			-- Get max, or less if there's a word boundary.
			local nmax = find_last_split(str, max) or max

			local imax = max - indent:len() -- Find out how much space we really have (account for indent).
			if imax < 10 then imax = 10 end -- Minimum chunk size for safety.

			s = str:sub(1, imax) -- Take the beginning.
			str = str:sub(imax + 1) -- Trim off the beginning.
			s = indent .. s:trim() -- Add the indent.
		end

		table.insert(newlines, s) -- Add the beginning.
		--str = "___" .. str

		first = false
	end

	--minetest.log(str)
	--minetest.log(dump(newlines))
	return newlines
end



local function wrap_lines(lines)
	local newlines = {}
	local MAX_COLUMNS = 59

	for i = 1, #lines, 1 do
		local g = lines[i]

		if g:len() <= MAX_COLUMNS then
			table.insert(newlines, g)
		else
			local j = split_line(g, MAX_COLUMNS)
			for k, v in ipairs(j) do
				table.insert(newlines, v)
			end
		end
	end

	return newlines
end



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
			table.insert(outlines, lines[i])
		end
	end

	outlines = wrap_lines(collate_lines(outlines))

	return table.concat(outlines, "\n")
end
