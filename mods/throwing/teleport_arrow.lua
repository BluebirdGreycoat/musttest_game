minetest.register_craftitem("throwing:arrow_teleport", {
	description = "Teleport Arrow",
	inventory_image = "throwing_arrow_teleport.png",
})

minetest.register_node("throwing:arrow_teleport_box", {
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
	tiles = {"throwing_arrow_teleport.png", "throwing_arrow_teleport.png", "throwing_arrow_teleport_back.png", "throwing_arrow_teleport_front.png", "throwing_arrow_teleport_2.png", "throwing_arrow_teleport.png"},
	groups = {not_in_creative_inventory=1},
})

local THROWING_ARROW_ENTITY={
	_name = "throwing:arrow_teleport",
	physical = false,
	timer=0,
	visual = "wielditem",
	visual_size = {x=0.1, y=0.1},
	textures = {"throwing:arrow_teleport_box"},
	lastpos={},
	collisionbox = {0,0,0,0,0,0},
	player = "",
}

THROWING_ARROW_ENTITY.on_step = function(self, dtime)
	self.timer=self.timer+dtime
	local pos = self.object:get_pos()
	local node = minetest.get_node(pos)
	if not self.player then
		self.object:remove()
	end

	if self.timer>0.2 then
		local objs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, 2)
		for k, obj in pairs(objs) do
			if obj:get_luaentity() ~= nil then
				local oname = obj:get_luaentity().name
				if not throwing.entity_blocks_arrow(oname) then
					self.object:remove()
					if self.player ~= "" then
						self.player:set_pos(pos)
						self.player:get_inventory():add_item("main", ItemStack("default:stick 2"))
					end
				end
			end
		end
	end

	if self.lastpos.x~=nil then
		if throwing_node_should_block_arrow(node.name) then
			self.object:remove()
			if self.player ~= "" then
				self.player:set_pos(self.lastpos)
				self.player:get_inventory():add_item("main", ItemStack("default:stick 2"))
			end
		end
	end
	self.lastpos={x=pos.x, y=pos.y, z=pos.z}
end

minetest.register_entity("throwing:arrow_teleport_entity", THROWING_ARROW_ENTITY)

minetest.register_craft({
	output = 'throwing:arrow_teleport 8',
	recipe = {
		{'default:stick', 'default:stick', 'starpearl:pearl'}
	}
})

minetest.register_craft({
	output = 'throwing:arrow_teleport 8',
	recipe = {
		{'starpearl:pearl', 'default:stick', 'default:stick'}
	}
})
