
if not minetest.global_exists("nodestore") then nodestore = {} end
nodestore.modpath = minetest.get_modpath("networks")
nodestore.worldpath = minetest.get_worldpath()
nodestore.database = nodestore.worldpath .. "/nodestore.sqlite"

-- Nodes in the nodestore are indexed by block sector, then hash.
nodestore.data = nodestore.data or {} -- Nodes, indexed by sector.
nodestore.dirty = nodestore.dirty or {} -- List of dirty sectors.



-- Cache for speed.
local myfloor = math.floor
local myhash = minetest.hash_node_position -- TODO: could I implement this in Lua for speed?



-- Private function!
-- Create db:exec wrapper for error reporting.
function nodestore.db_exec(stmt)
  if nodestore.db:exec(stmt) ~= nodestore.sql.OK then
		local msg = nodestore.db:errmsg()
    minetest.log("error", "Sqlite ERROR: " .. msg)

    local admin = utility.get_first_available_admin()
		if admin then
			minetest.chat_send_player(admin:get_player_name(),
				"# Server: Error from SQL! " .. msg)
		end
  end
end



-- Private function!
local function pos_to_sector(pos)
	local sx = myfloor(pos.x/16)
	local sy = myfloor(pos.y/16)
	local sz = myfloor(pos.z/16)
	return myhash({x=sx, y=sy, z=sz})
	-- Number as returned is not suitable for use in filename, must transform first!
end



-- Private function!
local function table_not_empty(tb)
	local c = 0
	for k, v in pairs(tb) do
		c = 1
		break
	end
	return (c > 0)
end



-- Private function!
local function sector_to_keyname(sector)
	local keyname = minetest.serialize(sector)
	assert(type(keyname) == "string")
	keyname = string.gsub(keyname, "return ", "")
	assert(string.len(keyname) > 0)
	return keyname
end



-- Private function!
function nodestore.log(msg)
	minetest.log("action", "[nodestore]: " .. msg)
end



-- Public API function.
--
-- Shall return the declared name and declared owner of a node at a position,
-- reading the data from memory if possible, otherwise reading the map directly.
-- If the map is read from, the data is cached in anticipation of future reads.
function nodestore.get_nodename_and_realowner(pos, hash, netowner)
	local sector = pos_to_sector(pos)
	nodestore.do_load(sector)

	do
		local node = nodestore.data[sector][hash]
		if node then
			-- Note: owner will not necessarily match netowner.
			return node.name, node.owner
		end
	end

	-- Otherwise, we have to read from the map.
	local meta = minetest.get_meta(pos)
	local realname = meta:get_string("nodename")
	local realowner = meta:get_string("owner")
	nodestore.data[sector][hash] = {
		name = realname,
		owner = realowner,
	}
	nodestore.dirty[sector] = true
	return realname, realowner
end



-- Public API function.
--
-- Shall read the node at the passed position, and store in the database its
-- declared owner and declared name. The database is declared 'dirty'.
-- The node must declare its owner and name in the nodemeta, using 'owner' and
-- 'nodename' keys. Note that 'nodename' should be set on construction and not
-- changed, even if the node is swapped for another version of itself, such as
-- swapping between the active/inactive versions of a default furnace.
function nodestore.add_node(pos)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	local sector = pos_to_sector(pos)
	nodestore.do_load(sector)
	local hash = myhash(pos)
	nodestore.data[sector][hash] = {
		name = meta:get_string("nodename"),
		owner = owner,
	}
	nodestore.dirty[sector] = true
end



-- Public API function.
--
-- Shall delete the node at the given position from the database (if data
-- exists). The database is declared 'dirty' only if data was removed.
function nodestore.del_node(pos)
	local sector = pos_to_sector(pos)
	nodestore.do_load(sector)
	local hash = myhash(pos)
	nodestore.data[sector][hash] = nil
	nodestore.dirty[sector] = true
end



-- Public API function.
--
-- Shall obtain the hub info for a node at a given position, if the node in that
-- position is a hub node. Will read the data from memory if possible, otherwise
-- the data will be read from the map and then cached in anticipation of future
-- reads.
--
-- Note that this is similar to 'nodestore.get_nodename_and_realowner', but it
-- returns hub data instead of name and owner.
function nodestore.get_hub_info(pos)
	local sector = pos_to_sector(pos)
	nodestore.do_load(sector)

	local hash = myhash(pos)
	local node = nodestore.data[sector][hash]
	if node and node.hub then
		return node.hub
	end

	-- Otherwise, we have to read the map.
	return nodestore.update_hub_info(pos)
end



local keytab = {
	-- First: position in a direction [p=position]. Second: is direction enabled
	-- [e=enabled]. A search for a valid position in a direction is only done if
	-- that position is enabled.
	{mp="np", me="ne"},
	{mp="sp", me="se"},
	{mp="ep", me="ee"},
	{mp="wp", me="we"},
	{mp="up", me="ue"},
	{mp="dp", me="de"},
}

-- Public API function.
--
-- Shall read the hub info, owner, and nodename for a hub node at a given
-- position from the map and store it in the cache. Will also return the hub
-- info that was read (which may be ignored). Note that just as in
-- 'nodestore.add_node', the owner and nodename must be declared with 'owner'
-- and 'nodename' keys in the node metadata. Hub information should be declared
-- with the keys as defined by the 'keytab' table above.
function nodestore.update_hub_info(pos)
	local meta = minetest.get_meta(pos)
	local data = {}
	for k, v in ipairs(keytab) do
		local e = meta:get_int(v.me)
		data[v.me] = e
		if e == 1 then
			local ps = meta:get_string(v.mp)
			local p = minetest.string_to_pos(ps)
			if p then
				data[v.mp] = p
			else
				data[v.mp] = nil
			end
		else
			data[v.mp] = nil
		end
	end
	local sector = pos_to_sector(pos)
	nodestore.do_load(sector)
	local hash = myhash(pos)
	nodestore.data[sector][hash] = {
		name = meta:get_string("nodename"),
		owner = meta:get_string("owner"),
		hub = data,
	}
	nodestore.dirty[sector] = true
	return data
end



-- Private function!
--
-- Write all sectors marked as dirty to the database.
function nodestore.do_save()
	-- First check if anything is dirty. Count dirty entries.
	local have_dirty = false
	for k, v in pairs(nodestore.dirty) do
		have_dirty = true
		break
	end

	if have_dirty then
		nodestore.db_exec("BEGIN TRANSACTION;")
		for sector, v in pairs(nodestore.dirty) do
			-- Generate filename.
			local keyname = sector_to_keyname(sector)

			nodestore.log("Saving sector " .. keyname .. " because it is dirty.")
			local data = nodestore.data[sector]
			if data and table_not_empty(data) then
				local str = minetest.serialize(data)
				if type(str) == "string" then
					nodestore.db_save_sector(sector, str)
				else
					nodestore.log("Could not serialize sector " .. keyname .. " to string!")
				end
			else
				nodestore.log("Sector " .. keyname .. " declared dirty, but does not exist in memory or is empty.")
			end
		end
		-- Clear dirty names.
		nodestore.dirty = {}
		nodestore.db_exec("COMMIT;")
	end
end



-- Private function!
--
-- Try to load 'sector' from the database. If the sector exists, load it and
-- populate the in-memory cache. If the sector does not exist in the database,
-- create an empty in-memory cache.
function nodestore.do_load(sector)
	-- If data is already loaded, then do nothing.
	if nodestore.data[sector] then
		return
	end

	-- Generate sector name for use in messages.
	local keyname = sector_to_keyname(sector)

	-- Attempt to get data from database.
	local str = nodestore.db_load_sector(sector)
	if str and type(str) == "string" then
		local data = minetest.deserialize(str)
		if type(data) == "table" then
			nodestore.data[sector] = data
			nodestore.dirty[sector] = nil
		else
			nodestore.log("Sector " .. keyname .. " could not be loaded from database, it is corrupt!")
		end
	else
		nodestore.log("Sector " .. keyname .. " does not exist in database. Creating it.")
	end

	-- Create table if not loaded from database.
	if not nodestore.data[sector] then
		nodestore.data[sector] = {}
	end
end



-- Private function!
function nodestore.db_save_sector(key, data)
	local stmt = nodestore.db:prepare([[ INSERT OR REPLACE INTO store (name, data) VALUES (?, ?); ]])

	local r1 = stmt:bind(1, key)
	assert(r1 == nodestore.sql.OK)

	local r2 = stmt:bind_blob(2, data)
	assert(r2 == nodestore.sql.OK)

	local r3 = stmt:step()
	assert(r3 == nodestore.sql.DONE)

	local r4 = stmt:finalize()
	assert(r4 == nodestore.sql.OK)
end



-- Private function!
function nodestore.db_load_sector(key)
	local stmt = nodestore.db:prepare([[ SELECT name, data FROM store WHERE name = ? LIMIT 1; ]])
	stmt:bind(1, key)
	local r = stmt:step()
	while r == nodestore.sql.ROW do
		r = stmt:step()
	end
	assert(r == nodestore.sql.DONE)
	for row in stmt:nrows() do
		stmt:finalize()
		assert(row.data and row.name)
		assert(type(row.data) == "string")
		assert(row.name == key)
		nodestore.log( ("Loaded sector %s from database."):format(sector_to_keyname(key)) )
	  return row.data
	end
	-- Returns 'nil' if no record in database.
end



-- Private function!
-- This is needed to ensure dirty sectors are saved before the database is closed.
function nodestore.on_shutdown()
	nodestore.do_save()
	nodestore.db:close()
end



-- Private function!
function nodestore.create_table()
	local stmt = [[
		CREATE TABLE IF NOT EXISTS store (name INTEGER PRIMARY KEY, data BLOB) WITHOUT ROWID;
	]]
	nodestore.db_exec(stmt)
end



-- One-time execution goes here.
if not nodestore.run_once then
	-- Obtain library for database access.
	-- lsqlite3 loaded on init file for security
	--nodestore.sql = require("lsqlite3")
	nodestore.sql = networks.sql
	assert(nodestore.sql)

	-- Don't allow other mods to use this global library!
	if sqlite3 then sqlite3 = nil end

	-- Open database.
	nodestore.db = nodestore.sql.open(nodestore.database)
	assert(nodestore.db)

	-- Create table if necessary.
	nodestore.create_table()

	-- Database save callbacks.
	minetest.register_on_mapsave(function(...)
		return nodestore.do_save(...) end)
	minetest.register_on_shutdown(function(...)
		return nodestore.on_shutdown(...) end)

	local c = "nodestore:core"
	local f = nodestore.modpath .. "/nodestore.lua"
	reload.register_file(c, f, false)

	nodestore.run_once = true
end
