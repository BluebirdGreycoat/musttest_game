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
	lastpos = {},
	collisionbox = {0,0,0,0,0,0},
	player = "",
}

local air_nodes = {"air", "group:airlike"}

THROWING_ARROW_ENTITY.on_step = function(self, dtime)
	self.timer = self.timer + dtime
	local pos = self.object:get_pos()
	local rpos = vector.round(pos)
	local node = minetest.get_node(rpos)

	-- Player may have logged off after firing the arrow.
	if not self.player_name then
		self.object:remove()
		return
	end

	local player = minetest.get_player_by_name(self.player_name)

	if not player then
		self.object:remove()
		return
	end

	-- Collide with entities.
	if self.timer > 0.2 then
		local objs = minetest.get_objects_inside_radius({x=pos.x, y=pos.y, z=pos.z}, 2)

		for k, obj in pairs(objs) do
			if obj:get_luaentity() ~= nil then
				local oname = obj:get_luaentity().name

				if not throwing.entity_blocks_arrow(oname) then

					-- Do not TP player unless we find air.
					local tpos = minetest.find_node_near(rpos, 1, air_nodes, true)
					if tpos then
						player:set_pos(tpos)
					end

					self.object:remove()
					return
				end
			end
		end
	end

	-- Collide with nodes.
	-- (Note: 'lastpos' table is never nil because it is part of entity definition.)
	if self.lastpos.x ~= nil then
		local prevnode = minetest.get_node(vector.round(self.lastpos))
		if not throwing_node_should_block_arrow(prevnode.name) then
			if throwing_node_should_block_arrow(node.name) then

				local tpos = minetest.find_node_near(vector.round(self.lastpos), 1, air_nodes, true)
				if tpos then
					player:set_pos(tpos)
				end

				self.object:remove()
				return
			end
		end
	end

	self.lastpos = {x=pos.x, y=pos.y, z=pos.z}
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
