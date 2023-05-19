-----------------------revolver---------------

minetest.register_tool("xtraores:platinum_revolver", {
		description = "".. core.colorize("#68fff6", "Platinum revolver\n")..core.colorize("#FFFFFF", "Ranged damage: 6\n")..core.colorize("#FFFFFF", "Bullet speed: 30\n")..core.colorize("#FFFFFF", "Xtraores gun level: 2"),
	inventory_image = "xtraores_platinum_revolver.png",
	wield_scale = {x=1.0,y=1.0,z=1.0},
	on_use = function(itemstack, user, pointed_thing)
		local inv = user:get_inventory()
		if not inv:contains_item("main", "xtraores:platinum_bullet 1") then
			minetest.sound_play("xtraores_empty", {object=user})
			return itemstack
		end
		if not minetest.setting_getbool("creative_mode") then
			inv:remove_item("main", "xtraores:platinum_bullet ")	
itemstack:add_wear(65535/1000)
		end
		local pos = user:getpos()
		local dir = user:get_look_dir()
		local yaw = user:get_look_yaw()
		if pos and dir and yaw then
			pos.y = pos.y + 1.6
			local obj = minetest.add_entity(pos, "xtraores:platinumshot")
			if obj then
				minetest.sound_play("xtraores_rifle", {object=obj})
				obj:set_velocity({x=dir.x * 30, y=dir.y * 30, z=dir.z * 30})
				obj:set_acceleration({x=dir.x * 0, y=0, z=dir.z * 0})
				obj:setyaw(yaw + math.pi)
			pos.y = pos.y - 0.2
			local obj = minetest.add_entity(pos, "xtraores:gunsmoke")
				minetest.sound_play("xtraores_rifle", {object=obj})
				obj:set_velocity({x=dir.x * 3, y=dir.y * 3, z=dir.z * 3})
				obj:set_acceleration({x=dir.x * -4, y=2, z=dir.z * -4})
				obj:setyaw(yaw + math.pi)

				local ent = obj:get_luaentity()
				if ent then
					ent.player = ent.player or user
				end
			end
		end
		return itemstack
	end,
})

local xtraores_platinumshot = {
	physical = false,
	timer = 0,
	visual = "wielditem",
	visual_size = {x=0.25, y=0.4,},
	textures = {'xtraores:platinum_shot'},
	lastpos= {},
	collisionbox = {0, 0, 0, 0, 0, 0},
}
xtraores_platinumshot.on_step = function(self, dtime)
	self.timer = self.timer + dtime
	local pos = self.object:getpos()
	local node = minetest.get_node(pos)

	if self.timer > 0.10 then
		local objs = minetest.get_objects_inside_radius({x = pos.x, y = pos.y, z = pos.z}, 1)
		for k, obj in pairs(objs) do
			if obj:get_luaentity() ~= nil then
				if obj:get_luaentity().name ~= "xtraores:platinumshot" and obj:get_luaentity().name ~= "__builtin:item" then
					local damage = 6
					obj:punch(self.object, 1.0, {
						full_punch_interval = 1.0,
						damage_groups= {fleshy = damage},
					}, nil)
					minetest.sound_play("default_dig_cracky", {pos = self.lastpos, gain = 0.8})
					self.object:remove()
				end
			else
				local damage = 6
				obj:punch(self.object, 1.0, {
					full_punch_interval = 1.0,
					damage_groups= {fleshy = damage},
				}, nil)
				minetest.sound_play("default_dig_cracky", {pos = self.lastpos, gain = 0.8})
				self.object:remove()
			end
		end
	end

	if self.lastpos.x ~= nil then
		if minetest.registered_nodes[node.name].walkable then
			if not minetest.setting_getbool("creative_mode") then
				minetest.add_item(self.lastpos, "")
			end
			minetest.sound_play("default_dig_cracky", {pos = self.lastpos, gain = 0.8})
			self.object:remove()
		end
	end
	self.lastpos= {x = pos.x, y = pos.y, z = pos.z}
end

minetest.register_entity("xtraores:platinumshot", xtraores_platinumshot)

minetest.register_craftitem("xtraores:platinum_shot", {
	inventory_image = "xtraores_platinum_shot.png",
})

minetest.register_craftitem("xtraores:platinum_bullet", {
		description = "".. core.colorize("#68fff6", "Platinum  bullet\n")..core.colorize("#FFFFFF", "Used by guns of level 2\n")..core.colorize("#FFFFFF", "Xtraores ammo level: 2"),
	stack_max= 500,
	inventory_image = "xtraores_platinum_bullet.png",
})

minetest.register_craft( {
	type = "shapeless",
	output = "xtraores:platinum_revolver",
	recipe = {"xtraores:platinum_revolver_base", "xtraores:platinum_mag", "xtraores:revolver_handle"},
})

minetest.register_craft({
	output = 'xtraores:platinum_bullet 25',
	recipe = {
		{'', 'default:gold_ingot', ''},
		{'', 'xtraores:platinum_bar', ''},
		{'', 'xtraores:platinum_bar', ''},
	}
})

-----------------------handgun---------------

minetest.register_tool("xtraores:cobalt_handgun", {
		description = "".. core.colorize("#68fff6", "Cobalt handgun\n")..core.colorize("#FFFFFF", "Ranged damage: 12\n")..core.colorize("#FFFFFF", "Bullet speed: 45\n")..core.colorize("#FFFFFF", "Xtraores gun level: 4"),
	inventory_image = "xtraores_cobalt_handgun.png",
	wield_scale = {x=1.0,y=1.0,z=1.0},
	on_use = function(itemstack, user, pointed_thing)
		local inv = user:get_inventory()
		if not inv:contains_item("main", "xtraores:cobalt_bullet 1") then
			minetest.sound_play("xtraores_empty", {object=user})
			return itemstack
		end
		if not minetest.setting_getbool("creative_mode") then
			inv:remove_item("main", "xtraores:cobalt_bullet ")	
itemstack:add_wear(65535/1750)
		end
		local pos = user:getpos()
		local dir = user:get_look_dir()
		local yaw = user:get_look_yaw()
		if pos and dir and yaw then
			pos.y = pos.y + 1.6
			local obj = minetest.add_entity(pos, "xtraores:cobaltshot")
			if obj then
				minetest.sound_play("xtraores_handgun", {object=obj})
				obj:set_velocity({x=dir.x * 45, y=dir.y * 45, z=dir.z * 45})
				obj:set_acceleration({x=dir.x * 0, y=0, z=dir.z * 0})
				obj:setyaw(yaw + math.pi)
			pos.y = pos.y - 0.2
			local obj = minetest.add_entity(pos, "xtraores:gunsmoke")
				minetest.sound_play("xtraores_handgun", {object=obj})
				obj:set_velocity({x=dir.x * 3, y=dir.y * 3, z=dir.z * 3})
				obj:set_acceleration({x=dir.x * -4, y=2, z=dir.z * -4})
				obj:setyaw(yaw + math.pi)

				local ent = obj:get_luaentity()
				if ent then
					ent.player = ent.player or user
				end
			end
		end
		return itemstack
	end,
})

local xtraores_cobaltshot = {
	physical = false,
	timer = 0,
	visual = "wielditem",
	visual_size = {x=0.25, y=0.4,},
	textures = {'xtraores:cobalt_shot'},
	lastpos= {},
	collisionbox = {0, 0, 0, 0, 0, 0},
}
xtraores_cobaltshot.on_step = function(self, dtime)
	self.timer = self.timer + dtime
	local pos = self.object:getpos()
	local node = minetest.get_node(pos)

	if self.timer > 0.07 then
		local objs = minetest.get_objects_inside_radius({x = pos.x, y = pos.y, z = pos.z}, 1)
		for k, obj in pairs(objs) do
			if obj:get_luaentity() ~= nil then
				if obj:get_luaentity().name ~= "xtraores:cobaltshot" and obj:get_luaentity().name ~= "__builtin:item" then
					local damage = 12
					obj:punch(self.object, 1.0, {
						full_punch_interval = 1.0,
						damage_groups= {fleshy = damage},
					}, nil)
					minetest.sound_play("default_dig_cracky", {pos = self.lastpos, gain = 0.8})
					self.object:remove()
				end
			else
				local damage = 12
				obj:punch(self.object, 1.0, {
					full_punch_interval = 1.0,
					damage_groups= {fleshy = damage},
				}, nil)
				minetest.sound_play("default_dig_cracky", {pos = self.lastpos, gain = 0.8})
				self.object:remove()
			end
		end
	end

	if self.lastpos.x ~= nil then
		if minetest.registered_nodes[node.name].walkable then
			if not minetest.setting_getbool("creative_mode") then
				minetest.add_item(self.lastpos, "")
			end
			minetest.sound_play("default_dig_cracky", {pos = self.lastpos, gain = 0.8})
			self.object:remove()
		end
	end
	self.lastpos= {x = pos.x, y = pos.y, z = pos.z}
end

minetest.register_entity("xtraores:cobaltshot", xtraores_cobaltshot)

minetest.register_craftitem("xtraores:cobalt_shot", {
	inventory_image = "xtraores_cobalt_shot.png",
})

minetest.register_craftitem("xtraores:cobalt_bullet", {
		description = "".. core.colorize("#68fff6", "cobalt  bullet\n")..core.colorize("#FFFFFF", "Used by guns of level 4\n")..core.colorize("#FFFFFF", "Xtraores ammo level: 4"),
	stack_max= 500,
	inventory_image = "xtraores_cobalt_bullet.png",
})

minetest.register_craft( {
	type = "shapeless",
	output = "xtraores:cobalt_handgun",
	recipe = {"xtraores:cobalt_top", "xtraores:cobalt_base", "xtraores:cobalt_handle"},
})

minetest.register_craft({
	output = 'xtraores:cobalt_bullet 25',
	recipe = {
		{'', 'xtraores:cobalt_bar', ''},
		{'', 'xtraores:cobalt_bar', ''},
		{'', 'default:mese_crystal', ''},
	}
})

-----------------------orichalcum_rifle---------------

minetest.register_tool("xtraores:orichalcum_rifle", {
		description = "".. core.colorize("#68fff6", "Orichalcum rifle\n")..core.colorize("#FFFFFF", "Ranged damage: 26\n")..core.colorize("#FFFFFF", "Bullet speed: 70\n")..core.colorize("#FFFFFF", "Xtraores gun level: 10"),
	inventory_image = "xtraores_orichalcum_rifle.png",
	wield_scale = {x=2.0,y=2.0,z=1.0},
	on_use = function(itemstack, user, pointed_thing)
		local inv = user:get_inventory()
		if not inv:contains_item("main", "xtraores:orichalcum_bullet 1") then
			minetest.sound_play("xtraores_empty", {object=user})
			return itemstack
		end
		if not minetest.setting_getbool("creative_mode") then
			inv:remove_item("main", "xtraores:orichalcum_bullet ")	
itemstack:add_wear(65535/9001)
		end
		local pos = user:getpos()
		local dir = user:get_look_dir()
		local yaw = user:get_look_yaw()
		if pos and dir and yaw then
			pos.y = pos.y + 1.6
			local obj = minetest.add_entity(pos, "xtraores:orichalcumshot")
			if obj then
				minetest.sound_play("xtraores_rifle", {object=obj})
				obj:set_velocity({x=dir.x * 70, y=dir.y * 70, z=dir.z * 70})
				obj:set_acceleration({x=dir.x * 0, y=0, z=dir.z * 0})
				obj:setyaw(yaw + math.pi)
			pos.y = pos.y - 0.2
			local obj = minetest.add_entity(pos, "xtraores:gunsmoke")
				minetest.sound_play("xtraores_rifle", {object=obj})
				obj:set_velocity({x=dir.x * 3, y=dir.y * 3, z=dir.z * 3})
				obj:set_acceleration({x=dir.x * -4, y=2, z=dir.z * -4})
				obj:setyaw(yaw + math.pi)

				local ent = obj:get_luaentity()
				if ent then
					ent.player = ent.player or user
				end
			end
		end
		return itemstack
	end,
})

local xtraores_orichalcumshot = {
	physical = false,
	timer = 0,
	visual = "wielditem",
	visual_size = {x=0.4, y=0.8,},
	textures = {'xtraores:orichalcum_shot'},
	lastpos= {},
	collisionbox = {0, 0, 0, 0, 0, 0},
}
xtraores_orichalcumshot.on_step = function(self, dtime)
	self.timer = self.timer + dtime
	local pos = self.object:getpos()
	local node = minetest.get_node(pos)

	if self.timer > 0.05 then
		local objs = minetest.get_objects_inside_radius({x = pos.x, y = pos.y, z = pos.z}, 1.5)
		for k, obj in pairs(objs) do
			if obj:get_luaentity() ~= nil then
				if obj:get_luaentity().name ~= "xtraores:orichalcumshot" and obj:get_luaentity().name ~= "__builtin:item" then
					local damage = 26
					obj:punch(self.object, 1.0, {
						full_punch_interval = 1.0,
						damage_groups= {fleshy = damage},
					}, nil)
					minetest.sound_play("default_dig_cracky", {pos = self.lastpos, gain = 0.8})
					self.object:remove()
				end
			else
				local damage = 26
				obj:punch(self.object, 1.0, {
					full_punch_interval = 1.0,
					damage_groups= {fleshy = damage},
				}, nil)
				minetest.sound_play("default_dig_cracky", {pos = self.lastpos, gain = 0.8})
				self.object:remove()
			end
		end
	end

	if self.lastpos.x ~= nil then
		if minetest.registered_nodes[node.name].walkable then
			if not minetest.setting_getbool("creative_mode") then
				minetest.add_item(self.lastpos, "")
			end
			minetest.sound_play("default_dig_cracky", {pos = self.lastpos, gain = 0.8})
			self.object:remove()
		end
	end
	self.lastpos= {x = pos.x, y = pos.y, z = pos.z}
end

minetest.register_entity("xtraores:orichalcumshot", xtraores_orichalcumshot)

minetest.register_craftitem("xtraores:orichalcum_shot", {
	inventory_image = "xtraores_orichalcum_shot.png",
	wield_scale = {x=2.0,y=1.0,z=1.0},
})

minetest.register_craftitem("xtraores:orichalcum_bullet", {
		description = "".. core.colorize("#68fff6", "orichalcum  bullet\n")..core.colorize("#FFFFFF", "Used by guns of level 10\n")..core.colorize("#FFFFFF", "Xtraores ammo level: 10"),
	stack_max= 500,
	inventory_image = "xtraores_orichalcum_bullet.png",
})

minetest.register_craft( {
	type = "shapeless",
	output = "xtraores:orichalcum_rifle",
	recipe = {"xtraores:orichalcum_rifle_barrel", "xtraores:orichalcum_rifle_scope", "xtraores:orichalcum_rifle_base", "xtraores:orichalcum_rifle_stock", "xtraores:orichalcum_rifle_grip",
"xtraores:orichalcum_rifle_handle" },
})

minetest.register_craft({
	output = 'xtraores:orichalcum_bullet 30',
	recipe = {
		{'', 'xtraores:orichalcum_bar', ''},
		{'', 'xtraores:orichalcum_bar', ''},
		{'', 'xtraores:antracite_ore', ''},
	}
})

local xtraores_gunsmoke = {
	physical = false,
	timer = 0,
	visual = "sprite",
	visual_size = {x=0.5, y=0.5,},
	textures = {'tnt_smoke.png'},
	lastpos= { },
	collisionbox = {0, 0, 0, 0, 0, 0},
}
xtraores_gunsmoke.on_step = function(self, dtime)
	self.timer = self.timer + dtime
	local pos = self.object:getpos()
	local node = minetest.get_node(pos)

	if self.timer > 1 then
		local objs = minetest.get_objects_inside_radius({x = pos.x, y = pos.y, z = pos.z}, 100)
		for k, obj in pairs(objs) do
			if obj:get_luaentity() ~= nil then
				if obj:get_luaentity().name ~= "xtraores:gunsmoke" and obj:get_luaentity().name ~= "__builtin:item" then

					self.object:remove()
				end

			end

		end

	end

	if self.lastpos.x ~= nil then
		if minetest.registered_nodes[node.name].walkable then
			if not minetest.setting_getbool("creative_mode") then
				minetest.add_item(self.lastpos, "")
			end

			self.object:remove()
		end
	end
	self.lastpos= {x = pos.x, y = pos.y, z = pos.z}
end
minetest.register_entity("xtraores:gunsmoke", xtraores_gunsmoke)
