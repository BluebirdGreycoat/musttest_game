
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

	function to_namespace.register_callback(name, func)
		table.insert(to_namespace._SIGSLOT_CALLBACKS, {name=name, action=func})
	end
end
