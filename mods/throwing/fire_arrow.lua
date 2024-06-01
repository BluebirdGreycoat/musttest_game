
-- Localize for performance.
local math_floor = math.floor



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
	_name = "throwing:arrow_fire",
	physical = false,
	timer=0,
	visual = "wielditem",
	visual_size = {x=0.1, y=0.1},
	textures = {"throwing:arrow_fire_box"},
	lastpos={},
	collisionbox = {0,0,0,0,0,0},
	static_save = false,
}

function THROWING_ARROW_ENTITY.hit_player(self, obj, intersection_point)
	local damage = 4*500
	throwing_arrow_punch_entity(obj, self, damage)
	minetest.add_item(self.lastpos, 'default:stick')
end

function THROWING_ARROW_ENTITY.hit_object(self, obj, intersection_point)
	local damage = 4*500
	throwing_arrow_punch_entity(obj, self, damage)
	minetest.add_item(self.lastpos, 'default:stick')
end

function THROWING_ARROW_ENTITY.hit_node(self, under, above, intersection_point)
	local fpos = minetest.find_node_near(above, 1, {"air", "group:airlike"}, true)
	if fpos then
		local node = minetest.get_node(fpos)
		if minetest.get_item_group(node.name, "unbreakable") == 0 then
			minetest.add_node(fpos, {name="fire:basic_flame"})
		end
	end
	minetest.sound_play("throwing_shell_explode", {pos=above, gain=1.0, max_hear_distance=2*64}, true)
end

THROWING_ARROW_ENTITY.on_step = function(self, dtime)
	local pos = self.object:get_pos()

	-- Light up the air as it passes.
	if self.lastpos.x ~= nil then
		if math_floor(self.lastpos.x+0.5) ~= math_floor(pos.x+0.5) or
				math_floor(self.lastpos.y+0.5) ~= math_floor(pos.y+0.5) or
				math_floor(self.lastpos.z+0.5) ~= math_floor(pos.z+0.5) then
			if minetest.get_node(pos).name == "air" then
				minetest.set_node(pos, {name="throwing:light"})
			end
		end
	end

	throwing.do_fly(self, dtime)
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
		{'charcoal:charcoal', 'plastic:oil_extract', 'group:stick'},
	},
})

