
fortress.v2.SQL_DATABASE_FILE =
	minetest.get_worldpath() .. "/fortdata.v2.sql"



local function execute_statement(stmt, values)
	if not fortress.v2.SQL_LIB then return end
	if not fortress.v2.SQL_DATABASE_OBJ then return end

	local SQL_ROW = fortress.v2.SQL_LIB.ROW
	local SQL_DONE = fortress.v2.SQL_LIB.DONE
	local SQL_OK = fortress.v2.SQL_LIB.OK

	local db = fortress.v2.SQL_DATABASE_OBJ
	local allrows, status
	local obj = db:prepare(stmt)
	if not obj then return end

	local function geterr()
		local msg = db:errmsg()
		minetest.log("error", "SQLite3 Error: " .. msg)
	end

	if type(values) == "table" then
		if obj:bind_values(unpack(values)) ~= SQL_OK then return geterr() end
	end

	for row in obj:nrows() do
		if not allrows then allrows = {} end
		allrows[#allrows + 1] = row
	end

	status = db:errcode()
	if status ~= SQL_DONE and status ~= SQL_OK then return geterr() end
	if obj:finalize() ~= SQL_OK then return geterr() end

	return true, allrows
end



local function init_lib()
	local ENV = minetest.request_insecure_environment()
	if not ENV then
		minetest.log("error", "[fortress] need insecure ENV for full experience")
		return
	end

	local success, lib = pcall(ENV.require, "lsqlite3")
	if not success then
		minetest.log("error", "[fortress] need SQL for full experience")
		return
	end

	fortress.v2.SQL_LIB = lib
	if sqlite3 then sqlite3 = nil end -- Leakage.
	return true
end



local function open_database()
	local database = fortress.v2.SQL_LIB.open(fortress.v2.SQL_DATABASE_FILE)
	if database and database.exec then
		fortress.v2.SQL_DATABASE_OBJ = database
		return true
	end

	minetest.log("error",
		"Could not open SQL database: " .. fortress.v2.SQL_DATABASE_FILE)
end



local function create_table()
	local stmt = [[
		CREATE TABLE IF NOT EXISTS fortress (hash TEXT, data BLOB);
	]]
	if not execute_statement(stmt) then return end
	return true
end



function fortress.v2.sql_init()
	if not init_lib() then return end
	if not open_database() then return end
	if not create_table() then return end

	return true
end



-- Accepts: string key, string data.
-- Returns: boolean success.
function fortress.v2.sql_write(key, data)
	if type(key) ~= "string" or type(data) ~= "string" then return end
	local cmd = [[ INSERT INTO fortress (hash, data) VALUES (?, ?); ]]
	return execute_statement(cmd, {key, data})
end



-- Accepts: string key.
-- Returns: string data, or nil.
function fortress.v2.sql_read(key)
	if type(key) ~= "string" then return end
	local cmd = [[ SELECT data FROM fortress WHERE hash = ? LIMIT 1; ]]
	local status, rows = execute_statement(cmd, {key})
	if not status then return end
	if not rows or not rows[1] or type(rows[1].data) ~= "string" then return end
	return rows[1].data
end
