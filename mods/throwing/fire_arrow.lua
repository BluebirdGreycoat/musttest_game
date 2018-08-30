minetest.register_craftitem("throwing:arrow_fire", {
	description = "Fire Arrow",
	inventory_image = "throwing_arrow_fire.png",
})

minetest.register_node("throwing:arrow_fire_box", {
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			-- Shaft
			{-6.5/17, -1.5/17, -1.5/17, 6.5/17, 1.5/17, 1.5/17},
			--Spitze
			{-4.5/17, 2.5/17, 2.5/17, -3.5/17, -2.5/17, -2.5/17},
			{-8.5/17, 0.5/17, 0.5/17, -6.5/17, -0.5/17, -0.5/17},
			--Federn
			{6.5/17, 1.5/17, 1.5/17, 7.5/17, 2.5/17, 2.5/17},
			{7.5/17, -2.5/17, 2.5/17, 6.5/17, -1.5/17, 1.5/17},
			{7.5/17, 2.5/17, -2.5/17, 6.5/17, 1.5/17, -1.5/17},
			{6.5/17, -1.5/17, -1.5/17, 7.5/17, -2.5/17, -2.5/17},
			
			{7.5/17, 2.5/17, 2.5/17, 8.5/17, 3.5/17, 3.5/17},
			{8.5/17, -3.5/17, 3.5/17, 7.5/17, -2.5/17, 2.5/17},
			{8.5/17, 3.5/17, -3.5/17, 7.5/17, 2.5/17, -2.5/17},
			{7.5/17, -2.5/17, -2.5/17, 8.5/17, -3.5/17, -3.5/17},
		}
	},
	tiles = {"throwing_arrow_fire.png", "throwing_arrow_fire.png", "throwing_arrow_fire_back.png", "throwing_arrow_fire_front.png", "throwing_arrow_fire_2.png", "throwing_arrow_fire.png"},
	groups = {not_in_creative_inventory=1},
})

local THROWING_ARROW_ENTITY={
	physical = false,
	timer=0,
	visual = "wielditem",
	visual_size = {x=0.1, y=0.1},
	textures = {"throwing:arrow_fire_box"},
	lastpos={},
	collisionbox = {0,0,0,0,0,0},
}

THROWING_ARROW_ENTITY.on_step = function(self, dtime)
	self.timer=self.timer+dtime
	local pos = self.object:getpos()
	local node = minetest.get_node(pos)

	if self.timer>0.2 then
		local objs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, 2)
		for k, obj in pairs(objs) do
			if obj:get_luaentity() ~= nil then
				if obj:get_luaentity().name ~= "throwing:arrow_fire_entity" and obj:get_luaentity().name ~= "__builtin:item" then
					local damage = 4
					throwing_arrow_punch_entity(obj, self, damage)
					self.object:remove()
					minetest.add_item(self.lastpos, 'default:stick')
				end
      elseif obj:is_player() then
        local damage = 4
        throwing_arrow_punch_entity(obj, self, damage)
        self.object:remove()
        minetest.add_item(self.lastpos, 'default:stick')
			end
		end
	end

	if self.lastpos.x~=nil then
		if throwing_node_should_block_arrow(node.name) then
      if node.name == "throwing:light" or not minetest.test_protection(self.lastpos, "") then
        minetest.set_node(self.lastpos, {name="fire:basic_flame"})
      else
        local fpos = minetest.find_node_near(pos, 1, "air")
        if fpos then
          minetest.set_node(fpos, {name="fire:basic_flame"})
        end
      end
      minetest.sound_play("throwing_shell_explode", {pos=pos, gain=1.0, max_hear_distance=2*64})
			self.object:remove()
		end
		if math.floor(self.lastpos.x+0.5) ~= math.floor(pos.x+0.5) or
			math.floor(self.lastpos.y+0.5) ~= math.floor(pos.y+0.5) or
			math.floor(self.lastpos.z+0.5) ~= math.floor(pos.z+0.5) then
			if minetest.get_node(pos).name == "air" then
				minetest.set_node(pos, {name="throwing:light"})
			end
		end
	end
	self.lastpos={x=pos.x, y=pos.y, z=pos.z}
end

minetest.register_entity("throwing:arrow_fire_entity", THROWING_ARROW_ENTITY)

minetest.register_node("throwing:light", {
	drawtype = "airlike",
	paramtype = "light",
	sunlight_propagates = true,
	tiles = {"throwing_empty.png"},
	light_source = default.LIGHT_MAX-5,
	selection_box = {
		type = "fixed",
		fixed = {
			{0,0,0,0,0,0}
		}
	},
	groups = {not_in_creative_inventory=1},

	on_construct = function(pos)
		minetest.get_node_timer(pos):start(0.5)
	end,

	on_timer = function(pos, elapsed)
		minetest.remove_node(pos)
	end,
})

minetest.register_craft({
	output = 'throwing:arrow_fire',
	recipe = {
		{'default:stick', 'default:stick', 'default:torch'},
	},
})

minetest.register_craft({
	output = 'throwing:arrow_fire',
	recipe = {
		{'default:torch', 'default:stick', 'default:stick'},
	},
})

