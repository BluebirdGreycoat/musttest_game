minetest.register_craftitem("throwing:arrow_tnt", {
	description = "TNT Arrow",
	inventory_image = "throwing_arrow_tnt.png",
})

minetest.register_node("throwing:arrow_tnt_box", {
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
	tiles = {"throwing_arrow_tnt.png", "throwing_arrow_tnt.png", "throwing_arrow_tnt_back.png", "throwing_arrow_tnt_front.png", "throwing_arrow_tnt_2.png", "throwing_arrow_tnt.png"},
	groups = {not_in_creative_inventory=1},
})

local THROWING_ARROW_ENTITY={
	_name = "throwing:arrow_tnt",
	physical = false,
	timer=0,
	visual = "wielditem",
	visual_size = {x=0.1, y=0.1},
	textures = {"throwing:arrow_tnt_box"},
	lastpos={},
	collisionbox = {0,0,0,0,0,0},
}



local function boom(pos, pname)
  -- Detonate some TNT!
  tnt.boom(pos, {
    radius = 2,
    ignore_protection = false,
    ignore_on_blast = false,
    damage_radius = 5,
    disable_drops = true,
		name = pname,
		from_arrow = true,
  })
end

-- Back to the arrow

THROWING_ARROW_ENTITY.on_step = function(self, dtime)
	self.timer=self.timer+dtime
	local pos = self.object:get_pos()
	local node = minetest.get_node(pos)

  if self.timer>0.2 then
    local objs = minetest.get_objects_inside_radius(table.copy(pos), 2)
    for k, obj in pairs(objs) do
      if obj:get_luaentity() ~= nil then
				local oname = obj:get_luaentity().name
				if not throwing.entity_blocks_arrow(oname) then
          local damage = 1*500
					local pname = self.player_name

          -- Punch to alert mobs who hit them.
          throwing_arrow_punch_entity(obj, self, damage)

          boom(pos, pname)
          self.object:remove()
					return
        end
      elseif obj:is_player() then
        local damage = 1
				local pname = self.player_name

        boom(pos, pname)
        self.object:remove()
				return
      end
    end
  end

	if self.lastpos.x~=nil then
		if throwing_node_should_block_arrow(node.name) then
			local pname = self.player_name
			boom(self.lastpos, pname)
			self.object:remove()
			return
		end
	end

	self.lastpos={x=pos.x, y=pos.y, z=pos.z}
end

minetest.register_entity("throwing:arrow_tnt_entity", THROWING_ARROW_ENTITY)

minetest.register_craft({
	output = 'throwing:arrow_tnt 3',
	recipe = {
		{'default:stick', 'tnt:tnt', 'default:copper_ingot'},
	}
})

minetest.register_craft({
	output = 'throwing:arrow_tnt 3',
	recipe = {
		{'default:copper_ingot', 'tnt:tnt', 'default:stick'},
	}
})
