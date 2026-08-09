
-- Turn a formtable into a GUI object by adding methods to it.
-- You can then use the returned table-object in your code much easier than
-- the raw formtable, since it has helper methods attached.
-- Basically all this does is make a copy of the table, attach methods,
-- and return the new table.
function formspec.create_gui_object(formtable)
	-- Minimum required elements to be a valid formtable.
	if not formtable.children or not formtable.size then
		return
	end

	local tab = table.copy(formtable)

	-- Install methods.
	function tab:to_formspec()
		return formspec.create_formspec_from_table(self)
	end

	-- Returns widget-table, index or nil.
	-- You can modify the table directly (remember to call formtable:to_formspec() ).
	function tab:get_control_by_name(name)
		for index, widget in ipairs(self.children) do
			if widget.name and widget.name == name then
				return widget, index
			end
		end
	end

	-- Returns widget-table, index or nil.
	-- You can modify the table directly (remember to call formtable:to_formspec() ).
	-- Not all formspec elements can have names, that's why this method exists.
	function tab:get_control_by_id(name)
		for index, widget in ipairs(self.children) do
			if widget.FORMID and widget.FORMID == name then
				return widget, index
			end
		end
	end

	-- Returns the FIRST matching widget-table (of type), index or nil.
	-- You can modify the table directly (remember to call formtable:to_formspec() ).
	function tab:get_control_by_type(name)
		for index, widget in ipairs(self.children) do
			if widget.type and widget.type == name then
				return widget, index
			end
		end
	end

	return tab
end
