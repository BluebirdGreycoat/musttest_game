--------------------------------------------------------------------------------
-- Mod: Itemframes
-- Author: Zeg9
-- License: WTFPL
--------------------------------------------------------------------------------

local tmp = {}
screwdriver = screwdriver or {}

local function on_rename_check(pos, nodename)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	-- Nobody placed this block.
	if owner == "" then
		return
	end
	local dname = rename.gpn(owner)

	meta:set_string("rename", dname)
	meta:set_string("infotext", nodename .. " (Owned by <" .. dname .. ">!)")
end

minetest.register_entity("itemframes:item",{
	hp_max = 1,
	visual="wielditem",
	visual_size={x = 0.33, y = 0.33},
	collisionbox = {0, 0, 0, 0, 0, 0},
	physical = false,
	textures = {"air"},
	on_activate = function(self, staticdata)
		if tmp.nodename ~= nil and tmp.texture ~= nil then
			self.nodename = tmp.nodename
			tmp.nodename = nil
			self.texture = tmp.texture
			tmp.texture = nil
		else
			if staticdata ~= nil and staticdata ~= "" then
				local data = staticdata:split(';')
				if data and data[1] and data[2] then
					self.nodename = data[1]
					self.texture = data[2]
				end
			end
		end
		if self.texture ~= nil then
			self.object:set_properties({textures = {self.texture}})
		end
		if self.nodename == "itemframes:pedestal" then
			self.object:set_properties({automatic_rotate = 1})
		end
	end,
	get_staticdata = function(self)
		if self.nodename ~= nil and self.texture ~= nil then
			return self.nodename .. ';' .. self.texture
		end
		return ""
	end,
})

local facedir = {}

facedir[0] = {x = 0, y = 0, z = 1}
facedir[1] = {x = 1, y = 0, z = 0}
facedir[2] = {x = 0, y = 0, z = -1}
facedir[3] = {x = -1, y = 0, z = 0}

local remove_item = function(pos, node)
	local objs = nil
	if node.name == "itemframes:frame" then
		objs = minetest.get_objects_inside_radius(pos, .5)
	elseif node.name == "itemframes:pedestal" then
		objs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y+1,z=pos.z}, .5)
	end
	if objs then
		for _, obj in ipairs(objs) do
			if obj and obj:get_luaentity() and obj:get_luaentity().name == "itemframes:item" then
				obj:remove()
			end
		end
	end
end

local update_item = function(pos, node)
	remove_item(pos, node)
	local meta = minetest.get_meta(pos)
	if meta:get_string("item") ~= "" then
		if node.name == "itemframes:frame" then
			local posad = facedir[node.param2]
			if not posad then return end
			pos.x = pos.x + posad.x * 6.5 / 16
			pos.y = pos.y + posad.y * 6.5 / 16
			pos.z = pos.z + posad.z * 6.5 / 16
		elseif node.name == "itemframes:pedestal" then
			pos.y = pos.y + 12 / 16 + 0.33
		end
		tmp.nodename = node.name
		tmp.texture = ItemStack(meta:get_string("item")):get_name()
		local e = minetest.add_entity(pos,"itemframes:item")
		if e and node.name == "itemframes:frame" then
			local yaw = math.pi * 2 - node.param2 * math.pi / 2
			e:setyaw(yaw)
		end
	end
end

local drop_item = function(pos, node)
	local meta = minetest.get_meta(pos)
	if meta:get_string("item") ~= "" then
		if node.name == "itemframes:frame" then
			minetest.add_item(pos, meta:get_string("item"))
		elseif node.name == "itemframes:pedestal" then
			minetest.add_item({x=pos.x,y=pos.y+1,z=pos.z}, meta:get_string("item"))
		end
		meta:set_string("item","")
	end
	remove_item(pos, node)
end

minetest.register_node("itemframes:frame",{
	description = "Item Frame\n\nSometimes stored items become invisible.\nPunch with a stick to restore them.",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, 7/16, 0.5, 0.5, 0.5}
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, 7/16, 0.5, 0.5, 0.5}
	},
	tiles = {"itemframes_frame.png"},
	inventory_image = "itemframes_frame.png",
	wield_image = "itemframes_frame.png",
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	groups = utility.dig_groups("bigitem"),
	legacy_wallmounted = true,
	sounds = default.node_sound_defaults(),
	on_rotate = screwdriver.disallow,
	after_place_node = function(pos, placer, itemstack)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner",placer:get_player_name())
		meta:set_string("infotext", string.format("Item Frame (Owned by <%s>!)", rename.gpn(placer:get_player_name())))
	end,
	_on_rename_check = function(pos)
		on_rename_check(pos, "Item Frame")
		update_item(pos, minetest.get_node(pos))
	end,
	on_rightclick = function(pos, node, clicker, itemstack)
		if not itemstack then return end
		local meta = minetest.get_meta(pos)
		local name = clicker and clicker:get_player_name()
		if name == meta:get_string("owner") or
				minetest.check_player_privs(name, "protection_bypass") then
			drop_item(pos,node)
			local s = itemstack:take_item()
			meta:set_string("item",s:to_string())
			update_item(pos,node)
		end
		if map.is_mapping_kit(itemstack:get_name()) then
			minetest.chat_send_player("MustTest", "Updating inventory: " .. itemstack:get_name() .. ", " .. name)
			minetest.after(0, function() map.update_inventory_info(name) end)
		end
		return itemstack
	end,
	on_punch = function(pos,node,puncher)
		local meta = minetest.get_meta(pos)
		local name = puncher and puncher:get_player_name()
		if name == meta:get_string("owner") or
				minetest.check_player_privs(name, "protection_bypass") then
			drop_item(pos, node)
		end
	end,
	can_dig = function(pos,player)
		if not player then return end
		local name = player and player:get_player_name()
		local meta = minetest.get_meta(pos)
		return name == meta:get_string("owner") or
				minetest.check_player_privs(name, "protection_bypass")
	end,
	on_destruct = function(pos)
		local meta = minetest.get_meta(pos)
		local node = minetest.get_node(pos)
		if meta:get_string("item") ~= "" then
			drop_item(pos, node)
		end
	end,
	on_finish_collapse = function(pos, node)
		-- Prevent item-duplication.
		local meta = minetest.get_meta(pos)
		meta:set_string("item", nil)
	end,
})


minetest.register_node("itemframes:pedestal",{
	description = "Pedestal\n\nSometimes stored items become invisible.\nPunch with a stick to restore them.",
	drawtype = "nodebox",
	node_box = {
		type = "fixed", fixed = {
			{-7/16, -8/16, -7/16, 7/16, -7/16, 7/16}, -- bottom plate
			{-6/16, -7/16, -6/16, 6/16, -6/16, 6/16}, -- bottom plate (upper)
			{-0.25, -6/16, -0.25, 0.25, 11/16, 0.25}, -- pillar
			{-7/16, 11/16, -7/16, 7/16, 12/16, 7/16}, -- top plate
		}
	},
	--selection_box = {
	--	type = "fixed",
	--	fixed = {-7/16, -0.5, -7/16, 7/16, 12/16, 7/16}
	--},
	tiles = {"itemframes_pedestal.png"},
	paramtype = "light",
	groups = utility.dig_groups("brick"),
	sounds = default.node_sound_defaults(),
	on_rotate = screwdriver.disallow,
	after_place_node = function(pos, placer, itemstack)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner",placer:get_player_name())
		meta:set_string("infotext", string.format("Pedestal (Owned by <%s>!)", rename.gpn(placer:get_player_name())))
	end,
	_on_rename_check = function(pos)
		on_rename_check(pos, "Pedestal")
		update_item(pos, minetest.get_node(pos))
	end,
	on_rightclick = function(pos, node, clicker, itemstack)
		if not itemstack then return end
		local meta = minetest.get_meta(pos)
		local name = clicker and clicker:get_player_name()
		if name == meta:get_string("owner") or
				minetest.check_player_privs(name, "protection_bypass") then
			drop_item(pos,node)
			local s = itemstack:take_item()
			meta:set_string("item",s:to_string())
			update_item(pos,node)
		end
		if map.is_mapping_kit(itemstack:get_name()) then
			minetest.after(0, function() map.update_inventory_info(name) end)
		end
		return itemstack
	end,
	on_punch = function(pos,node,puncher)
		local meta = minetest.get_meta(pos)
		local name = puncher and puncher:get_player_name()
		if name == meta:get_string("owner") or
				minetest.check_player_privs(name, "protection_bypass") then
			drop_item(pos,node)
		end
	end,
	can_dig = function(pos,player)
		if not player then return end
		local name = player and player:get_player_name()
		local meta = minetest.get_meta(pos)
		return name == meta:get_string("owner") or
				minetest.check_player_privs(name, "protection_bypass")
	end,
	on_destruct = function(pos)
		local meta = minetest.get_meta(pos)
		local node = minetest.get_node(pos)
		if meta:get_string("item") ~= "" then
			drop_item(pos, node)
		end
	end,
	on_finish_collapse = function(pos, node)
		-- Prevent item-duplication.
		local meta = minetest.get_meta(pos)
		meta:set_string("item", nil)
	end,
})


-- crafts

minetest.register_craft({
	output = 'itemframes:frame',
	recipe = {
		{'group:stick', 'group:stick', 'group:stick'},
		{'group:stick', 'default:paper', 'default:stick'},
		{'group:stick', 'group:stick', 'group:stick'},
	}
})

minetest.register_craft({
	output = 'itemframes:pedestal',
	recipe = {
		{'default:stone', 'default:stone', 'default:stone'},
		{'', 'default:stone', ''},
		{'default:stone', 'default:stone', 'default:stone'},
	}
})

-- stop mesecon pistons from pushing itemframes and pedestals
if minetest.get_modpath("mesecons_mvps") then
	mesecon.register_mvps_stopper("itemframes:frame")
	mesecon.register_mvps_stopper("itemframes:pedestal")
end
