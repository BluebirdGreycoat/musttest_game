
-- Contexts for users who have the "formspec editor" panel open.
formspec.EDITOR_CONTEXTS = formspec.EDITOR_CONTEXTS or {}
formspec.SAVED_CONTEXTS = formspec.SAVED_CONTEXTS or {}



local function highlight_selected_widget(context)
	-- Show a bright box around the currently selected widget.
	local idx = context:get_selected_widget()
	local selector = context:get_control_by_id("GUIselectorDisplay")
	local widgets = context:get_editing_root()

	if selector and idx then
		local target = widgets[idx]

		if target.type == "checkbox" then
			-- Checkboxes don't have W, H.
			selector.visible = true
			selector.x = target.x - 0.05
			selector.y = target.y - 0.2
			selector.w = 0.4
			selector.h = 0.4
		else
			selector.visible = true
			selector.x = target.x - 0.02
			selector.y = target.y - 0.02
			selector.w = (target.w or 1) + 0.06
			selector.h = (target.h or 1) + 0.06
		end
	end
end



function formspec.make_editor(pname)
	local context = formspec.EDITOR_CONTEXTS[pname]
	if not context then return "" end

	local NEWROOT = {
		size = {x=20, y=10},

		children = {
			-- Shows what the currently-edited formspec looks like.
			{type="container", x=0, y=0},
			{type="background9", x=0, y=0, w=9, h=10, texture="gui_formbg.png", x1=50},
			{type="box", x=0, y=0, w=1, h=1, color="#ff0000ff", visible=false, FORMSPEC_ID="GUIselectorDisplay"},
			{type="container_end", FORMSPEC_ID="testGUIend"},

			-- Editor formspec with controls.
			{type="container", x=11, y=0},
			{type="background9", x=0, y=0, w=9, h=10, texture="gui_formbg.png", x1=50},
			{type="box", x=0.5, y=9.3, w=8, h=0.35, color="#00000055"},
			{type="label", x=0.5, y=9.3, w=8, h=0.35, text="No error.", show_box=false, FORMSPEC_ID="errordisplay"},
			{type="button", x=0.5, y=8.5, w=2.0, h=0.5, name="logdump", label="Dump To Log", tooltip="Writes the edited GUI parameters to the logfile."},

			-- List of current/active parameters.
			{type="container", x=0.5, y=0.4},
			{type="label", x=0, y=0, w=4.5, h=0.35, text="Parameter List", FORMSPEC_ID="paramslistLabel"},
			{type="textlist", x=0, y=0.4, w=4.5, h=3.5, name="paramslist", FORMSPEC_ID="paramslist", tooltip="This shows the list of current widget parameters."},
			{type="field", x=0, y=4.4, w=4.5, h=0.4, name="paramfield", label="Edit Parameter:", close_on_enter=false, tooltip="Type <key>=<value> to enter a parameter. Type <key>=nil to remove.", default=context.default_edit_parameter},
			{type="button", x=0, y=5.0, w=2.5, h=0.5, name="add_widget", label="Add New Widget"},
			{type="container_end"},

			-- List of registered widget types.
			{type="container", x=5.5, y=0.4},
			{type="label", x=0, y=0, w=3, h=0.35, text="Known Widgets"},
			{type="textlist", x=0, y=0.4, w=3, h=3, name="widgetlist", FORMSPEC_ID="widgetlist", tooltip="Lists all registered widgets."},
			{type="container_end"},

			-- List of active widgets.
			{type="container", x=5.5, y=4.1},
			{type="label", x=0, y=0, w=3, h=0.35, text="Constructed Widgets"},
			{type="textlist", x=0, y=0.4, w=3, h=3.8, name="activewidgets", FORMSPEC_ID="activewidgets", tooltip="Lists constructed widgets."},
			{type="button", x=0, y=4.4, w=0.5, h=0.5, name="move_order_up", label="▲"},
			{type="button", x=0.6, y=4.4, w=0.5, h=0.5, name="move_order_dn", label="▼"},
			{type="button", x=1.2, y=4.4, w=1.8, h=0.5, name="remove_widget", label="Delete"},
			{type="container_end"},

			-- Widget move controls.
			{type="container", x=0.5, y=6.42},
			{type="label", x=0, y=0, w=3, h=0.35, text="Move Widget"},
			{h=0.5, move_step=0.1, label="▲", name="move_up", type="button", w=0.5, x=0.5, y=0+0.38},
			{h=0.5, move_step=0.1, label="▼", name="move_down", type="button", w=0.5, x=0.5, y=1+0.38},
			{h=0.5, move_step=0.1, label="◀", name="move_left", type="button", w=0.5, x=0, y=0.5+0.38},
			{h=0.5, move_step=0.1, label="▶", name="move_right", type="button", w=0.5, x=1, y=0.5+0.38},
			{h=0.5, move_step=0.5, label="⇓", name="move_down2", type="button", w=0.5, x=1, y=1+0.38},
			{h=0.5, move_step=0.5, label="⇑", name="move_up2", type="button", w=0.5, x=0, y=0+0.38},
			{h=0.5, move_step=0.5, label="⇐", name="move_left2", type="button", w=0.5, x=0, y=1+0.38},
			{h=0.5, move_step=0.5, label="⇒", name="move_right2", type="button", w=0.5, x=1, y=0+0.38},
			{type="container_end"},

			-- Widget size controls.
			{type="container", x=3.5, y=6.42},
			{type="label", x=0, y=0, w=3, h=0.35, text="Size Widget"},
			{h=0.5, move_step=0.1, label="▲", name="size_up", type="button", w=0.5, x=0.5, y=0+0.38},
			{h=0.5, move_step=0.1, label="▼", name="size_down", type="button", w=0.5, x=0.5, y=1+0.38},
			{h=0.5, move_step=0.1, label="◀", name="size_left", type="button", w=0.5, x=0, y=0.5+0.38},
			{h=0.5, move_step=0.1, label="▶", name="size_right", type="button", w=0.5, x=1, y=0.5+0.38},
			{h=0.5, move_step=0.5, label="⇓", name="size_down2", type="button", w=0.5, x=1, y=1+0.38},
			{h=0.5, move_step=0.5, label="⇑", name="size_up2", type="button", w=0.5, x=0, y=0+0.38},
			{h=0.5, move_step=0.5, label="⇐", name="size_left2", type="button", w=0.5, x=0, y=1+0.38},
			{h=0.5, move_step=0.5, label="⇒", name="size_right2", type="button", w=0.5, x=1, y=0+0.38},
			{type="container_end"},

			-- Size checkboxes.
			{type="container", x=2.3, y=6.95},
			{type="checkbox", name="stepsizeSelector1", x=0, y=0, label="0.1", selected=false},
			{type="checkbox", name="stepsizeSelector2", x=0, y=0.35, label="0.01", selected=false},
			{type="container_end"},

			{type="container_end"},
		},
	}

	context.root = NEWROOT

	local function FIND(name)
		for k, v in ipairs(context.root.children) do
			if v.FORMSPEC_ID == name then
				return k
			end
		end
		return nil
	end

	if #context.last_error > 0 then
		context.root.children[FIND("errordisplay")].text = context.last_error
	end

	-- Show a bright box around the currently selected widget.
	highlight_selected_widget(context)

	if context.step_size_selector == 1 then
		context:get_control_by_name("stepsizeSelector1").selected = true
	elseif context.step_size_selector == 2 then
		context:get_control_by_name("stepsizeSelector2").selected = true
	end

	do
		local pos = FIND("paramslist")
		local itemlist = {}

		for k, v in ipairs(context.current_widget_params) do
			local value = v.value
			if type(v.value) == "string" then
				value = "\"" .. v.value .. "\""
			end
			table.insert(itemlist, v.param .. " = " .. tostring(value))
		end

		context.root.children[pos].itemlist = itemlist
		context.root.children[pos].selected = context:get_selected_param()

		if context:get_selected_widget() then
			context.root.children[FIND("paramslistLabel")].text = "Parameter List of Selected Widget"
		end
	end

	do
		local pos = FIND("widgetlist")
		local itemlist = {}

		for name, _ in pairs(formspec.WIDGET_TYPES) do
			table.insert(itemlist, name)
		end

		table.sort(itemlist)
		context.root.children[pos].itemlist = itemlist
		context.known_widget_names = itemlist
	end

	do
		local pos = FIND("activewidgets")
		local itemlist = {}

		for _, v in ipairs(context.editing_root) do
			table.insert(itemlist, (v.type .. " [" .. (v.name or "") .. "]"))
		end

		context.root.children[pos].itemlist = itemlist
		context.root.children[pos].selected = context:get_selected_widget()
	end

	-- Construct the workpiece being edited so we can show what it looks like.
	if context.editing_root then
		local pos = FIND("testGUIend")
		for _, info in ipairs(context.editing_root) do
			table.insert(context.root.children, pos, info)
			pos = pos + 1 -- Insert items in order.
		end
	end

	return formspec.create_formspec_from_table(context.root)
end



local SPECIAL_PARAMETERS = {
	["type"] = 1,
	["name"] = 2,
	["x"] = 3,
	["y"] = 4,
	["w"] = 5,
	["h"] = 6,
	["x1"] = 7,
	["y1"] = 8,
	["x2"] = 9,
	["y2"] = 10,
}

local function priority_sort(pa, pb)
	local a = pa.param
	local b = pb.param

	local prioA = SPECIAL_PARAMETERS[a]
	local prioB = SPECIAL_PARAMETERS[b]

	if prioA and prioB then
		-- Both special → sort by their defined priority
		return prioA < prioB
	elseif prioA then
		-- a is special, b is not → a comes first
		return true
	elseif prioB then
		-- b is special, a is not → b comes first
		return false
	else
		-- Neither special → normal string sort
		return a < b
	end
end



local function create_new_editor_context(pname, param)
	return {
		original_param = param, -- Original chatcommand param.
		root = {}, -- A copy of the original GUI table, MINUS the edited GUI.
		editing_root = {}, -- A flat array of all edited/managed GUI table infos.
		current_widget_params = {}, -- Array of {param="key", value=<val>} subtables.
		known_widget_names = {}, -- Array of registered widget names.
		last_error = "",
		default_edit_parameter = "",
		step_size_selector = 1,

		set_error = function(self, msg)
			self.last_error = minetest.get_color_escape_sequence("#ff0000ff") .. msg
		end,

		set_message = function(self, msg)
			self.last_error = msg
		end,

		get_editing_root = function(self)
			return self.editing_root
		end,

		get_selected_widget = function(self)
			local idx = self.selected_active_widget
			if idx and idx >= 1 and idx <= #self.editing_root then
				return idx
			end
		end,

		get_selected_param = function(self)
			return self.selected_active_param
		end,

		set_selected_widget = function(self, idx)
			-- Negative values select from the end.
			if idx and idx < 0 then
				idx = #self.editing_root + idx + 1
			end

			if idx and idx >= 1 and idx <= #self.editing_root then
				self.selected_active_widget = idx
				return
			end

			self.selected_active_widget = nil
		end,

		set_selected_param = function(self, idx)
			-- Negative values select from the end.
			if idx and idx < 0 then
				idx = #self.current_widget_params + idx + 1
			end

			if idx and idx >= 1 and idx <= #self.current_widget_params then
				self.selected_active_param = idx
				return
			end

			self.selected_active_param = nil
		end,

		set_editing_parameters = function(self, params)
			if not params or not next(params) then
				self.current_widget_params = {}
				return
			end

			local newlist = {}

			for k, v in pairs(params) do
				table.insert(newlist, {param=k, value=v})
			end

			-- Sort with priority.
			table.sort(newlist, priority_sort)

			self.current_widget_params = newlist
		end,

		get_control_by_name = function(self, name)
			for _, widget in ipairs(self.root.children) do
				if widget.name and widget.name == name then
					return widget
				end
			end
		end,

		get_control_by_id = function(self, name)
			for _, widget in ipairs(self.root.children) do
				if widget.FORMSPEC_ID and widget.FORMSPEC_ID == name then
					return widget
				end
			end
		end,

		get_widget_params = function(self)
			local params = {}

			-- Convert array of subtables to regular widget description table (dict).
			for k, v in ipairs(self.current_widget_params or {}) do
				params[v.param] = v.value
			end

			return params
		end,
	}
end



-- Called from chatcommand.
function formspec.show_editor(pname, param)
	-- Reuse existing context if present.
	if formspec.SAVED_CONTEXTS[pname] then
		formspec.EDITOR_CONTEXTS[pname] = formspec.SAVED_CONTEXTS[pname]
		formspec.SAVED_CONTEXTS[pname] = nil
	end

	if not formspec.EDITOR_CONTEXTS[pname] then
		formspec.EDITOR_CONTEXTS[pname] = create_new_editor_context(pname, param)
	else
		-- Update all functions in the existing context.
		local existing_context = formspec.EDITOR_CONTEXTS[pname]
		local tmp = create_new_editor_context(pname, param)
		for k, v in pairs(tmp) do
			if type(v) == "function" then
				existing_context[k] = v
			end
		end
	end

	local serialized = formspec.make_editor(pname)
	minetest.show_formspec(pname, "formspec:editor", serialized)
end



local function handle_add_widget(context, fields)
	if not fields.add_widget then
		return
	end

	local widgets = context:get_editing_root()
	local params = context:get_widget_params()

	if type(params.type) ~= "string" then
		context:set_error("Missing mandatory type name.")
		return
	end

	-- Prevent user from messing up the editor GUI.
	if type(params.FORMSPEC_ID) ~= "nil" then
		context:set_error("Do NOT use internal GUI editor names.")
		return
	end

	local widgetfactory = formspec.WIDGET_TYPES[params.type]
	if not widgetfactory then
		context:set_error("Cannot create unknown widget.")
		return
	end
	if not widgetfactory.make_params then
		context:set_error("Widget not constructable.")
		return
	end

	-- Invent default names for widgets that have name parameters but they're empty.
	if params.name and #params.name == 0 then
		local t = params.type
		local c = 1

		-- Count up all widgets of the same type.
		for _, v in ipairs(widgets) do
			if v.type == t then
				c = c + 1
			end
		end

		-- Build name string.
		local s = t .. c
		params.name = s
	end

	-- Do NOT allow names beginning with "key_".
	if params.name then
		if params.name:find("^key_") then
			context:set_error("Cannot create widget with engine-reserved name.")
			return
		end
	end

	-- Make sure we're not adding GUI elements with duplicate or reserved names.
	-- That will break stuff.
	if params.name then
		if context:get_control_by_name(params.name) then
			context:set_error("Cannot create widget using EDITOR reserved name.")
			return
		end

		for k, v in ipairs(widgets) do
			if v.name and v.name == params.name then
				context:set_error("You've already added a widget with that name.")
				return
			end
		end
	end

	-- Make sure minimum parameters are provided matching what the widget wants.
	local wanted_params = widgetfactory.make_params()
	for k, v in pairs(wanted_params) do
		if type(params[k]) ~= type(v) then
			context:set_error("Missing required parameter, or wrong parameter type.")
			return
		end
	end

	table.insert(widgets, params)

	context:set_message("Success: added " .. params.type .. " [" .. (params.name or "") .. "].")
	context:set_selected_widget(-1)
	return true
end



local function handle_remove_widget(context, fields)
	if not fields.remove_widget then
		return
	end

	local idx = context:get_selected_widget()
	local widgets = context:get_editing_root()

	if not (idx and idx >= 1 and idx <= #widgets) then
		return context:set_error("No selected widget to remove.")
	end

	local removed = table.remove(widgets, idx)

	if idx > #widgets then
		idx = #widgets
	end

	context:set_selected_widget(idx)
	return context:set_message("Removed " .. removed.type .. " [" .. (removed.name or "") .. "] widget.")
end



local function handle_param_edit(context, fields)
	if fields.key_enter_field ~= "paramfield" then
		return
	end

	context:set_error("What are you doing?")
	local tokens = fields.paramfield:split("=")

	for i=1, #tokens, 1 do
		tokens[i] = tokens[i]:trim()
	end

	if not (#tokens == 2 and tokens[1]:len() > 0 and tokens[2]:len() > 0) then
		return
	end

	local function FIND(key)
		for k, v in ipairs(context.current_widget_params) do
			if v.param == key then
				return k
			end
		end
	end

	-- Input 'val' is always a string.
	local function TOTYPE(val)
		if tonumber(val) then
			return tonumber(val)
		elseif val == "true" then
			return true
		elseif val == "false" then
			return false
		elseif val == "\"\"" then
			return ""
		end

		-- Strip quotes if user supplied them.
		if val:sub(1, 1) == "\"" and val:sub(#val) == "\"" then
			return val:sub(2, val:len() - 1)
		end

		-- Val is a string and should remain a string.
		return val
	end

	local pos = FIND(tokens[1])

	if pos then
		context:set_selected_param(pos)

		if not context.selected_active_widget or tokens[1] ~= "type" then
			if tokens[2] ~= "nil" then
				context.current_widget_params[pos].value = TOTYPE(tokens[2])
				context:set_message("Updated parameter.")
				context:set_selected_param(pos)
			else
				table.remove(context.current_widget_params, pos)
				context:set_message("Parameter removed from table.")
				context:set_selected_param(nil)
			end
		else
			context:set_selected_param(nil)
			context:set_error("Cannot change type of existing created widget.")
			return
		end
	else
		if tokens[2] ~= "nil" then
			table.insert(context.current_widget_params, {param=tokens[1], value=TOTYPE(tokens[2])})
			context:set_selected_param(-1)
			context:set_message("Added new parameter.")
		else
			context:set_selected_param(nil)
			context:set_error("Parameter doesn't exist; nothing to be done.")
			return
		end
	end

	-- Edit currently selected active widget.
	if context.selected_active_widget then
		local idx = context.selected_active_widget
		local root = context.editing_root

		if idx >= 1 and idx <= #root then
			-- Reuse the logic here to update the widget.
			-- This always adds a new widget to the end of the widget array.
			-- We can replace'n'pop.
			local oldname = root[idx].name
			root[idx].name = "" -- Otherwise we couldn't add.
			if handle_add_widget(context, {add_widget=true}) then
				root[idx] = root[#root]
				root[#root] = nil
				context.selected_active_widget = idx
			else
				root[idx].name = oldname -- Restore it.
			end
		end
	end
end



local function handle_widget_select(context, fields)
	if not fields.widgetlist then
		return
	end

	local tab = minetest.explode_textlist_event(fields.widgetlist)
	local idx = tab.index
	local widgets = context.known_widget_names

	if not (tab.type == "DCL" and idx >= 1 and idx <= #widgets) then
		return -- Normal.
	end

	context:set_selected_param(nil)
	context.default_edit_parameter = nil

	local name = widgets[idx]
	local widget = formspec.WIDGET_TYPES[name]

	if not widget then
		context:set_editing_parameters(nil)
		context:set_error("Selected unknown widget type!")
		return
	end

	if not widget.make_params then
		context:set_editing_parameters(nil)
		context:set_error("Widget type not constructable.")
		return
	end

	context:set_editing_parameters(widget.make_params())
	context:set_selected_widget(nil)
	context:set_message("Selected: " .. name .. ".")
end



local function handle_active_select(context, fields)
	if not fields.activewidgets then
		return
	end

	local tab = minetest.explode_textlist_event(fields.activewidgets)
	local idx = tab.index
	local widgets = context:get_editing_root()

	-- A single click removes the current selection.
	if tab.type == "CHG" then
		context:set_selected_widget(nil)
		context:set_editing_parameters(nil)
		return
	end

	if not (tab.type == "DCL" and idx >= 1 and idx <= #widgets) then
		return -- Normal.
	end

	context:set_editing_parameters(widgets[idx])
	context:set_selected_widget(idx)
	context:set_message("Selected widget " .. idx .. " (" .. widgets[idx].type .. " [" .. (widgets[idx].name or "") .. "]).")
end



local function handle_param_select(context, fields)
	if not fields.paramslist then
		return
	end

	local params = context.current_widget_params
	local tab = minetest.explode_textlist_event(fields.paramslist)
	local idx = tab.index

	if not (tab.type == "CHG" and idx >= 1 and idx <= #params) then
		return -- Normal.
	end

	local entry = params[idx]
	local val = entry.value
	if type(val) == "string" and #val == 0 then
		val = "\"\""
	end

	context.default_edit_parameter = entry.param .. "=" .. tostring(val)
	context:set_selected_param(idx)
end



local function handle_change_order(context, fields)
	if not fields.move_order_dn and not fields.move_order_up then
		return
	end

	local widgets = context:get_editing_root()
	local idx = context:get_selected_widget()

	if not (idx and idx >= 1 and idx <= #widgets) then
		context:set_error("No selected widget.")
		return
	end

	if fields.move_order_dn and idx < #widgets then
		local tmp = widgets[idx + 1]
		widgets[idx + 1] = widgets[idx]
		widgets[idx] = tmp
		context:set_selected_widget(idx + 1)
	end

	if fields.move_order_up and idx > 1 then
		local tmp = widgets[idx - 1]
		widgets[idx - 1] = widgets[idx]
		widgets[idx] = tmp
		context:set_selected_widget(idx - 1)
	end
end



local function handle_move_widget(context, fields)
	local idx = context:get_selected_widget()
	local widgets = context:get_editing_root()

	if not (idx and idx >= 1 and idx <= #widgets) then
		return
	end

	local changed = false
	local target = widgets[idx]

	local buttons = {
		move_left = {x=-1, y=0, z=0},
		move_right = {x=1, y=0, z=0},
		move_up = {x=0, y=-1, z=0},
		move_down = {x=0, y=1, z=0},
		move_left2 = {x=-1, y=0, z=0},
		move_right2 = {x=1, y=0, z=0},
		move_up2 = {x=0, y=-1, z=0},
		move_down2 = {x=0, y=1, z=0},
	}

	for fieldname, info in pairs(buttons) do
		if fields[fieldname] then
			local step = context:get_control_by_name(fieldname).move_step

			if context.step_size_selector == 2 and step < 0.5 then
				step = 0.01
			end

			local curpos = {x=target.x, y=target.y, z=0}
			local newpos = vector.add(vector.multiply(info, step), curpos)

			target.x = newpos.x
			target.y = newpos.y

			-- Round to nearest hundredths.
			target.x = math.round(target.x * 100) / 100
			target.y = math.round(target.y * 100) / 100

			changed = true
			break
		end
	end

	if changed then
		context:set_editing_parameters(target)
		context:set_selected_param(nil)
		context.default_edit_parameter = nil
	end
end



local function handle_size_widget(context, fields)
	local idx = context:get_selected_widget()
	local widgets = context:get_editing_root()

	if not idx then
		return
	end

	local changed = false
	local target = widgets[idx]

	-- Widget doesn't support sizing.
	if not target.w or not target.h then
		return
	end

	local buttons = {
		size_left = {x=-1, y=0, z=0},
		size_right = {x=1, y=0, z=0},
		size_up = {x=0, y=-1, z=0},
		size_down = {x=0, y=1, z=0},
		size_left2 = {x=-1, y=0, z=0},
		size_right2 = {x=1, y=0, z=0},
		size_up2 = {x=0, y=-1, z=0},
		size_down2 = {x=0, y=1, z=0},
	}

	for fieldname, info in pairs(buttons) do
		if fields[fieldname] then
			local step = context:get_control_by_name(fieldname).move_step

			if context.step_size_selector == 2 and step < 0.5 then
				step = 0.01
			end

			local curpos = {x=target.w, y=target.h, z=0}
			local newpos = vector.add(vector.multiply(info, step), curpos)

			target.w = newpos.x
			target.h = newpos.y

			if target.w < 0.1 then target.w = 0.1 end
			if target.h < 0.1 then target.h = 0.1 end

			-- Round to nearest hundredths.
			target.w = math.round(target.w * 100) / 100
			target.h = math.round(target.h * 100) / 100

			changed = true
			break
		end
	end

	if changed then
		context:set_editing_parameters(target)
		context:set_selected_param(nil)
		context.default_edit_parameter = nil
	end
end



local function handle_step_selector(context, fields)
	local function toboolean(str)
		if type(str) == "boolean" then
			return str
		end

		if type(str) == "string" then
			if str == "true" then return true end
			if str == "false" then return false end
		end

		if type(str) == "number" then
			if str == 0 then return false end
			return true
		end

		return false
	end

	if fields.stepsizeSelector1 then
		local bs = fields.stepsizeSelector1
		if toboolean(bs) then
			context.step_size_selector = 1
			context:get_control_by_name("stepsizeSelector1").selected = true
			context:get_control_by_name("stepsizeSelector2").selected = false
		else
			context.step_size_selector = 2
			context:get_control_by_name("stepsizeSelector1").selected = false
			context:get_control_by_name("stepsizeSelector2").selected = true
		end
	end

	if fields.stepsizeSelector2 then
		local bs = fields.stepsizeSelector2
		if toboolean(bs) then
			context.step_size_selector = 2
			context:get_control_by_name("stepsizeSelector1").selected = false
			context:get_control_by_name("stepsizeSelector2").selected = true
		else
			context.step_size_selector = 1
			context:get_control_by_name("stepsizeSelector1").selected = true
			context:get_control_by_name("stepsizeSelector2").selected = false
		end
	end
end



local function handle_live_select(context, fields)
	local names = {}
	local widgets = context:get_editing_root()

	-- List of GUI elements to ignore because we ALWAYS get them in 'fields'
	local BLACKLIST = {
		field = true,
		textarea = true,
	}

	for index, info in ipairs(widgets) do
		if info.name and info.name ~= "" and not BLACKLIST[info.type] then
			table.insert(names, {name=info.name, index=index})
		end
	end

	for _, entry in ipairs(names) do
		if fields[entry.name] then
			local idx = entry.index
			context:set_selected_widget(idx)
			context:set_editing_parameters(widgets[idx])
			context:set_message("Selected widget " .. idx .. " (" .. widgets[idx].type .. " [" .. (widgets[idx].name or "") .. "]).")
			return
		end
	end
end



local function handle_logdump(context, fields)
	if not fields.logdump then
		return
	end

	local root = context:get_editing_root()
	local final = dump(root)

	-- Clean it up.
	final = final:gsub("\n", " ")
	final = final:gsub("%s+", " ")
	final = final:gsub("%s*=%s*", "=")
	final = final:gsub("{%s*", "{")
	final = final:gsub(",%s*}", "}")
	final = final:gsub("}%s*,%s*{", "},\n{")

	minetest.log("[formspec:dump] " .. final)

	local lines = final:split("\n")
	for _, line in ipairs(lines) do
		minetest.chat_send_player(pname, "# Server: " .. line)
	end

	context:set_message("Dumped! I hope you had a console open.")
end



function formspec.on_player_receive_fields(player, formname, fields)
	if formname ~= "formspec:editor" then
		return
	end

	local pname = player:get_player_name()
	local context = formspec.EDITOR_CONTEXTS[pname]
	if not context then
		return
	end

	-- Nil error message by default, shall be populated if some field action errors.
	context.last_error = ""

	if fields.quit then
		-- Save for later. User might have clicked off the editor and we don't want to throw away their work.
		formspec.SAVED_CONTEXTS[pname] = formspec.EDITOR_CONTEXTS[pname]
		formspec.EDITOR_CONTEXTS[pname] = nil
		return
	end

	handle_param_edit(context, fields)
	handle_param_select(context, fields)
	handle_widget_select(context, fields)
	handle_active_select(context, fields)
	handle_add_widget(context, fields)
	handle_remove_widget(context, fields)
	handle_change_order(context, fields)
	handle_move_widget(context, fields)
	handle_size_widget(context, fields)
	handle_step_selector(context, fields)
	handle_live_select(context, fields)
	handle_logdump(context, fields)

	-- No need to call other field handlers.
	formspec.show_editor(pname, formspec.EDITOR_CONTEXTS[pname].original_param)
	return true
end
