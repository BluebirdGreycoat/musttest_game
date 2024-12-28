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
	static_save = false,
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

local function explode_nearby(self, pos)
	local vel = self.object:get_velocity()
	local objs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, 2)

	for k, obj in pairs(objs) do
		if obj:get_luaentity() ~= nil then
			local oname = obj:get_luaentity().name
			if not throwing.entity_ignores_arrow(oname) then
				local speed = vector.length(vel)
				local damage = 1*500
				throwing_arrow_punch_entity(obj, self, damage)
				boom(pos, self.player_name)
			end
		elseif obj:is_player() then
			local speed = vector.length(vel)
			local damage = 1
			throwing_arrow_punch_entity(obj, self, damage)
			boom(pos, self.player_name)
		end
	end
end

function THROWING_ARROW_ENTITY.hit_player(self, obj, intersection_point)
	explode_nearby(self, intersection_point)
end

function THROWING_ARROW_ENTITY.hit_object(self, obj, intersection_point)
	explode_nearby(self, intersection_point)
end

function THROWING_ARROW_ENTITY.hit_node(self, under, above, intersection_point)
	local node = minetest.get_node(under)
	local ndef = minetest.registered_nodes[node.name]

	-- Call 'on_arrow_impact' if node defines it.
	if ndef.on_arrow_impact then
		ndef.on_arrow_impact(under, above, self.object, intersection_point)
	end

	boom(above, self.player_name)
end

THROWING_ARROW_ENTITY.on_step = function(self, dtime)
	throwing.do_fly(self, dtime)
end

minetest.register_entity("throwing:arrow_tnt_entity", THROWING_ARROW_ENTITY)

minetest.register_craft({
	output = 'throwing:arrow_tnt 3',
	recipe = {
		{'', 'tnt:tnt_stick', 'group:stick'},
		{'default:copper_ingot', 'tnt:tnt_stick', 'group:stick'},
		{'', 'tnt:tnt_stick', 'group:stick'},
	}
})
