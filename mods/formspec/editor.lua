
-- Contexts for users who have the "formspec editor" panel open.
formspec.EDITOR_CONTEXTS = formspec.EDITOR_CONTEXTS or {}
formspec.SAVED_CONTEXTS = formspec.SAVED_CONTEXTS or {}

local MIN_FORM_WIDTH = 3
local MIN_FORM_HEIGHT = 2



local function highlight_selected_widget(context)
	-- Show a bright box around the currently selected widget.
	local idx = context:get_selected_widget()
	local widgets = context:get_editing_root()
	local selector = {type="box", x=0, y=0, w=1, h=1, color="#ff0000ff"}
	local _, begpos = context:get_control_by_id("testGUIbegin")

	if idx then
		local target = widgets[idx]

		-- Certain widgets (like end tags) don't exist in space.
		if not target.x or not target.y then
			return
		end

		if target.type == "checkbox" then
			-- Checkboxes don't have W, H.
			selector.x = target.x - 0.05
			selector.y = target.y - 0.2
			selector.w = 0.4
			selector.h = 0.4
		else
			selector.x = target.x - 0.02
			selector.y = target.y - 0.02
			selector.w = (target.w or 1) + 0.06
			selector.h = (target.h or 1) + 0.06
		end

		local targetpos = idx + begpos
		table.insert(context.root.children, targetpos, selector)
	end
end



local function show_form_borders(context)
	local _, idx = context:get_control_by_id("testGUIbegin")
	local g = context:get_form_geometry()
	local t = 0.02

	local boxes = {
		{x=0, y=0, w=g.x, h=t},
		{x=0, y=0, w=t, h=g.y},
		{x=g.x-t, y=0, w=t, h=g.y},
		{x=0, y=g.y-t, w=g.x, h=t},
	}

	for _, v in ipairs(boxes) do
		table.insert(context.root.children, idx, {type="box", x=v.x, y=v.y, w=v.w, h=v.h, color="#00ff00ff"})
	end
end



function formspec.make_editor(pname)
	local context = formspec.EDITOR_CONTEXTS[pname]
	if not context then return "" end

	local TEST_SIZE = table.copy(context.FormGeom)
	local TEST_PAD = 0.5
	local INIT_SIZE = table.copy(context.FormGeom)
	INIT_SIZE.x = INIT_SIZE.x + 9 + TEST_PAD
	INIT_SIZE.y = math.max(10, INIT_SIZE.y)

	local NEWROOT = {
		size = INIT_SIZE,

		children = {
			-- Shows what the currently-edited formspec looks like.
			{type="container", x=0, y=0, FORMSPEC_ID="testGUIbegin"},
			-- DO NOT add any elements between here and TEST GUI container end!
			-- If you do, you will need to adjust magic numbers elsewhere in the code.
			{type="container_end", FORMSPEC_ID="testGUIend"},

			-- Editor formspec with controls.
			{type="background9", x=TEST_SIZE.x+TEST_PAD, y=0, w=9, h=10, texture="gui_formbg.png", x1=50},
			{type="tabheader", x=TEST_SIZE.x+TEST_PAD, y=0, w=9, h=0.5, name="EditorTabs", itemlist={"Form", "Widgets", "Save/Load", "Styling"}, current_tab=context.current_form_tab},

			-- Widget panel.
			{type="container", x=TEST_SIZE.x+TEST_PAD, y=0, FORMSPEC_ID="EditorFSContainer2"},
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
			{type="checkbox", name="stepsizeSelector1", x=0, y=0, label="0.1"},
			{type="checkbox", name="stepsizeSelector2", x=0, y=0.35, label="0.01"},
			{type="container_end"},
			{type="container_end"},

			-- Form controls.
			{type="container", x=TEST_SIZE.x+TEST_PAD, y=0, FORMSPEC_ID="EditorFSContainer1"},

			{type="container", x=2.3, y=0.4+0.53},
			{type="checkbox", name="FormStepSizeSelector1", x=0, y=0, label="0.1"},
			{type="checkbox", name="FormStepSizeSelector2", x=0, y=0.35, label="0.01"},
			{type="label", x=0, y=0.6, w=5, h=0.35, text="", FORMSPEC_ID="FormWLabel"},
			{type="label", x=0, y=0.6+0.35, w=5, h=0.35, text="", FORMSPEC_ID="FormHLabel"},
			{type="container_end"},

			-- Form size controls.
			{type="container", x=0.5, y=0.4},
			{type="label", x=0, y=0, w=3, h=0.35, text="Form Dimensions"},
			{h=0.5, move_step=0.1, label="▲", name="FORM_size_up", type="button", w=0.5, x=0.5, y=0+0.38},
			{h=0.5, move_step=0.1, label="▼", name="FORM_size_down", type="button", w=0.5, x=0.5, y=1+0.38},
			{h=0.5, move_step=0.1, label="◀", name="FORM_size_left", type="button", w=0.5, x=0, y=0.5+0.38},
			{h=0.5, move_step=0.1, label="▶", name="FORM_size_right", type="button", w=0.5, x=1, y=0.5+0.38},
			{h=0.5, move_step=0.5, label="⇓", name="FORM_size_down2", type="button", w=0.5, x=1, y=1+0.38},
			{h=0.5, move_step=0.5, label="⇑", name="FORM_size_up2", type="button", w=0.5, x=0, y=0+0.38},
			{h=0.5, move_step=0.5, label="⇐", name="FORM_size_left2", type="button", w=0.5, x=0, y=1+0.38},
			{h=0.5, move_step=0.5, label="⇒", name="FORM_size_right2", type="button", w=0.5, x=1, y=0+0.38},
			{type="container_end"},

			{type="container_end"},

			-- Save/load.
			{type="container", x=TEST_SIZE.x+TEST_PAD, y=0, FORMSPEC_ID="EditorFSContainer3"},
			{type="container_end"},

			-- Styling.
			{type="container", x=TEST_SIZE.x+TEST_PAD, y=0, FORMSPEC_ID="EditorFSContainer4"},
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

	if context.step_size_selector == 1 then
		context:get_control_by_name("stepsizeSelector1").selected = true
	elseif context.step_size_selector == 2 then
		context:get_control_by_name("stepsizeSelector2").selected = true
	end

	if context.formsize_step_size_selector == 1 then
		context:get_control_by_name("FormStepSizeSelector1").selected = true
	elseif context.formsize_step_size_selector == 2 then
		context:get_control_by_name("FormStepSizeSelector2").selected = true
	end

	if context.current_form_tab == 1 then
		-- Form controls.
		context:get_control_by_id("EditorFSContainer1").visible = true
		context:get_control_by_id("EditorFSContainer2").visible = false
		context:get_control_by_id("EditorFSContainer3").visible = false
		context:get_control_by_id("EditorFSContainer4").visible = false
		show_form_borders(context)
	elseif context.current_form_tab == 2 then
		-- Widget editor.
		context:get_control_by_id("EditorFSContainer1").visible = false
		context:get_control_by_id("EditorFSContainer2").visible = true
		context:get_control_by_id("EditorFSContainer3").visible = false
		context:get_control_by_id("EditorFSContainer4").visible = false
	elseif context.current_form_tab == 3 then
		-- Save/load.
		context:get_control_by_id("EditorFSContainer1").visible = false
		context:get_control_by_id("EditorFSContainer2").visible = false
		context:get_control_by_id("EditorFSContainer3").visible = true
		context:get_control_by_id("EditorFSContainer4").visible = false
	elseif context.current_form_tab == 4 then
		-- Syling.
		context:get_control_by_id("EditorFSContainer1").visible = false
		context:get_control_by_id("EditorFSContainer2").visible = false
		context:get_control_by_id("EditorFSContainer3").visible = false
		context:get_control_by_id("EditorFSContainer4").visible = true
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

	local FormGeom = context:get_form_geometry()
	context:get_control_by_id("FormWLabel").text = "X: " .. FormGeom.x
	context:get_control_by_id("FormHLabel").text = "Y: " .. FormGeom.y

	-- Show a bright box around the currently selected widget.
	-- This needs to be done *after* all the test GUI widgets are added to the
	-- display, because the selection box is injected into the widget list.
	highlight_selected_widget(context)

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



local function add_default_starting_widgets(root)
	table.insert(root, {type="background9", x=0, y=0, w=9, h=10, texture="gui_formbg.png", x1=50})
end



local function create_new_editor_context(pname, param)
	local root = {
		original_param = param, -- Original chatcommand param.
		root = {}, -- A copy of the original GUI table, MINUS the edited GUI.
		editing_root = {}, -- A flat array of all edited/managed GUI table infos.
		current_widget_params = {}, -- Array of {param="key", value=<val>} subtables.
		known_widget_names = {}, -- Array of registered widget names.
		last_error = "",
		default_edit_parameter = "",
		step_size_selector = 1,
		formsize_step_size_selector = 1,
		current_form_tab = 2,
		FormGeom = {x=9, y=10},

		get_form_geometry = function(self)
			return {x=self.FormGeom.x, y=self.FormGeom.y}
		end,

		set_form_geometry = function(self, geom)
			if geom.x < MIN_FORM_WIDTH then geom.x = MIN_FORM_WIDTH end
			if geom.y < MIN_FORM_HEIGHT then geom.y = MIN_FORM_HEIGHT end
			self.FormGeom = geom
		end,

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
			-- We have to make sure we only search widgets *after* the end of the test GUI list.
			-- Otherwise we'd return widgets that are part of the test GUI.
			local _, pos = self:get_control_by_id("testGUIend")

			for index, widget in ipairs(self.root.children) do
				if index > pos and widget.name and widget.name == name then
					return widget, index
				end
			end
		end,

		get_control_by_id = function(self, name)
			for index, widget in ipairs(self.root.children) do
				if widget.FORMSPEC_ID and widget.FORMSPEC_ID == name then
					return widget, index
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

		get_widget_by_type = function(self, typename)
			for index, info in ipairs(self:get_editing_root()) do
				if info.type == typename then
					return info, index
				end
			end
		end,
	}

	add_default_starting_widgets(root.editing_root)

	return root
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



local function validate_active_params(context, replace_index)
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

	local factory = formspec.WIDGET_TYPES[params.type]
	if not factory then
		context:set_error("Cannot create unknown widget.")
		return
	end
	if not factory.make_params then
		context:set_error("Widget not constructable.")
		return
	end
	if factory.allow_editor_creation ~= nil and not factory.allow_editor_creation then
		context:set_error("Widget creation disallowed.")
		return
	end

	-- Do NOT allow names beginning with "key_".
	if params.name then
		if params.name:find("^key_") then
			context:set_error("Cannot create widget with engine-reserved name.")
			return
		end

		if not params.name:find("^[_%w]+$") then
			context:set_error("Invalid name.")
			return
		end
	end

	-- Make sure we're not adding GUI elements with duplicate or reserved names.
	-- That will break stuff.
	if params.name then
		if context:get_control_by_name(params.name) then
			context:set_error("Cannot create widget using editor reserved name.")
			return
		end

		for index, v in ipairs(widgets) do
			if v.name and v.name == params.name then
				if not (replace_index and replace_index == index) then
					context:set_error("You've already added a widget with that name.")
					return
				end
			end
		end
	end

	-- Make sure minimum parameters are provided matching what the widget wants.
	local wanted_params = factory.make_params()
	for k, v in pairs(wanted_params) do
		if type(params[k]) ~= type(v) then
			context:set_error("Missing required parameter, or wrong parameter type.")
			return
		end
	end

	return true
end



local function handle_add_widget(context, fields)
	if not fields.add_widget then
		return
	end

	local widgets = context:get_editing_root()
	local params = context:get_widget_params()

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

	if not validate_active_params(context) then
		return
	end

	table.insert(widgets, params)

	-- If the widget requires a matching end tag, add that.
	local factory = formspec.WIDGET_TYPES[params.type]
	if factory.end_tag then
		local info = formspec.WIDGET_TYPES[factory.end_tag]
		table.insert(widgets, info.make_params())
	end

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

	if not idx then
		context:set_error("No selected widget to remove.")
		return
	end

	local info = formspec.WIDGET_TYPES[widgets[idx].type]
	if info.allow_editor_deletion ~= nil and not info.allow_editor_deletion then
		context:set_error("Cannot delete that widget.")
		return
	end

	-- If the widget is paired with an end tag, delete that, too.
	-- Delete end tag *before* deleting start tag, because array position will change!
	if info.end_tag then
		for i = idx + 1, #widgets, 1 do
			local otype = widgets[i].type
			if otype == info.end_tag then
				table.remove(widgets, i)
				break
			end
		end
	end

	local removed = table.remove(widgets, idx)

	if idx > #widgets then
		idx = #widgets
	end

	context:set_selected_widget(idx)
	context:set_message("Removed " .. removed.type .. " [" .. (removed.name or "") .. "] widget.")
end



local function handle_param_edit(context, fields)
	if fields.key_enter_field ~= "paramfield" then
		return
	end

	context:set_error("What are you doing?")
	context.default_edit_parameter = nil
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

		if not context:get_selected_widget() or tokens[1] ~= "type" then
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

	-- Update parameters of the currently selected active widget.
	local idx = context:get_selected_widget()
	local widgets = context:get_editing_root()

	if not idx then
		return
	end

	if not validate_active_params(context, idx) then
		context:set_editing_parameters(widgets[idx])
		return
	end

	widgets[idx] = context:get_widget_params()
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

	local function may_move_dn()
		local this_type = widgets[idx].type
		local under_type = widgets[idx + 1].type
		local this_info = formspec.WIDGET_TYPES[this_type]
		local under_info = formspec.WIDGET_TYPES[under_type]

		if (this_info.begin_tag or this_info.end_tag) and (under_info.begin_tag or under_info.end_tag) then
			return false
		end

		return true
	end

	local function may_move_up()
		local this_type = widgets[idx].type
		local above_type = widgets[idx - 1].type
		local this_info = formspec.WIDGET_TYPES[this_type]
		local above_info = formspec.WIDGET_TYPES[above_type]

		if (this_info.begin_tag or this_info.end_tag) and (above_info.begin_tag or above_info.end_tag) then
			return false
		end

		return true
	end

	if fields.move_order_dn and idx < #widgets then
		if may_move_dn() then
			local tmp = widgets[idx + 1]
			widgets[idx + 1] = widgets[idx]
			widgets[idx] = tmp
			context:set_selected_widget(idx + 1)
		end
	end

	if fields.move_order_up and idx > 1 then
		if may_move_up() then
			local tmp = widgets[idx - 1]
			widgets[idx - 1] = widgets[idx]
			widgets[idx] = tmp
			context:set_selected_widget(idx - 1)
		end
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

	if not target.x or not target.y then
		-- Not all widgets exist in space.
		return
	end

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



local function handle_size_form(context, fields)
	local buttons = {
		FORM_size_left = {x=-1, y=0, z=0},
		FORM_size_right = {x=1, y=0, z=0},
		FORM_size_up = {x=0, y=-1, z=0},
		FORM_size_down = {x=0, y=1, z=0},
		FORM_size_left2 = {x=-1, y=0, z=0},
		FORM_size_right2 = {x=1, y=0, z=0},
		FORM_size_up2 = {x=0, y=-1, z=0},
		FORM_size_down2 = {x=0, y=1, z=0},
	}

	local MIN_W = MIN_FORM_WIDTH
	local MIN_H = MIN_FORM_HEIGHT

	local target = context:get_form_geometry()

	for fieldname, info in pairs(buttons) do
		if fields[fieldname] then
			local step = context:get_control_by_name(fieldname).move_step

			if context.formsize_step_size_selector == 2 and step < 0.5 then
				step = 0.01
			end

			local curpos = {x=target.x, y=target.y, z=0}
			local newpos = vector.add(vector.multiply(info, step), curpos)

			target.x = newpos.x
			target.y = newpos.y

			if target.x < MIN_W then target.x = MIN_W end
			if target.y < MIN_H then target.y = MIN_H end

			-- Round to nearest hundredths.
			target.x = math.round(target.x * 100) / 100
			target.y = math.round(target.y * 100) / 100

			context:set_form_geometry(target)
			local actgeom = context:get_form_geometry()

			-- If a background is available, we can use that for visual feedback.
			local widget = context:get_widget_by_type("background9")
			if widget then
				widget.x = 0
				widget.y = 0
				widget.w = actgeom.x
				widget.h = actgeom.y
			end

			break
		end
	end
end



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



local function handle_binary_selector_ex(context, fields, name1, name2)
	if fields[name1] then
		local bs = fields[name1]
		if toboolean(bs) then
			context:get_control_by_name(name1).selected = true
			context:get_control_by_name(name2).selected = false
			return 1
		else
			context:get_control_by_name(name1).selected = false
			context:get_control_by_name(name2).selected = true
			return 2
		end
	end

	if fields[name2] then
		local bs = fields[name2]
		if toboolean(bs) then
			context:get_control_by_name(name1).selected = false
			context:get_control_by_name(name2).selected = true
			return 2
		else
			context:get_control_by_name(name1).selected = true
			context:get_control_by_name(name2).selected = false
			return 1
		end
	end
end



local function handle_step_selector(context, fields)
	local val = handle_binary_selector_ex(context, fields, "stepsizeSelector1", "stepsizeSelector2")
	if val == 1 then
		context.step_size_selector = 1
	elseif val == 2 then
		context.step_size_selector = 2
	end
end



local function handle_formsize_step_selector(context, fields)
	local val = handle_binary_selector_ex(context, fields, "FormStepSizeSelector1", "FormStepSizeSelector2")
	if val == 1 then
		context.formsize_step_size_selector = 1
	elseif val == 2 then
		context.formsize_step_size_selector = 2
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



local function handle_switch_editor_tab(context, fields)
	if fields.EditorTabs then
		if fields.EditorTabs == "1" then
			context.current_form_tab = 1
		elseif fields.EditorTabs == "2" then
			context.current_form_tab = 2
		elseif fields.EditorTabs == "3" then
			context.current_form_tab = 3
		elseif fields.EditorTabs == "4" then
			context.current_form_tab = 4
		end
	end
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
	handle_formsize_step_selector(context, fields)
	handle_live_select(context, fields)
	handle_logdump(context, fields)
	handle_switch_editor_tab(context, fields)
	handle_size_form(context, fields)

	-- No need to call other field handlers.
	formspec.show_editor(pname, formspec.EDITOR_CONTEXTS[pname].original_param)
	return true
end
