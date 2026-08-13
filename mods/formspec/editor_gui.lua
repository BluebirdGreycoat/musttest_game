
return {
	size = {x=0, y=0},

	children = {
		-- The fake dropdown helps us distinguish between when the dropdown is directly manipulated vs when it isn't.
		-- It is located far off the formspec bounds where hopefully no one will ever see it.
		{h=1, itemlist={}, name="FakeDropdown", type="dropdown", w=1, x=100, y=1},

		-- Shows what the currently-edited formspec looks like.
		{type="container", x=0, y=0, FORMSPEC_ID="testGUIbegin"},
		-- DO NOT add any elements between here and TEST GUI container end!
		-- If you do, you will need to adjust magic numbers elsewhere in the code.
		{type="container_end", FORMSPEC_ID="testGUIend"},

		-- Editor formspec with controls.
		{type="container", x=0, y=0, FORMSPEC_ID="EditorOffsetContainer"},
		{type="container", x=0, y=0, FORMSPEC_ID="EditorFSContainer0"},
		{type="background9", x=0, y=0, w=9, h=10, texture="gui_formbg.png", x1=50},
		{type="tabheader", x=0, y=0, w=9, h=0.5, name="EditorTabs", itemlist={"Form", "Widgets", "Save/Load", "Styling", "Events", "Table"}},
		{type="box", x=0.5, y=9.3, w=8, h=0.35, color="#00000055"},
		{type="label", x=0.5, y=9.3, w=8, h=0.35, text="No error.", show_box=false, FORMSPEC_ID="errordisplay"},
		{type="container_end"},

		-- Widget panel.
		{type="container", x=0, y=0, FORMSPEC_ID="EditorFSContainer2"},
		{type="button", x=0.5, y=8.5, w=2.0, h=0.5, name="logdump", label="Dump To Log", tooltip="Writes the edited GUI parameters to the logfile."},

		-- List of current/active parameters.
		{type="container", x=0.5, y=0.4},
		{type="label", x=0, y=0, w=4.5, h=0.35, text="Parameter List", FORMSPEC_ID="paramslistLabel"},
		{type="textlist", x=0, y=0.4, w=4.5, h=3.5, name="paramslist", FORMSPEC_ID="paramslist", tooltip="This shows the list of current widget parameters."},
		{type="field", x=0, y=4.4, w=4.5, h=0.4, name="paramfield", label="Edit Parameter:", close_on_enter=false, tooltip="Type <key>=<value> to enter a parameter. Type <key>=nil to remove."},
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
		{type="container", x=0, y=0, FORMSPEC_ID="EditorFSContainer1"},
		{type="button", x=0.5, y=8.5, w=2.0, h=0.5, name="FormTabHideEditor", label="Hide Editor", tooltip="Hide the editor GUI so you can view the formspec by itself.\nPress ESC to return to the editor."},
		{type="button", x=2.6, y=8.5, w=2.4, h=0.5, name="FormTabExportToLog", label="Export to Log", tooltip="Dump complete GUI definitions to debug.txt.\nYou can copy the output to a file and load it with dofile()."},

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
		{type="container", x=0, y=0, FORMSPEC_ID="EditorFSContainer3"},
		{h=10, texture="gui_formbg.png", type="background9", w=9, x=0, x1=50, y=0},
		{h=0.33, text="Saved Formspecs", type="label", w=7.96, x=0.5, y=0.4},
		{h=3, name="SavedFormspecList", type="textlist", w=8, x=0.5, y=0.8},
		{h=0.5, label="Load Selected", name="LoadSelectedFormspec", type="button", w=2, x=0.5, y=4, tooltip="Load selected formspec into workspace.\nWill overwrite whatever's already there."},
		{h=0.5, label="Delete", name="DeleteSelectedFormspec", type="button", w=1.7, x=6.82, y=4, tooltip="Delete selected formspec. There are no undos.", style={bgcolor="red"}},
		{h=0.3, text="", type="label", w=5.85, x=2.6, y=4.1, FORMSPEC_ID="SelectedFileNameLabel"},
		{color="#00000055", h=0.1, type="box", w=8, x=0.5, y=4.72},
		{h=0.33, text="Active Formstring (Preview)", type="label", w=7.96, x=0.5, y=5},
		{h=2.8, label="", name="ActiveFormstringDisplay", text="", type="textarea", w=8, x=0.5, y=5.5},
		{h=0.5, label="Save Formspec", name="SaveActiveFormspec", type="button", w=2, x=0.5, y=8.5},
		{type="checkbox", name="AllowOverwrite", x=2.65, y=8.75, label="Overwrite"},
		{h=0.3, text="Name:", type="label", w=1, x=4.7, y=8.59},
		{close_on_enter=false, default="", h=0.5, label="", name="SaveNameEntry", type="field", w=3, x=5.5, y=8.5},
		{type="container_end"},

		-- Styling.
		{type="container", x=0, y=0, FORMSPEC_ID="EditorFSContainer4"},
		{type="container", x=0.5, y=0.4},
		{h=0.35, text="Style Parameters", type="label", w=4.5, x=0, y=0},
		{h=3.5, name="ActiveStyleParameters", type="textlist", w=4.5, x=0, y=0.4},
		{close_on_enter=false, default="", h=0.4, label="Edit Parameter:", name="EditStyleParameter", type="field", w=4.5, x=0, y=4.4},
		{type="container_end"},
		{type="container", x=5.5, y=0.4},
		{h=0.35, text="Constructed Widgets", type="label", w=3, x=0, y=0},
		{h=4.4, name="StyleableWidgetList", type="textlist", w=3, x=0, y=0.4},
		{type="container_end"},
		{h=3.28, label="Style Docs", style={font="mono", font_size="*0.85", textcolor="black"}, name="StyleEditorDocs", text="", type="textarea", w=8, x=0.5, y=5.7},
		{type="container_end"},

		-- Events.
		{type="container", x=0, y=0, FORMSPEC_ID="EditorFSContainer5"},
		{h=10, texture="gui_formbg.png", type="background9", w=9, x=0, x1=50, y=0},
		{h=0.7, text="Interact with any widget in the test GUI to see response fields.", type="label", w=4.5, x=0.5, y=0.5},
		{h=7.48, label="", name="EventResponseDisplay", style={font="mono", font_size="*0.9", textcolor="red"}, type="textarea", w=8, x=0.5, y=1.5},
		{type="container_end"},

		{type="container", x=0, y=0, FORMSPEC_ID="EditorFSContainer6"},
		{h=10, texture="gui_formbg.png", type="background9", w=9, x=0, x1=50, y=0},
		{h=0.35, text="Table Column Editor", type="label", w=8, x=0.5, y=0.4},
		{h=0.5, label="Add", name="EditTableAddColumn", type="button", w=1, x=0.5, y=4.62},
		{h=0.5, label="Del", name="EditTableRemoveColumn", type="button", w=1, x=1.6, y=4.62},
		{h=0.5, label="▲", name="EditTableMoveColumnUp", type="button", w=0.5, x=2.9, y=4.62},
		{h=0.5, label="▼", name="EditTableMoveColumnDown", type="button", w=0.5, x=3.5, y=4.62},
		{h=0.5, itemlist={"", "Text", "Image", "Color", "Indent", "Tree"}, name="EditTableChooseColumnType", type="dropdown", w=3.5, x=5, y=0.8, index_event=false},
		{h=0.35, text="Chose Column Type", type="label", w=3.5, x=5, y=0.4},
		{h=0.35, text="Column Params", type="label", w=3.5, x=5, y=1.5},
		{h=2.3, name="EditTableColumnParams", type="textlist", w=3.5, x=5, y=1.9},
		{close_on_enter=false, default="", h=0.4, label="Edit Parameter:", name="EditTableEditColumnParameter", tooltip="Type <key>=<value> to enter a parameter. Type <key>=nil to remove.", type="field", w=3.5, x=5, y=4.7},
		{h=3.6, name="EditTableColumnsDisplay", type="textlist", w=3.5, x=0.5, y=0.8},
		{h=0.35, text="Row Data Editor (For Previewing)", type="label", w=8, x=0.5, y=5.55},
		{h=2.28, label="", style={font="mono", font_size="*0.9"}, name="EditTableRowDataText", tooltip="Use this box to input test data.\nSeparate cells with commas.\nLine breaks are also accepted.", type="textarea", w=8, x=0.5, y=6},
		{h=0.5, label="Get Data", name="EditTableGetRows", type="button", w=1.7, x=0.5, y=8.5},
		{h=0.5, label="Submit Row Data", name="EditTableSubmitRows", tooltip="Set row data on the currently selected table widget.", type="button", w=2.5, x=2.3, y=8.5},
		{type="container_end"},
		{type="container_end"},
	},
}
