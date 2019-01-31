--[[

Copyright (C) 2016 Aftermoth, Zolan Davis

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation; either version 2.1 of the License,
or (at your option) version 3 of the License.

http://www.gnu.org/licenses/lgpl-2.1.html


--]]
--------------------------------------------------- Global

droplift = {
	invoke,
	-- function (dropobj, sync)
	-- sync in [ false | 0 | seconds ]. See details.txt
}

--------------------------------------------------- Local

local function obstructed(p)
	local n = minetest.get_node_or_nil(p)
	if not n then return false end
	local ndef = minetest.reg_ns_nodes[n.name]
	return ndef and ndef.walkable
end


-- * Local escape *

local dist = function(p1,p2)
	return (  (p1.y - p2.y)^2
			+ (p1.x - p2.x)^2
			+ (p1.z - p2.z)^2 )^0.5
end

local function escape(ent,pos)
	local q, p, ep, d, dd = pos
	for _,player in ipairs(minetest.get_connected_players()) do
		p = player:getpos(); p.y = p.y + 1
		d = dist(p,pos)
		if not dd or (d < dd) then dd, q = d, {x=p.x,y=p.y,z=p.z} end
	end
	for x = pos.x - 1, pos.x + 1 do
		p.x = x; for y = pos.y - 1, pos.y + 1 do
			p.y = y; for z = pos.z - 1, pos.z + 1 do
				p.z = z
				if not obstructed(p) then
					d = dist(q,p)
					if not ep or (d < dd) then dd, ep = d, {x=p.x,y=p.y,z=p.z} end
				end
			end
		end
	end
	if ep then ent.object:set_pos(ep) end
	return ep
end


-- * Entombment physics *

-- ---------------- LIFT

local function lift(obj)
	local p = obj:getpos()
	if p then
		local ent = obj:get_luaentity()
		if ent.is_entombed and obstructed(p) then
-- Time
			local t = 1
			local s1 = ent.sync1
			if s1 then
				local sd = ent.sync0+s1-os.time()
				if sd > 0 then t = sd end
				ent.sync0, ent.sync1 = nil, nil
			end
-- Space
			p = {x = p.x, y = math.floor(p.y - 0.5) + 1.800001, z = p.z}
			obj:set_pos(p)
			if s1 or obstructed(p) then
				minetest.after(t, lift, obj)
				return
			end
		end
-- Void.
		ent.is_entombed, ent.sync0, ent.sync1 = nil, nil, nil
	end
end

-- ---------------- ASYNC

local k = 0
local function newhash()
	k = (k==32767 and 1) or k+1
	return k
end

local function async(obj, usync)
	local p = obj:getpos()
	if p then
		local ent = obj:get_luaentity()
		local hash = newhash()
		ent.hash = ent.hash or hash
		if obstructed(p) then
-- Time.
			if not usync then
				if escape(ent, p) and  hash == ent.hash then
					ent.hash = nil
				end
			elseif usync > 0 then
				ent.sync0 = os.time()
				ent.sync1 = usync
			end
-- Space.
			if hash == ent.hash then
				obj:set_pos({x = p.x, y = math.floor(p.y - 0.5) + 0.800001, z = p.z})
				if not ent.is_entombed then
					ent.is_entombed = true
					minetest.after(1, lift, obj)
				end
			end
		end
		if hash == ent.hash then ent.hash = nil end
	end
end

droplift.invoke = function(obj, sync)
	async(obj, (sync and math.max(0,sync)))
end

-- * Events *

local function append_to_core_defns()
	local dropentity=minetest.registered_entities["__builtin:item"]

	-- Ensure consistency across reloads.
	local on_activate_copy = dropentity.on_activate
	dropentity.on_activate = function(ent, staticdata, dtime_s)
		on_activate_copy(ent, staticdata, dtime_s)
		if staticdata ~= "" then 
			if minetest.deserialize(staticdata).is_entombed then
				ent.is_entombed = true
				ent.object:setacceleration({x = 0, y = 0, z = 0})  -- Prevents 0.18m reload slippage. Not critical.
				minetest.after(0.1, lift, ent.object)
			end
		end
		ent.object:setvelocity({x = 0, y = 0, z = 0})  -- Prevents resting-buried drops burrowing. 
	end

	-- Preserve state across reloads
	local get_staticdata_copy = dropentity.get_staticdata
	dropentity.get_staticdata = function(ent)
		local s = get_staticdata_copy(ent)
		if ent.is_entombed then
			local r = {}
			if s ~= "" then
				r = minetest.deserialize(s)
			end
			r.is_entombed=true
			return minetest.serialize(r)
		end
		return s
	end

	-- Update drops inside newly placed nodes.
	local add_node_copy = minetest.add_node
	minetest.add_node = function(pos, node)
		add_node_copy(pos, node)
		dirtspread.check_dirt_covered_timer({x=pos.x, y=pos.y-1, z=pos.z})

		local a = minetest.get_objects_inside_radius(pos, 0.87)
		for _,obj in ipairs(a) do
			local ent = obj:get_luaentity()
			if ent and ent.name == "__builtin:item" then
				async(obj)
			end
		end
	end

end


append_to_core_defns()
