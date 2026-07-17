
if not minetest.global_exists("formspec") then formspec = {} end
formspec.modpath = minetest.get_modpath("formspec")

local FORMSPEC_VERSION = 9
local WIDGET_TYPES = {}



function formspec.register_widget(name, info)
	WIDGET_TYPES[name] = table.copy(info)
end



dofile(formspec.modpath .. "/widgets.lua")



local function FS(text)
	return minetest.formspec_escape(text)
end



local function get_styles(widget, params)
	local s1, s2 = "", ""
	if params.style then
		local props1 = {}
		local props2 = {}

		for k, v in pairs(params.style) do
			table.insert(props1, k .. "=" .. v)
			table.insert(props2, k .. "=") -- Resetters.
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
	if in_data.children then
		for _, info in ipairs(in_data.children) do
			local make = info.type and WIDGET_TYPES[info.type] and WIDGET_TYPES[info.type].make

			if make then
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
		end
	end
end



local function get_formspec_size(info)
	if info.size and info.size.x and info.size.y then
		return info.size.x .. "," .. info.size.y
	end
	return "8,8"
end



-- Helper function to create a formspec string from a GUI table.
--
-- A formspec is essentially just a serialized GUI description.
-- I'm tired of writing serialized GUIs. Let's use simpler tables to describe
-- the GUI, and write a function to generate the serialized form!
--
-- BTW the reason I NIH everything is because that leads to learning
-- how stuff actually works. Pulling libraries off the shelf is like asking AI
-- to solve all my problems. I'm sure it works, and I'm also sure I'll be as
-- stupid afterward as I was before.
function formspec.create_formspec_from_table(root)
	local formlines = {
		"formspec_version[" .. FORMSPEC_VERSION .. "]",
		"size[" .. get_formspec_size(root) .. "]",
		--"bgcolor[#ff0000ff;false]",
	}

	--if root.no_prepend then
	--	table.insert(formlines, "no_prepend[]")
	--end

	process_element_spec(root, formlines)

	local forms = table.concat(formlines)
	--minetest.log(forms)
	return forms
end



if not formspec.run_once then
	local c = "formspec:core"
	local f = formspec.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	formspec.run_once = true
end
