
-- Call this for your mod's namespace to quickly add a simple callback "signal/slot" system.
-- This function is safe to call multiple times (data not clobbered).
function reload.install_simple_signals(to_namespace)
	-- Don't clobber if already exists.
	to_namespace._SIGSLOT_CALLBACKS = to_namespace._SIGSLOT_CALLBACKS or {}

	function to_namespace.run_callbacks(name, ...)
		for _, cb in ipairs(to_namespace._SIGSLOT_CALLBACKS) do
			if cb.name == name and cb.action then
				cb.action(...)
			end
		end
	end

	-- Like 'run_callbacks' but does so on the next server step, OUTSIDE the calling stack frame.
	-- If you aren't into computer science enough to know what a stack frame is, don't worry.
	-- That stuff is for wizards.
	function to_namespace.run_callbacks_after(name, ...)
		minetest.after(0, to_namespace.run_callbacks, name, ...)
	end

	-- It's safe to call this function more than once (e.g., mod reload).
	-- Will not register a named callback more than once per target namespace.
	function to_namespace.register_callback(name, func)
		for _, cb in ipairs(to_namespace._SIGSLOT_CALLBACKS) do
			if cb.name == name then
				return -- Already registered.
			end
		end

		table.insert(to_namespace._SIGSLOT_CALLBACKS, {name=name, action=func})
	end
end
