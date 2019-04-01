---------------------------------------------------------------------------------------
-- simple anvil that can be used to repair tools
---------------------------------------------------------------------------------------
-- * can be used to repair tools
-- * the hammer gets dammaged a bit at each repair step
---------------------------------------------------------------------------------------
anvil = anvil or {}
anvil.modpath = minetest.get_modpath("anvil")

anvil.tmp = anvil.tmp or {}

-- Item entity's displacement above the anvil.
local item_displacement = 7/16

local remove_item = function(pos, node)
  local objs = minetest.env:get_objects_inside_radius({x = pos.x, y = pos.y + item_displacement, z = pos.z}, .5)
  if objs then
    for _, obj in ipairs(objs) do
      if obj and obj:get_luaentity() and obj:get_luaentity().name == "anvil:item" then
        obj:remove()
      end
    end
  end
end

local update_item = function(pos, node)
  local meta = minetest.env:get_meta(pos)
  local inv = meta:get_inventory()
  if not inv:is_empty("input") then
    pos.y = pos.y + item_displacement
    anvil.tmp.nodename = node.name
    anvil.tmp.texture = inv:get_stack("input", 1):get_name()
    local e = minetest.env:add_entity(pos,"anvil:item")
    local yaw = math.pi*2 - node.param2 * math.pi/2
    e:setyaw(yaw)
  end
end

local update_item_if_needed = function(pos, node)
	local test_pos = {x=pos.x, y=pos.y + item_displacement, z=pos.z}
	if #minetest.get_objects_inside_radius(test_pos, 0.5) > 0 then
		return
	end
  update_item(pos, node)
end

function anvil.on_activate(self, staticdata)
	if anvil.tmp.nodename ~= nil and anvil.tmp.texture ~= nil then
		self.nodename = anvil.tmp.nodename
		anvil.tmp.nodename = nil
		self.texture = anvil.tmp.texture
		anvil.tmp.texture = nil
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
		self.object:set_properties({textures={self.texture}})
	end
end

function anvil.get_staticdata(self)
	if self.nodename ~= nil and self.texture ~= nil then
		return self.nodename .. ';' .. self.texture
	end
	return ""
end

function anvil.on_construct(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	inv:set_size("input", 1)
end

function anvil.on_destruct(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	local item = inv:get_stack("input", 1)
	if item:get_count() == 1 then
		minetest.add_item(pos, item)
		inv:set_stack("input", 1, ItemStack(""))
	end

	remove_item(pos, minetest.get_node(pos))
end

function anvil.on_finish_collapse(pos, node)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	inv:set_stack("input", 1, ItemStack(""))
end

function anvil.after_place_node(pos, placer)
	local meta = minetest.get_meta(pos)
	meta:set_string("owner", placer:get_player_name() or "")
	meta:set_string("infotext", "Blacksmithing Anvil")
end

function anvil.can_dig(pos, player)
	local meta  = minetest.get_meta(pos)
	local inv   = meta:get_inventory()

	if not inv:is_empty("input") then
		return false
	end
	return true
end

function anvil.allow_metadata_inventory_put(pos, listname, index, stack, player)
	if not player or not player:is_player() then
		return 0
	end
	if minetest.test_protection(pos, player:get_player_name()) then
		return 0
	end

	local meta = minetest.get_meta(pos)
	if listname~="input" then
		return 0
	end
	if (listname=='input'
		and (stack:get_wear() == 0
		or minetest.get_item_group(stack:get_name(), "not_repaired_by_anvil") ~= 0
		or stack:get_name() == "cans:water_can"
		or stack:get_name() == "cans:lava_can" )) then

		-- Report error if tool is not the wieldhand.
		if stack:get_name() ~= "" then
			local pname = player:get_player_name()
			minetest.chat_send_player(pname, '# Server: This anvil is for damaged tools only.')
		end
		return 0
	end

	if meta:get_inventory():room_for_item("input", stack) then
		return stack:get_count()
	end
	return 0
end

function anvil.allow_metadata_inventory_move()
	return 0
end

function anvil.allow_metadata_inventory_take(pos, listname, index, stack, player)
	if not player or not player:is_player() then
		return 0
	end
	if minetest.test_protection(pos, player:get_player_name()) then
		return 0
	end

	if listname~="input" then
		return 0
	end
	return stack:get_count()
end

function anvil.on_rightclick(pos, node, clicker, itemstack)
	if not clicker or not clicker:is_player() then
		return
	end

	if minetest.test_protection(pos, clicker:get_player_name()) then
		return itemstack
	end

	-- If player is wielding nothing.
	if itemstack:get_count() == 0 then
		local meta = minetest.env:get_meta(pos)
		local inv = meta:get_inventory()
		if not inv:is_empty("input") then
			local return_stack = inv:get_stack("input", 1)
			inv:set_stack("input", 1, nil)
			--clicker:get_inventory():add_item("main", return_stack)
			remove_item(pos, node)
			return return_stack
			--return itemstack
		end
	end

	local this_def = minetest.reg_ns_nodes[node.name]
	if this_def.allow_metadata_inventory_put(pos, "input", 1, itemstack:peek_item(), clicker) > 0 then
		local s = itemstack:take_item()
		local meta = minetest.env:get_meta(pos)
		local inv = meta:get_inventory()
		inv:add_item("input", s)
		update_item(pos,node)
	end
	return itemstack
end

function anvil.on_punch(pos, node, puncher)
	if( not( pos ) or not( node ) or not( puncher )) then
		return
	end

	if minetest.test_protection(pos, puncher:get_player_name()) then
		return
	end

	update_item_if_needed(pos, node)

	local wielded = puncher:get_wielded_item()
	local meta = minetest.get_meta(pos)
	local inv  = meta:get_inventory()

	if wielded:get_count() == 0 then
		if not inv:is_empty("input") then
			local return_stack = inv:get_stack("input", 1)
			inv:set_stack("input", 1, nil)
			puncher:get_inventory():add_item("main", return_stack)
			remove_item(pos, node)
		end
	end

	-- Only punching with the hammer is supposed to work.
	local wieldname = wielded:get_name()
	if wieldname ~= 'anvil:hammer' and wieldname ~= "xdecor:hammer" then
		return
	end
	local hammerwear = 300
	-- The xdecor hammer wears out faster (it is cheaper to craft).
	if wieldname == "xdecor:hammer" then
		hammerwear = 1000
	end

	local input = inv:get_stack('input',1)

	-- Only tools can be repaired.
	if( not( input )
	or input:is_empty()
			or input:get_name() == "cans:water_can"
			or input:get_name() == "cans:lava_can" ) then
		return
	end

	-- 65535 is max damage.
	local damage_state = 40-math.floor(input:get_wear()/1638)

	local tool_name = input:get_name()

	local hud2 = nil
	local hud3 = nil
	if( input:get_wear()>0 ) then
		hud2 = puncher:hud_add({
			hud_elem_type = "statbar",
			text = "default_cloud.png^[colorize:#ff0000:256",
			number = 40,
			direction = 0, -- left to right
			position = {x=0.5, y=0.65},
			alignment = {x = 0, y = 0},
			offset = {x = -320, y = 0},
			size = {x=32, y=32},
		})
		hud3 = puncher:hud_add({
			hud_elem_type = "statbar",
			text = "default_cloud.png^[colorize:#00ff00:256",
			number = damage_state,
			direction = 0, -- left to right
			position = {x=0.5, y=0.65},
			alignment = {x = 0, y = 0},
			offset = {x = -320, y = 0},
			size = {x=32, y=32},
		})
	end
	minetest.after(2, function()
		if( puncher ) then
			puncher:hud_remove(hud2)
			puncher:hud_remove(hud3)
		end
	end)

	-- Tell the player when the job is done.
	if (input:get_wear() == 0) then
		local tool_desc
		if minetest.registered_items[tool_name] and minetest.registered_items[tool_name].description then
			tool_desc = utility.get_short_desc(minetest.registered_items[tool_name].description)
		else
			tool_desc = tool_name
		end
		local pname = puncher:get_player_name()
		minetest.chat_send_player(pname, '# Server: Your `' .. tool_desc .. '` has been repaired successfully.')
		return
	else
		pos.y = pos.y + item_displacement
		ambiance.sound_play("anvil_clang", pos, 1.0, 30)
		minetest.add_particlespawner({
			amount = math.random(3, 10),
			time = 0.1,
			minpos = pos,
			maxpos = pos,
			minvel = {x=2, y=3, z=2},
			maxvel = {x=-2, y=1, z=-2},
			minacc = {x=0, y= -10, z=0},
			maxacc = {x=0, y= -10, z=0},
			minexptime = 0.5,
			maxexptime = 1,
			minsize = 1,
			maxsize = 1,
			collisiondetection = true,
			vertical = false,
			texture = "anvil_spark.png",
		})
	end

	-- Do the actual repair.
	input:add_wear( -1500 )
	inv:set_stack("input", 1, input)

	-- Damage the hammer slightly.
	wielded:add_wear(hammerwear)
	if wielded:is_empty() then
		ambiance.sound_play("default_tool_breaks", pos, 1.0, 10)
	end
	puncher:set_wielded_item( wielded )
end

if not anvil.registered then
	minetest.register_alias("castle:anvil", "anvil:anvil")

	-- The hammer for the anvil.
	minetest.register_tool("anvil:hammer", {
		description = "Steel Blacksmithing Hammer",
		groups = {not_repaired_by_anvil = 1},
		sound = {breaks = "default_tool_breaks"},
		image           = "anvil_tool_steelhammer.png",
		inventory_image = "anvil_tool_steelhammer.png",
		tool_capabilities = tooldata["pick_wood"],
	})

	-- The anvil itself.
	minetest.register_node("anvil:anvil", {
		drawtype = "nodebox",
		description = "Anvil",
		tiles = {"chains_iron.png", "default_stone.png"},
		paramtype  = "light",
		paramtype2 = "facedir",
		groups = utility.dig_groups("machine", {falling_node=1}),
		sounds = default.node_sound_metal_defaults(),
		is_ground_content = false,

		-- The nodebox model comes from realtest.
		-- It has been modified to fit this game.
		node_box = {
			type = "fixed",
			fixed = {
				-- Base
				{-0.5,-0.5,-0.3,0.5,-0.4,0.3},

				-- Column
				{-0.35,-0.4,-0.25,0.35,-0.3,0.25},
				{-0.3,-0.3,-0.15,0.3,-0.1,0.15},

				-- Top
				{-0.5,-0.1,-0.2,0.5,0.1,0.2},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				-- Base
				{-0.5,-0.5,-0.3,0.5,-0.4,0.3},

				-- Column
				{-0.35,-0.4,-0.25,0.35,-0.3,0.25},
				{-0.3,-0.3,-0.15,0.3,-0.1,0.15},

				-- Top
				{-0.5,-0.1,-0.2,0.5,0.1,0.2},
			}
		},

		on_construct = function(...)
			return anvil.on_construct(...)
		end,

		on_destruct = function(...)
			return anvil.on_destruct(...)
		end,

		on_finish_collapse = function(...)
			return anvil.on_finish_collapse(...)
		end,

		after_place_node = function(...)
			return anvil.after_place_node(...)
		end,

		can_dig = function(...)
			return anvil.can_dig(...)
		end,

		allow_metadata_inventory_put = function(...)
			return anvil.allow_metadata_inventory_put(...)
		end,

		allow_metadata_inventory_take = function(...)
			return anvil.allow_metadata_inventory_take(...)
		end,

		allow_metadata_inventory_move = function(...)
			return anvil.allow_metadata_inventory_move(...)
		end,

		on_rightclick = function(...)
			return anvil.on_rightclick(...)
		end,

		on_punch = function(...)
			return anvil.on_punch(...)
		end,
	})

	minetest.register_entity("anvil:item", {
		hp_max = 1,
		visual="wielditem",
		visual_size={x=.33,y=.33},
		collisionbox = {0,0,0,0,0,0},
		physical=false,
		textures={"air"},

		on_activate = function(...)
			return anvil.on_activate(...)
		end,

		get_staticdata = function(...)
			return anvil.get_staticdata(...)
		end,
	})

	minetest.register_craft({
		output = "anvil:anvil",
		recipe = {
			{"carbon_steel:ingot","carbon_steel:ingot","carbon_steel:ingot"},
			{'',                   "cast_iron:ingot",''                   },
			{"default:steel_ingot","default:steel_ingot","default:steel_ingot"},
		},
	})

	minetest.register_craft({
		output = "anvil:hammer",
		recipe = {
			{"carbon_steel:ingot","group:stick","carbon_steel:ingot"},
			{"carbon_steel:ingot","group:stick","carbon_steel:ingot"},
			{'',                   "group:stick",      ''           },
		},
	})

	local c = "anvil:core"
	local f = anvil.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	anvil.registered = true
end


