
fortress.v2.SQL_DATABASE_FILE =
	minetest.get_worldpath() .. "/fortdata.v2.sql"



local function execute_statement(stmt)
	if not fortress.v2.SQL_LIB then return end
	if not fortress.v2.SQL_DATABASE_OBJ then return end

	local SQL_OK = fortress.v2.SQL_LIB.OK
	if fortress.v2.SQL_DATABASE_OBJ:exec(stmt) ~= SQL_OK then
		local msg = fortress.v2.SQL_DATABASE_OBJ:errmsg()
		minetest.log("error", "SQLite3 Error: " .. msg)
		return
	end

	return true
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
end
