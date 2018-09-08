-- File is individually reloadable.

-- List of all nodes which have special liquid interaction override code.
falldamage.liquid_interact_nodes = falldamage.liquid_interact_nodes or {}

local string_gsub = string.gsub
local string_find = string.find

-- Alter the way a node interacts with liquids base on its data.
-- Specifically, this determines whether a node can be placed in liquid.
-- A node should not be placeable if it could create airgaps for breathing.
-- This can be considered an extension of the `buildable_to' concept, where
-- all liquids become `buildable_to = false' when placing this node type.
function falldamage.apply_liquid_interaction_mod(name, def)
	name = string_gsub(name, "^:", "") -- Eases later parsing.
	def.can_place_in_liquid = true -- Defaults to true.

	local nodes = falldamage.liquid_interact_nodes
	local need_mod = false

	-- First, check parameters which may set `need_mod' to true.
	-- Then, check paramters which override it to be set false instead.
	-- If neither check triggers, the default is false.

	-- Only if walkability is specifically falsified.
	if def.walkable and def.walkable == false then
		need_mod = true
	end
	if def.climbable and def.climbable == true then
		need_mod = true
	end

	if def.drawtype then
		if def.drawtype == "nodebox" or
			def.drawtype == "mesh" or
			def.drawtype == "plantlike" then
			need_mod = true
		end
	end

	if def.groups then
		if def.groups.attached_node and def.groups.attached_node > 0 then
			need_mod = true
		end
		if def.groups.hanging_node and def.groups.hanging_node > 0 then
			need_mod = true
		end
	end

	-- Whitelisted drawtypes. Nodes with these drawtypes need no modification.
	-- They can never create airgaps under any circumstance.
	if def.drawtype then
		local dt = def.drawtype
		if dt == "normal" or
			dt == "liquid" or
			dt == "flowingliquid" or
			dt == "glasslike" or
			dt == "glasslike_framed" or
			dt == "glasslike_framed_optional" or
			dt == "allfaces" or
			dt == "allfaces_optional" or
			dt == "plantlike_rooted" then
			need_mod = false
		end
	end

	-- Obviously, immovable nodes can be placed in liquid.
	-- Protectors can be these.
	if def.groups and def.groups.immovable and def.groups.immovable > 0 then
		need_mod = false
	end

	-- Tree trunk nodes are exempt (they are nodeboxes).
	if def.groups and def.groups.tree and def.groups.tree > 0 then
		need_mod = false
	end

	-- If node is already marked as floodable, it has custom handling elsewhere.
	-- So we do not need to prevent placement in liquids, here.
	if def.floodable or def.on_flood then
		need_mod = false
	end

	-- Other special node exemptions.
	if string_find(name, "^bat2:") or
		string_find(name, "^stat2:") or
		string_find(name, "^tide:") or -- Tidal turbine must be in water!
		string_find(name, "^scaffolding:") or
		string_find(name, "^throwing:") or
		string_find(name, "^maptools:") or
		string_find(name, "^doors:") or
		string_find(name, "^protector:") or
		string_find(name, "^vines:") or
		string_find(name, "^morechests:") or
		string_find(name, "^chests:") or
		string_find(name, "^barter_table:") or
		string_find(name, "^engraver:") or
		string_find(name, "^solar:") or
		string_find(name, "^windy:") then
		need_mod = false
	end

	-- Is a nodebox.
	if name == "default:cactus" or
		name == "farming:soil" or
		name == "farming:soil_wet" or
		name == "farming:desert_sand_soil" or
		name == "farming:desert_sand_soil_wet" or
		name == "techcrafts:machine_casing" then
		need_mod = false
	end

	if need_mod then
		nodes[#nodes+1] = name
		def.can_place_in_liquid = false
	end
end

local function copy_pointed_thing(pointed_thing)
	return {
		type  = pointed_thing.type,
		above = vector.new(pointed_thing.above),
		under = vector.new(pointed_thing.under),
		ref   = pointed_thing.ref,
	}
end

local function user_name(user)
	return user and user:get_player_name() or ""
end

local function is_protected(pos, name)
	return core.is_protected(pos, name) and
		not minetest.check_player_privs(name, "protection_bypass")
end

-- Returns a logging function. For empty names, does not log.
local function make_log(name)
	return name ~= "" and core.log or function() end
end

local function check_attached_node(p, n)
	local def = core.registered_nodes[n.name]
	local d = {x = 0, y = 0, z = 0}
	if def.paramtype2 == "wallmounted" or
			def.paramtype2 == "colorwallmounted" then
		-- The fallback vector here is in case 'wallmounted to dir' is nil due
		-- to voxelmanip placing a wallmounted node without resetting a
		-- pre-existing param2 value that is out-of-range for wallmounted.
		-- The fallback vector corresponds to param2 = 0.
		d = core.wallmounted_to_dir(n.param2) or {x = 0, y = 1, z = 0}
	else
		d.y = -1
	end
	local p2 = vector.add(p, d)
	local nn = core.get_node(p2).name
	local def2 = core.registered_nodes[nn]
	if def2 and not def2.walkable then
		return false
	end
	return true
end

-- Override what's in the server's builtin.
function core.item_place_node(itemstack, placer, pointed_thing, param2)
	local def = itemstack:get_definition()
	if def.type ~= "node" or pointed_thing.type ~= "node" then
		return itemstack, false, nil
	end

	local under = pointed_thing.under
	local oldnode_under = core.get_node_or_nil(under)
	local above = pointed_thing.above
	local oldnode_above = core.get_node_or_nil(above)
	local playername = user_name(placer)
	local log = make_log(playername)

	if not oldnode_under or not oldnode_above then
		log("info", playername .. " tried to place"
			.. " node in unloaded position " .. core.pos_to_string(above))
		return itemstack, false, nil
	end

	local oldnode_uname = oldnode_under.name
	local oldnode_aname = oldnode_above.name

	-- Get node definitions, or fallback to default.
	local olddef_under = core.reg_ns_nodes[oldnode_uname] or
		core.registered_nodes[oldnode_uname]
	olddef_under = olddef_under or core.nodedef_default
	local olddef_above = core.reg_ns_nodes[oldnode_aname] or
		core.registered_nodes[oldnode_aname]
	olddef_above = olddef_above or core.nodedef_default

	if not olddef_above.buildable_to and not olddef_under.buildable_to then
		log("info", playername .. " tried to place"
			.. " node in invalid position " .. core.pos_to_string(above)
			.. ", replacing " .. oldnode_aname)
		return itemstack, false, nil
	end

	-- Don't permit building against some nodes.
	if olddef_under.not_buildable_against then
		return itemstack, false, nil
	end

	-- Place above pointed node
	local will_place_above = true
	local place_to = {x = above.x, y = above.y, z = above.z}

	-- If node under is buildable_to, place into it instead (eg. snow)
	if olddef_under.buildable_to then
		log("info", "node under is buildable to")
		place_to = {x = under.x, y = under.y, z = under.z}
		will_place_above = false
	end

	-- Feature addition by MustTest.
	if not def.can_place_in_liquid then
		if will_place_above and olddef_above.liquidtype ~= "none" then
			return itemstack, false, nil
		elseif not will_place_above and olddef_under.liquidtype ~= "none" then
			return itemstack, false, nil
		end
	end

	if is_protected(place_to, playername) then
		log("action", playername
				.. " tried to place " .. def.name
				.. " at protected position "
				.. core.pos_to_string(place_to))
		core.record_protection_violation(place_to, playername)
		return itemstack, false, nil
	end

	log("action", playername .. " places node "
		.. def.name .. " at " .. core.pos_to_string(place_to))

	local oldnode = core.get_node(place_to)
	local newnode = {name = def.name, param1 = 0, param2 = param2 or 0}

	-- Calculate direction for wall mounted stuff like torches and signs
	if def.place_param2 ~= nil then
		newnode.param2 = def.place_param2
	elseif (def.paramtype2 == "wallmounted" or
			def.paramtype2 == "colorwallmounted") and not param2 then
		local dir = {
			x = under.x - above.x,
			y = under.y - above.y,
			z = under.z - above.z
		}
		newnode.param2 = core.dir_to_wallmounted(dir)
	-- Calculate the direction for furnaces and chests and stuff
	elseif (def.paramtype2 == "facedir" or
			def.paramtype2 == "colorfacedir") and not param2 then
		local placer_pos = placer and placer:getpos()
		if placer_pos then
			local dir = {
				x = above.x - placer_pos.x,
				y = above.y - placer_pos.y,
				z = above.z - placer_pos.z
			}
			newnode.param2 = core.dir_to_facedir(dir)
			log("action", "facedir: " .. newnode.param2)
		end
	end

	local metatable = itemstack:get_meta():to_table().fields

	-- Transfer color information
	if metatable.palette_index and not def.place_param2 then
		local color_divisor = nil
		if def.paramtype2 == "color" then
			color_divisor = 1
		elseif def.paramtype2 == "colorwallmounted" then
			color_divisor = 8
		elseif def.paramtype2 == "colorfacedir" then
			color_divisor = 32
		end
		if color_divisor then
			local color = math.floor(metatable.palette_index / color_divisor)
			local other = newnode.param2 % color_divisor
			newnode.param2 = color * color_divisor + other
		end
	end

	-- Check if the node is attached and if it can be placed there
	if core.get_item_group(def.name, "attached_node") ~= 0 and
		not check_attached_node(place_to, newnode) then
		log("action", "attached node " .. def.name ..
			" can not be placed at " .. core.pos_to_string(place_to))
		return itemstack, false, nil
	end

	-- Add node and update
	core.add_node(place_to, newnode)

	local take_item = true

	-- Run callback
	if def.after_place_node then
		-- Deepcopy place_to and pointed_thing because callback can modify it
		local place_to_copy = {x=place_to.x, y=place_to.y, z=place_to.z}
		local pointed_thing_copy = copy_pointed_thing(pointed_thing)
		if def.after_place_node(place_to_copy, placer, itemstack,
				pointed_thing_copy) then
			take_item = false
		end
	end

	-- Run script hook
	for _, callback in ipairs(core.registered_on_placenodes) do
		-- Deepcopy pos, node and pointed_thing because callback can modify them
		local place_to_copy = {x=place_to.x, y=place_to.y, z=place_to.z}
		local newnode_copy = {name=newnode.name, param1=newnode.param1, param2=newnode.param2}
		local oldnode_copy = {name=oldnode.name, param1=oldnode.param1, param2=oldnode.param2}
		local pointed_thing_copy = copy_pointed_thing(pointed_thing)
		if callback(place_to_copy, newnode_copy, placer, oldnode_copy, itemstack, pointed_thing_copy) then
			take_item = false
		end
	end

	if take_item then
		itemstack:take_item()
	end

	-- Return position as 3rd result. By MustTest.
	return itemstack, true, place_to
end
