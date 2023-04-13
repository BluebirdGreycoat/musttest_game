minetest.register_craftitem("throwing:arrow_shell", {
	description = "Shell Arrow",
	inventory_image = "throwing_arrow_shell.png",
})

minetest.register_node("throwing:arrow_shell_box", {
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
	tiles = {"throwing_arrow_shell.png", "throwing_arrow_shell.png", "throwing_arrow_shell_back.png", "throwing_arrow_shell_front.png", "throwing_arrow_shell_2.png", "throwing_arrow_shell.png"},
	groups = {not_in_creative_inventory=1},
})

local THROWING_ARROW_ENTITY={
	_name = "throwing:arrow_shell",
	physical = false,
	timer=0,
	visual = "wielditem",
	visual_size = {x=0.1, y=0.1},
	textures = {"throwing:arrow_shell_box"},
	lastpos={},
	collisionbox = {0,0,0,0,0,0},
}

local radius = 1

local function add_effects(pos, radius)
	minetest.add_particlespawner({
		amount = 8,
		time = 0.5,
		minpos = vector.subtract(pos, radius / 2),
		maxpos = vector.add(pos, radius / 2),
		minvel = {x=-10, y=-10, z=-10},
		maxvel = {x=10,  y=10,  z=10},
		minacc = vector.new(),
		maxacc = vector.new(),
		minexptime = 0.5,
		maxexptime = 1,
		minsize = 0.5,
		maxsize = 1,
		texture = "tnt_smoke.png",
	})
end


local function boom(pos)
	minetest.sound_play("throwing_shell_explode", {pos=pos, gain=1.5, max_hear_distance=2*64}, true)
	
  -- Don't destroy things.
  if minetest.get_node(pos).name == "air" then
    minetest.set_node(pos, {name="tnt:boom"})
    minetest.get_node_timer(pos):start(0.1)
  end
	
  add_effects(pos, radius)
end

-- Back to the arrow

THROWING_ARROW_ENTITY.on_step = function(self, dtime)
	self.timer=self.timer+dtime
	local pos = self.object:get_pos()
	local node = minetest.get_node(pos)

	if self.timer>0.2 then
		local vel = self.object:get_velocity()
		local objs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, 2)
		for k, obj in pairs(objs) do
			if obj:get_luaentity() ~= nil then
				local oname = obj:get_luaentity().name
				if not throwing.entity_blocks_arrow(oname) then
					local speed = vector.length(vel)
					local damage = (((speed + 5)^1.2)/10 + 12) * 1
					throwing_arrow_punch_entity(obj, self, damage*500)
					self.object:remove()
					boom(pos)
				end
      elseif obj:is_player() then
        local speed = vector.length(vel)
        local damage = ((speed + 5)^1.2)/10 + 12
        throwing_arrow_punch_entity(obj, self, damage*500)
        self.object:remove()
        boom(pos)
			end
		end
	end

	if self.lastpos.x~=nil then
		if throwing_node_should_block_arrow(node.name) then
			self.object:remove()
			boom(self.lastpos)
		end
	end
	self.lastpos={x=pos.x, y=pos.y, z=pos.z}
end

minetest.register_entity("throwing:arrow_shell_entity", THROWING_ARROW_ENTITY)

minetest.register_craft({
	output = 'throwing:arrow_shell 8',
	recipe = {
		{'default:stick', 'tnt:gunpowder', 'default:copper_ingot'},
	}
})

minetest.register_craft({
	output = 'throwing:arrow_shell 8',
	recipe = {
		{'default:copper_ingot', 'tnt:gunpowder', 'default:stick'},
	}
})
