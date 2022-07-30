------------------------------------------------------------------------------
-- This file is registered as reloadable.
------------------------------------------------------------------------------

reload = reload or {}
reload.impl = reload.impl or {}
reload.impl.files = reload.impl.files or {}



reload.file_registered = function(id)
	assert(type(id) == "string") -- Foolproof us!
	if reload.impl.files[id] then return true else return false end
end



reload.register_file = function(id, file, noload)
	-- Foolproof us!
	assert(type(id) == "string")
	assert(type(file) == "string")
	
	-- This file cannot already have been registered.
	assert(reload.impl.files[id] == nil)
	
	-- Execute the file once.
	-- Registering the file also executes it, so doing this is the equivalent of using 'dofile',
	-- but with the added benefit of being able to execute the file again and again as needed.
	if noload == true or noload == nil then dofile(file) end
	reload.impl.files[id] = file
end



-- Check if file exists, and register/execute it only if it does.
reload.register_optional = function(id, path)
	-- Foolproof us!
	assert(type(id) == "string")
	assert(type(path) == "string")

	-- This file cannot already have been registered.
	assert(reload.impl.files[id] == nil)

	local file = io.open(path)
	if file then
		-- File exists, we can execute it.
		reload.impl.files[id] = path
		dofile(path)
	end
end
