
-- Contexts for users who have the "formspec editor" panel open.
formspec.EDITOR_CONTEXTS = formspec.EDITOR_CONTEXTS or {}



function formspec.make_editor(pname)
	local context = formspec.EDITOR_CONTEXTS[pname] or {}

	local root = {
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
			{type="button", x=0.5, y=8.5, w=1.7, h=0.6, name="add_widget", label="Add Item"},
			{type="label", x=0.5, y=9.3, w=8, h=0.35, text="No error.", show_box=false, FORMSPEC_ID="errordisplay"},

			-- List of current/active parameters.
			{type="container", x=0.5, y=0.4},
			{type="label", x=0, y=0, w=3, h=0.35, text="Parameter List"},
			{type="textlist", x=0, y=0.4, w=3, h=3.5, name="paramslist", FORMSPEC_ID="paramslist", tooltip="This shows the list of current widget parameters."},
			{type="field", x=0, y=4.4, w=3, h=0.4, name="paramfield", label="Edit Parameter:", close_on_enter=false, tooltip="Type <key>=<value> to enter a parameter. Type <key>=nil to remove.", default=context.default_edit_parameter},
			{type="container_end"},

			-- List of registered widget types.
			{type="container", x=5.5, y=0.4},
			{type="label", x=0, y=0, w=3, h=0.35, text="Known Widgets"},
			{type="textlist", x=0, y=0.4, w=3, h=3, name="widgetlist", FORMSPEC_ID="widgetlist", tooltip="Lists all registered widgets."},
			{type="container_end"},

			-- List of active widgets.
			{type="container", x=5.5, y=4.1},
			{type="label", x=0, y=0, w=3, h=0.35, text="Constructed Widgets"},
			{type="textlist", x=0, y=0.4, w=3, h=4.55, name="activewidgets", FORMSPEC_ID="activewidgets", tooltip="Lists constructed widgets."},
			{type="container_end"},

			{type="container_end"},
		},
	}

	local original_root = table.copy(root)

	local function FIND(name)
		for k, v in ipairs(root.children) do
			if v.FORMSPEC_ID == name then
				return k
			end
		end
		return nil
	end

	if #context.last_error > 0 then
		root.children[FIND("errordisplay")].text = context.last_error
	end

	-- Show a bright box around the currently selected widget.
	if context.selected_active_widget then
		local idx = context.selected_active_widget
		local pos = FIND("GUIselectorDisplay")
		local widgets = context.editing_root

		if pos and idx >= 1 and idx <= #widgets then
			local item = root.children[pos]
			local target = widgets[idx]
			item.visible = true
			item.x = target.x - 0.02
			item.y = target.y - 0.02
			item.w = (target.w or 1) + 0.06
			item.h = (target.h or 1) + 0.06
		end
	end

	do
		local itemlist = {}

		for k, v in ipairs(context.current_widget_params) do
			local value = v.value
			if type(v.value) == "string" then
				value = "\"" .. v.value .. "\""
			end
			table.insert(itemlist, v.param .. " = " .. tostring(value))
		end

		root.children[FIND("paramslist")].itemlist = itemlist
	end

	do
		local pos = FIND("widgetlist")
		local itemlist = {}

		for name, _ in pairs(formspec.WIDGET_TYPES) do
			table.insert(itemlist, name)
		end

		table.sort(itemlist)
		root.children[pos].itemlist = itemlist
		context.known_widget_names = itemlist
	end

	do
		local pos = FIND("activewidgets")
		local itemlist = {}

		for _, v in ipairs(context.editing_root) do
			table.insert(itemlist, (v.type .. " [" .. (v.name or "") .. "]"))
		end

		root.children[pos].itemlist = itemlist
	end

	-- Construct the workpiece being edited so we can show what it looks like.
	if context.editing_root then
		local pos = FIND("testGUIend")
		for _, info in ipairs(context.editing_root) do
			table.insert(root.children, pos, info)
			pos = pos + 1 -- Insert items in order.
		end
	end

	context.root = original_root -- Remember the original GUI table.
	return formspec.create_formspec_from_table(root)
end



-- Called from chatcommand.
function formspec.show_editor(pname, param)
	-- Reuse existing context if present.
	formspec.EDITOR_CONTEXTS[pname] = formspec.EDITOR_CONTEXTS[pname] or {
		original_param = param, -- Original chatcommand param.
		root = {}, -- A copy of the original GUI table, MINUS the edited GUI.
		editing_root = {}, -- A flat array of all edited/managed GUI table infos.
		current_widget_params = {}, -- Array of {param="key", value=<val>} subtables.
		known_widget_names = {}, -- Array of registered widget names.
		last_error = "",
		default_edit_parameter = "",
	}

	local serialized = formspec.make_editor(pname)
	minetest.show_formspec(pname, "formspec:editor", serialized)
end



local function handle_add_widget(context, fields)
	if not fields.add_widget then
		return
	end

	local params = {}

	-- Convert array of subtables to regular widget description table (dict).
	for k, v in ipairs(context.current_widget_params) do
		params[v.param] = v.value
	end

	if type(params.type) ~= "string" then
		context.last_error = "Missing mandatory type name."
		return
	end

	-- Prevent user from messing up the editor GUI.
	if type(params.FORMSPEC_ID) ~= "nil" then
		context.last_error = "Do NOT use internal GUI editor names."
		return
	end

	local widget = formspec.WIDGET_TYPES[params.type]
	if not widget then
		context.last_error = "Cannot create unknown widget."
		return
	end
	if not widget.make_params then
		context.last_error = "Widget not constructable."
		return
	end

	-- Invent default names for widgets that have name parameters but they're empty.
	if params.name and #params.name == 0 then
		local t = params.type
		local c = 1

		-- Count up all widgets of the same type.
		for _, v in ipairs(context.editing_root) do
			if v.type == t then
				c = c + 1
			end
		end

		-- Build name string.
		local s = t .. c
		params.name = s
	end

	-- Make sure we're not adding GUI elements with duplicate or reserved names.
	-- That will break stuff.
	if params.name then
		for k, v in ipairs(context.root.children) do
			if v.name and v.name == params.name then
				context.last_error = "Cannot create widget using EDITOR reserved name."
				return
			end
		end
		for k, v in ipairs(context.editing_root) do
			if v.name and v.name == params.name then
				context.last_error = "You've already added a widget with that name."
				return
			end
		end
	end

	-- Make sure minimum parameters are provided matching what the widget wants.
	local wanted_params = widget.make_params()
	for k, v in pairs(wanted_params) do
		if type(params[k]) ~= type(v) then
			context.last_error = "Missing required parameter, or wrong parameter type."
			return
		end
	end

	table.insert(context.editing_root, params)
	context.last_error = "Success: added " .. params.type .. " [" .. (params.name or "") .. "]."
	context.selected_active_widget = #context.editing_root
	return true
end



local function handle_param_edit(context, fields)
	if fields.key_enter_field ~= "paramfield" then
		return
	end

	context.last_error = "What are you doing?"
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
		if not context.selected_active_widget or tokens[1] ~= "type" then
			if tokens[2] ~= "nil" then
				context.current_widget_params[pos].value = TOTYPE(tokens[2])
				context.last_error = "Updated parameter."
			else
				table.remove(context.current_widget_params, pos)
				context.last_error = "Parameter removed from table."
			end
		else
			context.last_error = "Cannot change type of existing created widget."
			return
		end
	else
		if tokens[2] ~= "nil" then
			table.insert(context.current_widget_params, {param=tokens[1], value=TOTYPE(tokens[2])})
			context.last_error = "Added new parameter."
		else
			context.last_error = "Parameter doesn't exist; nothing to be done."
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

	local name = widgets[idx]
	if not formspec.WIDGET_TYPES[name] then
		context.current_widget_params = {}
		context.last_error = "Selected unknown widget type!"
		return
	end

	context.last_error = "Selected: " .. name .. "."
	local widget = formspec.WIDGET_TYPES[name]

	if not widget.make_params then
		context.current_widget_params = {}
		context.last_error = "Widget type not constructable."
		return
	end

	local params = widget.make_params()
	local new_param_list = {}

	for k, v in pairs(params) do
		table.insert(new_param_list, {param=k, value=v})
	end

	table.sort(new_param_list, function(a, b)
		return a.param < b.param
	end)

	context.current_widget_params = new_param_list
	context.selected_active_widget = nil
end



local function handle_active_select(context, fields)
	if not fields.activewidgets then
		return
	end

	local tab = minetest.explode_textlist_event(fields.activewidgets)
	local idx = tab.index
	local widgets = context.editing_root

	if not (tab.type == "DCL" and idx >= 1 and idx <= #widgets) then
		return -- Normal.
	end

	local new_param_list = {}

	for k, v in pairs(widgets[idx]) do
		table.insert(new_param_list, {param=k, value=v})
	end

	table.sort(new_param_list, function(a, b)
		return a.param < b.param
	end)

	context.current_widget_params = new_param_list
	context.selected_active_widget = idx
	context.last_error = "Selected widget " .. idx .. " (" .. widgets[idx].type .. " [" .. (widgets[idx].name or "") .. "])."
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
		formspec.EDITOR_CONTEXTS[pname] = nil
		return
	end

	handle_param_edit(context, fields)
	handle_param_select(context, fields)
	handle_widget_select(context, fields)
	handle_active_select(context, fields)
	handle_add_widget(context, fields)

	-- No need to call other field handlers.
	formspec.show_editor(pname, formspec.EDITOR_CONTEXTS[pname].original_param)
	return true
end
