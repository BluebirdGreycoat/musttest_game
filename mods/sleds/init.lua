-- Sled mod, copied from boat mod and modified.
-- Mod is reloadable.
sleds = sleds or {}
sleds.modpath = minetest.get_modpath("sleds")
sleds.players = sleds.players or {}



local function is_snow(pos)
	local nn = minetest.get_node(pos).name
	local def = minetest.registered_nodes[nn]
	if def and def.groups then
		if def.groups.snow and def.groups.snow > 0 then
			return true
		end
		if def.groups.ice and def.groups.ice > 0 then
			return true
		end
	end
	return false
end

local function is_snow_or_air(pos)
	local nn = minetest.get_node(pos).name
	if nn == "air" or snow.is_snow(nn) then
		return true
	end
	local def = minetest.registered_nodes[nn]
	if def and def.groups then
		if def.groups.snow and def.groups.snow > 0 then
			return true
		end
		if def.groups.ice and def.groups.ice > 0 then
			return true
		end
	end
	return false
end

local function get_velocity(v, yaw, y)
	local x = -math.sin(yaw) * v
	local z =  math.cos(yaw) * v
	return {x=x, y=y, z=z}
end

local function get_v(v)
	return math.sqrt(v.x ^ 2 + v.z ^ 2)
end



function sleds.on_rightclick(self, clicker)
	if not clicker or not clicker:is_player() then
		return
	end
	if clicker:get_hp() == 0 then
		return
	end
	local name = clicker:get_player_name()
	if self.driver and clicker == self.driver then
		self.driver = nil
		clicker:set_detach()
		--clicker:set_properties({collisionbox = sleds.players[name].cb})
		default.player_attached[name] = false
		default.player_set_animation(clicker, "stand" , 30)
		local pos = clicker:getpos()
		pos = {x = pos.x, y = pos.y + 0.2, z = pos.z}
		minetest.after(0.1, function() clicker:set_pos(pos) end)
	elseif not self.driver then
		-- Not while attached to something else!
		if default.player_attached[name] then
			return
		end

		local attach = clicker:get_attach()
		if attach and attach:get_luaentity() then
			local luaentity = attach:get_luaentity()
			if luaentity.driver then
				luaentity.driver = nil
			end
			clicker:set_detach()
			--clicker:set_properties({collisionbox = sleds.players[name].cb})
		end
		self.driver = clicker
		clicker:set_attach(self.object, "", {x = 0, y = 0.1, z = -3}, {x = 0, y = 0, z = 0})
		default.player_attached[name] = true
		minetest.after(0.2, function() default.player_set_animation(clicker, "sit" , 30) end)
		clicker:set_look_horizontal(self.object:getyaw())
		--clicker:set_properties({stepheight=3})

		local pp = clicker:get_properties()
		sleds.players[name] = {}
		--sleds.players[name].cb = pp.collisionbox
		--clicker:set_properties({collisionbox = {0}})
	end
end

function sleds.on_activate(self, data)
	self.object:set_armor_groups({immortal = 1})
	self.object:set_acceleration({x = 0, y = -9.8, z = 0}) -- Gravity.
	if data then
		local info = minetest.deserialize(data) or {}
		self.v = info.v or 0
		self.y = info.y or 0
	end
end

function sleds.get_staticdata(self)
	return minetest.serialize({
		v = self.v,
		y = self.y,
	})
end

function sleds.on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir)
	if not puncher or not puncher:is_player() or self.removed then
		return
	end
	if self.driver and puncher == self.driver then
		self.driver = nil
		local name = puncher:get_player_name()
		puncher:set_detach()
		--puncher:set_properties({collisionbox = sleds.players[name].cb})
		default.player_attached[name] = false
	end
	if not self.driver then
		self.removed = true
		local inv = puncher:get_inventory()
		if not minetest.setting_getbool("creative_mode")
				or not inv:contains_item("main", "sleds:sled") then
			local leftover = inv:add_item("main", "sleds:sled")
			-- if no room in inventory add a replacement sled to the world
			if not leftover:is_empty() then
				minetest.add_item(self.object:getpos(), leftover)
			end
		end
		-- delay remove to ensure player is detached
		minetest.after(0.1, function()
			self.object:remove()
		end)
	end
end

function sleds.on_step(self, dtime)
	local velo = self.object:get_velocity()
	local pos = self.object:get_pos()
	self.v = get_v(velo)

	-- Slow the sled down gradually.
	if is_snow_or_air({x=pos.x, y=pos.y-0.3, z=pos.z}) then
		self.v = self.v - 0.02
	else
		self.v = self.v - 0.2
	end
	if self.v < 0 then
		self.v = 0
	end

	-- Update jump timer.
	self.jump = (self.jump or 0) - dtime
	if self.jump < 0 then self.jump = 0 end

	-- Accelerate sled forwards if going downhill.
	local is_flying = false
	local last_y = self.y
	self.y = pos.y
	if self.y < last_y then
		if self.v > 2 then
			local node = minetest.get_node({x=pos.x, y=pos.y-2, z=pos.z})
			-- But not if sled is flying.
			if node.name ~= "air" then
				self.v = self.v + 0.2
			else
				-- Don't compute driver controls if flying.
				is_flying = true
			end
		end
	end

	-- Driver controls.
	if not is_flying and self.driver then
		local ctrl = self.driver:get_player_control()
		local yaw = self.object:get_yaw()
		if ctrl.up then
			-- Cannot accelerate faster than this if player-powered.
			if self.v < 7 then
				self.v = self.v + 0.1
			end
		elseif ctrl.down then
			self.v = self.v - 0.13
		end
		if ctrl.left then
			self.object:set_yaw(yaw + (1 + dtime) * 0.03)
		elseif ctrl.right then
			self.object:set_yaw(yaw - (1 + dtime) * 0.03)
		end

		-- Allow sled to jump, if velocity high enough and
		-- pilot hasn't already executed a jump.
		if ctrl.jump and self.v > 6 and (self.jump or 0) <= 0 then
			local sta = sprint.get_stamina(self.driver)
			local stacost = 5
			if sta >= stacost then
				velo.y = velo.y + 6
				self.v = self.v - 1 -- Knock velocity down a bit.
				self.jump = 1.5 -- Delay before pilot can jump again.
				sprint.add_stamina(self.driver, -stacost)
			end
		end
	end

	local new_velo = get_velocity(self.v, self.object:get_yaw(), velo.y)
	self.object:set_velocity(new_velo)
end

function sleds.on_place(itemstack, placer, pointed_thing)
	local under = pointed_thing.under
	local node = minetest.get_node(under)
	local udef = minetest.registered_nodes[node.name]
	if udef and udef.on_rightclick and
			not (placer and placer:get_player_control().sneak) then
		return udef.on_rightclick(under, node, placer, itemstack,
			pointed_thing) or itemstack
	end

	if pointed_thing.type ~= "node" then
		return itemstack
	end
	if not is_snow(pointed_thing.under) then
		return itemstack
	end
	pointed_thing.under.y = pointed_thing.under.y + 1.0
	local sled = minetest.add_entity(pointed_thing.under, "sleds:sled")
	if sled then
		sled:setyaw(placer:get_look_horizontal())
		if not minetest.setting_getbool("creative_mode") then
			itemstack:take_item()
		end
	end
	return itemstack
end



if not sleds.run_once then
	-- Sled entity.
	local sled = {
		visual = "mesh",
		mesh = "sled.obj",
		textures = {"sled.png"},
		stepheight = 0.5,
		physical = true,

		collisionbox = {-0.7, -0.20, -0.7, 0.7, 0.5, 0.7},
		--selection_box = {-0.7, -0.20, -0.7, 0.7, 0.2, 0.7},

		driver = nil,
		v = 0,
		y = 0,
		removed = false,

		on_rightclick = function(...)
			return sleds.on_rightclick(...)
		end,

		on_activate = function(...)
			return sleds.on_activate(...)
		end,

		get_staticdata = function(...)
			return sleds.get_staticdata(...)
		end,

		on_punch = function(...)
			return sleds.on_punch(...)
		end,

		on_step = function(...)
			return sleds.on_step(...)
		end,
	}

	minetest.register_entity("sleds:sled", sled)

	minetest.register_craftitem("sleds:sled", {
		description = "Sled\nUseable on snow.",
		inventory_image = "snow_sled.png",
		wield_image = "snow_sled.png",
		wield_scale = {x=2, y=2, z=1},
		liquids_pointable = true,
		groups = {flammable = 2},

		on_place = function(...)
			return sleds.on_place(...)
		end,
	})

	minetest.register_craft({
		output = "sleds:sled",
		recipe = {
			{"group:stick", "", "group:stick"},
			{"group:wood", "group:wood", "group:wood"},
			{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		},
	})

	minetest.register_craft({
		type = "fuel",
		recipe = "sleds:sled",
		burntime = 20,
	})

	-- File is reloadable.
	local c = "sleds:core"
	local f = sleds.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	sleds.run_once = true
end
