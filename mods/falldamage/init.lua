
-- Use whenever you would use `minetest.registered_nodes' but don't need stairs.
minetest.reg_ns_nodes = {}

falldamage = falldamage or {}
falldamage.modpath = minetest.get_modpath("falldamage")
dofile(falldamage.modpath .. "/tilesheet.lua")
dofile(falldamage.modpath .. "/rangecheck.lua")
dofile(falldamage.modpath .. "/liquidinteraction.lua")



local function copy_pointed_thing(pointed_thing)
	return {
		type  = pointed_thing.type,
		above = vector.new(pointed_thing.above),
		under = vector.new(pointed_thing.under),
		ref   = pointed_thing.ref,
	}
end



local old_register_craftitem = minetest.register_craftitem
function minetest.register_craftitem(name, def2)
	local def = table.copy(def2)

	if type(def.stack_max) == "nil" then
		def.stack_max = 64
	end
	if type(def.inventory_image) == "string" then
		def.inventory_image = image.get(def.inventory_image)
	end
	if type(def.wield_image) == "string" then
		def.wield_image = image.get(def.wield_image)
	end
	return old_register_craftitem(name, def)
end



local old_register_tool = minetest.register_tool
function minetest.register_tool(name, def)
	local ndef = table.copy(def)
	if ndef.tool_capabilities then
		if ndef.tool_capabilities.range_modifier then
			ndef.range = (ndef.range or 4.0) * ndef.tool_capabilities.range_modifier
		end
	end
	return old_register_tool(name, ndef)
end



-- Override minetest.register_node so that we can modify the falling damage GLOBALLY.
local old_register_node = minetest.register_node;
local function register_node(name, def2)
	local def = table.copy(def2)

	if not def.groups then def.groups = {} end
	if not def.groups.fall_damage_add_percent then
		def.groups.fall_damage_add_percent = 30
	end

	-- Any nodes dealing env damage get added to the 'env_damage' group.
	if def.damage_per_second ~= 0 then
		def.groups.env_damage = 1
	end

	if not def.movement_speed_multiplier then
		if def.drawtype == "nodebox" or def.drawtype == "mesh" then
			if not string.find(name, "^vines:") then
				def.movement_speed_multiplier = default.SLOW_SPEED
			end
		end
	end

	if type(def.stack_max) == "nil" then
		def.stack_max = 64
	end

	-- Every node that overrides 'on_punch' must have its 'on_punch'
	-- handler wrapped in one that calls punchnode callbacks.
	if def.on_punch then
		local on_punch = def.on_punch
		def.on_punch = function(pos, node, puncher, pointed_thing)
			-- Run script hook
			for _, callback in ipairs(core.registered_on_punchnodes) do
				-- Copy pos and node because callback can modify them
				local pos_copy = vector.new(pos)
				local node_copy = {name=node.name, param1=node.param1, param2=node.param2}
				local pointed_thing_copy = pointed_thing and copy_pointed_thing(pointed_thing) or nil
				callback(pos_copy, node_copy, puncher, pointed_thing_copy)
			end
			return on_punch(pos, node, puncher, pointed_thing)
		end
	end

	-- If the node defines 'can_dig' then we must create a wrapper
	-- that calls 'minetest.is_protected' if that function returns false.
	-- This is because the engine will skip the protection check in core.
	if def.can_dig then
		local can_dig = def.can_dig
		function def.can_dig(pos, digger)
			local result = can_dig(pos, digger) -- Call old function.
			if not result then
				-- Old function returned false, we must check protection (because MT core will not do this).
				local pname = ""
				if digger and digger:is_player() then
					pname = digger:get_player_name()
				end
				if minetest.test_protection(pos, pname) then
					protector.punish_player(pos, pname)
				end
			end
			return result
			-- If the old function returned true (i.e., player can dig)
			-- the MT core will follow up with a protection check.
		end
	end

	if type(def.tiles) == "table" then
		for k, v in pairs(def.tiles) do
			if type(v) == "string" then
				def.tiles[k] = image.get(v)
			end
		end
	end
	if type(def.inventory_image) == "string" then
		def.inventory_image = image.get(def.inventory_image)
	end
	if type(def.wield_image) == "string" then
		def.wield_image = image.get(def.wield_image)
	end

	if def.groups.notify_construct and def.groups.notify_construct > 0 then
		if def.on_construct then
			local old = def.on_construct
			def.on_construct = function(pos)
				notify.notify_adjacent(pos)
				return old(pos)
			end
		else
			def.on_construct = function(pos)
				notify.notify_adjacent(pos)
			end
		end
	end
  
	if def.groups.notify_destruct and def.groups.notify_destruct > 0 then
		if def.on_destruct then
			local old = def.on_destruct
			def.on_destruct = function(pos)
				notify.notify_adjacent(pos)
				return old(pos)
			end
		else
			def.on_destruct = function(pos)
				notify.notify_adjacent(pos)
			end
		end
	end

	--clumpfall.update_nodedef(name, def)

	falldamage.apply_range_checks(def)
	falldamage.apply_liquid_interaction_mod(name, def)
	if def.sounds then
		assert(type(def.sounds) == "table")
	end
	old_register_node(name, def)

	-- Populate table of all non-stair nodes.
	if not name:find("^%:?stairs:") then
		local first, second = name:match("^%:?([%w_]+)%:([%w_]+)$")
		local n = first .. ":" .. second
		local def = minetest.registered_nodes[n]
		minetest.reg_ns_nodes[n] = def
	end
end
minetest.register_node = register_node

-- Make sure our custom node tables contain entries for air and ignore.
minetest.reg_ns_nodes["air"] = minetest.registered_nodes["air"]
minetest.reg_ns_nodes["ignore"] = minetest.registered_nodes["ignore"]
