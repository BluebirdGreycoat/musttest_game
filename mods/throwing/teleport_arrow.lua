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

	-- Raycast collisions with nodes. Ignore entities, they're not really useful.
	-- (Note: 'lastpos' table is never nil because it is part of entity definition.
	-- This is why test is against 'x' key here.)
	--
	-- Update: arrow throwing function now always sets 'lastpos' when the arrow
	-- entity is spawned (to solve problems where the arrow has moved some distance
	-- before the 'on_step' function gets called). Still checking this to avoid
	-- problems with old arrow entities in the world.
	if self.lastpos.x ~= nil then
		local ray = minetest.raycast(self.lastpos, pos, false, true)

		for thing in ray do
			if thing.type == "node" then
				local nodeu = minetest.get_node(thing.under)
				local nodea = minetest.get_node(thing.above)

				local blocku = throwing_node_should_block_arrow(nodeu.name)
				local blocka = throwing_node_should_block_arrow(nodea.name)

				if not blocka and blocku then
					local tpos = minetest.find_node_near(thing.above, 1, air_nodes, true)
					if tpos then
						player:set_pos(tpos)
					end

					self.object:remove()
					return
				elseif (blocka and blocku) or (blocka and not blocku) then
					-- Arrow was fired from inside solid nodes.
					self.object:remove()
					return
				end
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
