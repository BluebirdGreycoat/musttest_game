
local function FS(text)
	return minetest.formspec_escape(text)
end



local function get_styles(widget, params)
	local s1, s2 = "", ""
	if params.style then
		local props1 = {}
		local props2 = {}

		for k, v in pairs(params.style) do
			local t = type(v) -- Ignore unsupported types.
			if t == "string" or t == "boolean" or t == "number" then
				table.insert(props1, k .. "=" .. tostring(v))
				table.insert(props2, k .. "=") -- Resetters.
			end
		end

		local propstr1 = table.concat(props1, ";")
		local propstr2 = table.concat(props2, ";")

		-- Only needed if style properties were actually present.
		if #props1 > 0 then
			s1 = "style_type[" .. widget .. ";" .. propstr1 .. "]"
			s2 = "style_type[" .. widget .. ";" .. propstr2 .. "]"
		end
	end
	return s1, s2
end



local function apply_styles(params, formstring)
	local widget = params.type
	local s1, s2 = get_styles(widget, params)
	return s1 .. formstring .. s2
end



local function process_element_spec(in_data, out_lines)
	if not in_data.children then
		return
	end

	-- Keep track of nesting level as we walk the flat array table.
	local nesting_level = {}

	local function all_parents_visible()
		for _, info in ipairs(nesting_level) do
			if info.visible == false then
				return false
			end
		end
		return true
	end

	for _, info in ipairs(in_data.children) do
		local make = info.type and formspec.WIDGET_TYPES[info.type] and formspec.WIDGET_TYPES[info.type].make

		if not make then
			goto skip_me
		end

		local was_invisible = false
		local is_container_tag = false

		if info.type == "container" then
			table.insert(nesting_level, info)
			is_container_tag = true
		elseif info.type == "container_end" then
			was_invisible = not all_parents_visible()
			table.remove(nesting_level)
			is_container_tag = true
		end

		-- Skip adding end tag if its start tag was invisible.
		-- This keeps us balanced.
		if not all_parents_visible() or (was_invisible and is_container_tag) then
			goto skip_me
		end

		if info.visible or info.visible == nil then
			-- Create base GUI element from factory function.
			local s = make(info)

			-- Sandwich style tags.
			s = apply_styles(info, s)

			-- Add tooltip if present. Must be declared *after* the element it's bound to.
			if info.tooltip and info.name then
				s = s .. "tooltip[" .. info.name .. ";" .. FS(info.tooltip) .. "]"
			end

			-- Show debug AABB.
			if info.show_box then
				local b = "box[" .. info.x .. "," .. info.y .. ";" .. (info.w or 0.1) .. "," .. (info.h or 0.1) .. ";#00ff00ff]"
				table.insert(out_lines, b)
			end

			-- Add to (flat) array of GUI elements.
			table.insert(out_lines, s)
		end

		::skip_me::
	end
end



-- Helper function to create a formspec string from a GUI table.
--
-- A formspec is essentially just a serialized GUI description.
-- I'm tired of writing serialized GUIs. Let's use simpler tables to describe
-- the GUI, and write a function to generate the serialized form!
--
-- BTW the reason I NIH everything is because that leads to learning
-- how stuff actually works. Pulling libraries off the shelf is like asking AI
-- to solve all my problems. I'm sure it works (we shall see), and I'm also
-- sure I'll be as stupid afterward as I was before.
function formspec.create_formspec_from_table(root)
	local formlines = {
		"formspec_version[" .. formspec.FORMSPEC_VERSION .. "]",
	}

	local function deal_with(name, pos, default)
		if not pos or not pos.x or not pos.y then
			if default then
				pos = default
			else
				return
			end
		end

		if type(pos) ~= "table" then return end
		if type(pos.x) ~= "number" then return end
		if type(pos.y) ~= "number" then return end

		table.insert(formlines, name .. "[" .. pos.x .. "," .. pos.y .. "]")
	end

	deal_with("size", root.size, {x=8, y=8})
	deal_with("position", root.position)
	deal_with("anchor", root.anchor)
	deal_with("padding", root.padding)

	if root.no_prepend then
		table.insert(formlines, "no_prepend[]")
	end

	if root.allow_close == false then
		table.insert(formlines, "allow_close[false]")
	end

	process_element_spec(root, formlines)

	local forms = table.concat(formlines)
	--minetest.log(forms)
	return forms
end
