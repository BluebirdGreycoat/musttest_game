-- sauth mod for minetest voxel game
-- by shivajiva101@hotmail.com

-- Expose auth handler functions
sauth = {}
local auth_table = {}
local MN = minetest.get_current_modname()
local WP = minetest.get_worldpath()
local ie = minetest.request_insecure_environment()

if not ie then
	error("insecure environment inaccessible"..
		" - make sure this mod has been added to minetest.conf!")
end

-- Requires library for db access
local _sql
do
	local success, lib = pcall(ie.require, "lsqlite3")
	if not success then
		minetest.log("error", "sqlite not found, using builtin auth handler (skipping sauth)")
		minetest.log("error", lib)
		return
	end
	assert(lib)
	assert(lib.open)
	_sql = lib
end
-- Don't allow other mods to use this global library!
if sqlite3 then sqlite3 = nil end

local singleplayer = minetest.is_singleplayer()

-- Use conf setting to determine handler for singleplayer
if not minetest.settings:get(MN .. '.enable_singleplayer') and singleplayer then
	minetest.log("info", "singleplayer game using builtin auth handler")
	return
end

local db = _sql.open(WP.."/sauth.sqlite") -- connection

-- Create db:exec wrapper for error reporting
local function db_exec(stmt)
	if db:exec(stmt) ~= _sql.OK then
		minetest.log("error", "Sqlite ERROR:  ", db:errmsg())
	end
end

local function cache_check(name)
	local chk = false
	for _,data in ipairs(minetest.get_connected_players()) do
		if data:get_player_name() == name then
			chk = true
			break
		end
	end
	if not chk then
		auth_table[name] = nil
	end
end

-- Db tables - because we need them!
local create_db = [[
CREATE TABLE IF NOT EXISTS auth (id INTEGER PRIMARY KEY AUTOINCREMENT,
name VARCHAR(32), password VARCHAR(512), privileges VARCHAR(512),
last_login INTEGER, first_login INTEGER);
CREATE TABLE IF NOT EXISTS _s (import BOOLEAN);
]]
db_exec(create_db)

--[[
###########################
###  Database: Queries  ###
###########################
]]

-- Prepared statements.
local stmt_get_record = db:prepare([[
	SELECT * FROM auth WHERE name = ? LIMIT 1;
]])
assert(stmt_get_record, db:errmsg())

local stmt_check_name = db:prepare([[
	SELECT DISTINCT name
	FROM auth
	WHERE LOWER(name) = LOWER(?) LIMIT 1;
]])
assert(stmt_check_name, db:errmsg())

local stmt_check_name_all = db:prepare([[
	SELECT name
	FROM auth
	WHERE LOWER(name) = LOWER(?);
]])
assert(stmt_check_name_all, db:errmsg())

local stmt_get_names = db:prepare([[
	SELECT name FROM auth WHERE name LIKE '%' || ? || '%';
]])
assert(stmt_get_names, db:errmsg())



-- Actions.
local function get_record(name)
	stmt_get_record:reset()
	assert(stmt_get_record:bind_values(name) == _sql.OK)

	for row in stmt_get_record:nrows() do
		return row
	end
end

local function check_name(name)
	stmt_check_name:reset()
	assert(stmt_check_name:bind_values(name) == _sql.OK)

	for row in stmt_check_name:nrows() do
		return row
	end
end

local function check_name_all(name)
	stmt_check_name_all:reset()
	assert(stmt_check_name_all:bind_values(name) == _sql.OK)

	local t = {}
	for row in stmt_check_name_all:nrows() do
		t[#t+1] = row.name
	end

	return t
end

local function get_names(name)
	stmt_get_names:reset()
	assert(stmt_get_names:bind_values(name) == _sql.OK)

	local r = {}
	for row in stmt_get_names:nrows() do
		r[#r+1] = row.name
	end

	return r
end

--[[
##############################
###  Database: Statements  ###
##############################
]]

-- Prepared statements.
local stmt_add_record = db:prepare([[
	INSERT INTO auth (name, password, privileges, last_login) VALUES (?, ?, ?, ?)
]])
assert(stmt_add_record, db:errmsg())

local stmt_update_login = db:prepare([[
	UPDATE auth SET last_login = ? WHERE name = ?
]])
assert(stmt_update_login, db:errmsg())

local stmt_update_password = db:prepare([[
	UPDATE auth SET password = ? WHERE name = ?
]])
assert(stmt_update_password, db:errmsg())

local stmt_update_privs = db:prepare([[
	UPDATE auth SET privileges = ? WHERE name = ?
]])
assert(stmt_update_privs, db:errmsg())

local stmt_del_record = db:prepare([[
	DELETE FROM auth WHERE name = ?
]])
assert(stmt_del_record, db:errmsg())



-- Actions.
local function add_record(name, password, privs, last_login)
	stmt_add_record:reset()
	assert(stmt_add_record:bind_values(name, password, privs, last_login) == _sql.OK)
	assert(stmt_add_record:step() == _sql.DONE)
end

local function update_login(name)
	local ts = os.time()
	stmt_update_login:reset()
	assert(stmt_update_login:bind_values(ts, name) == _sql.OK)
	assert(stmt_update_login:step() == _sql.DONE)
end

local function update_password(name, password)
	stmt_update_password:reset()
	assert(stmt_update_password:bind_values(password, name) == _sql.OK)
	assert(stmt_update_password:step() == _sql.DONE)
end

local function update_privileges(name, privs)
	stmt_update_privs:reset()
	assert(stmt_update_privs:bind_values(privs, name) == _sql.OK)
	assert(stmt_update_privs:step() == _sql.DONE)
end

local function del_record(name)
	stmt_del_record:reset()
	assert(stmt_del_record:bind_values(name) == _sql.OK)
	assert(stmt_del_record:step() == _sql.DONE)
end



--[[
######################
###  Auth Handler  ###
######################
]]

sauth.auth_handler = {
	get_auth = function(name, add_to_cache)
		-- Return password, privileges, last_login.
		assert(type(name) == 'string')
		-- Datch empty names for mods that do privilege checks.
		if name == '' or name == ' ' then
			minetest.log("info", "[sauth]: Name missing in call to get_auth. Rejected.")
			return nil
		end
		add_to_cache = add_to_cache or true -- Assert caching on missing param
		local r = auth_table[name]
		-- Check and load db record if reqd
		if r == nil then
			r = get_record(name)
		else
			return r	-- cached copy
		end
		-- Return nil on missing entry
		if not r then return nil end

		-- Figure out what privileges the player should have.
		-- Take a copy of the players privilege table
		local privileges, admin = {}
		for priv, _ in pairs(minetest.string_to_privs(r.privileges)) do
			privileges[priv] = true
		end
		if core.settings then
			admin = core.settings:get("name")
		else
			admin = core.setting_get("name")
		end
		-- If singleplayer, grant privileges marked give_to_singleplayer = true
		if core.is_singleplayer() then
			for priv, def in pairs(core.registered_privileges) do
				if def.give_to_singleplayer then
					privileges[priv] = true
				end
			end
		-- If admin, grant all privileges
		elseif name == admin then
			for priv, def in pairs(core.registered_privileges) do
				privileges[priv] = true
			end
		end
		-- Construct record
		local record = {
			password = r.password,
			privileges = privileges,
			last_login = tonumber(r.last_login)
		}
		if not auth_table[name] and add_to_cache then auth_table[name] = record end -- Cache if reqd
		return record
	end,

	create_auth = function(name, password)
		assert(type(name) == 'string')
		assert(type(password) == 'string')
		local ts, privs = os.time()
		if core.settings then
			privs = core.settings:get("default_privs")
		else
			-- use old method
			privs = core.setting_get("default_privs")
		end
		-- Params: name, password, privs, last_login
		add_record(name,password,privs,ts)
		return true
	end,

	delete_auth = function(name)
		assert(type(name) == 'string')
		-- Offline only!
		if auth_table[name] == nil then del_record(name) end
		return true
	end,

	set_password = function(name, password)
		assert(type(name) == 'string')
		assert(type(password) == 'string')
		-- get player record
		if get_record(name) == nil then
			sauth.auth_handler.create_auth(name, password)
		else
			update_password(name, password)
			if auth_table[name] then auth_table[name].password = password end
		end
		return true
	end,

	set_privileges = function(name, privs)
		assert(type(name) == 'string')
		assert(type(privs) == 'table')
		if not sauth.auth_handler.get_auth(name) then
	    		-- create the record
			if core.settings then
				sauth.auth_handler.create_auth(name,
					core.get_password_hash(name,
						core.settings:get("default_password")))
			else
				sauth.auth_handler.create_auth(name,
					core.get_password_hash(name,
						core.setting_get("default_password")))
			end
		end
		local admin
		if core.settings then
			admin = core.settings:get("name")
		else
			admin = core.setting_get("name")
		end
		if name == admin then privs.privs = true end
		update_privileges(name, minetest.privs_to_string(privs))
		if auth_table[name] then auth_table[name].privileges = privs end
		minetest.notify_authentication_modified(name)
		return true
	end,

	reload = function()
		return true
	end,

	record_login = function(name)
		assert(type(name) == 'string')
		update_login(name)
		auth_table[name].last_login = os.time()
		return true
	end,

	name_search = function(name)
		assert(type(name) == 'string')
		return get_names(name)
	end,

	-- This function should scan through the DB and check if name already has a similar entry.
	check_similar_name = function(name)
		assert(type(name) == 'string')
		return check_name_all(name)
	end,
}

--[[
########################
###  Register hooks  ###
########################
]]
-- Register auth handler
minetest.register_authentication_handler(sauth.auth_handler)
minetest.log('action', MN .. ": Registered auth handler")

-- Housekeeping
minetest.register_on_leaveplayer(function(player)
	-- Schedule a check to see if the player has gone
	minetest.after(60*3, cache_check, player:get_player_name())
end)

minetest.register_on_prejoinplayer(function(name, ip)
	local r = get_record(name)	
	if r ~= nil then
		return
	end
	-- Check name isn't registered
	local chk = check_name(name)
	if chk then
		return ("\nCannot allocate account '%s'. " ..
			"Name '%s' already authorized. " ..
			"Choose a different name."):format(name, chk.name)
	end
end)

minetest.register_on_shutdown(function()
	db:close()
end)
