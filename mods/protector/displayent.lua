
-- Display entity shown when protector node is punched

if not protector.displayent_registered then
	protector.displayent_registered = true

	local ENTITY_GLOW = 14

	local versions = {
		{radius=protector.radius, node="protector:display_node", entity="protector:display"},
		{radius=protector.radius_small, node="protector:display_node_small", entity="protector:display_small"},
	}

	for _, v in ipairs(versions) do
		minetest.register_entity(v.entity, {
			physical = false,
			collisionbox = {0, 0, 0, 0, 0, 0},
			visual = "wielditem",
			-- wielditem seems to be scaled to 1.5 times original node size
			visual_size = {x = 1.0 / 1.5, y = 1.0 / 1.5},
			textures = {v.node},
			timer = 0,
			glow = ENTITY_GLOW,
			static_save = false,

			on_step = function(self, dtime)
				self.timer = self.timer + dtime
				if self.timer > protector.display_time then
					self.object:remove()
				end
			end,

			on_blast = function(self, damage)
				return false, false, {}
			end,
		})
	end

	local function get_nodebox(x)
		local w = 1/64 -- Tex width/height.
		local h = 0.5 - w*2 -- Wall thickness.
		return {
			-- sides
			{-(x+0.5+w), -(x+0.5+w), -(x+0.5+w), -(x+h  +w),  (x+0.5+w),  (x+0.5+w)},
			{-(x+0.5+w), -(x+0.5+w),  (x+h  +w),  (x+0.5+w),  (x+0.5+w),  (x+0.5+w)},
			{ (x+h  +w), -(x+0.5+w), -(x+0.5+w),  (x+0.5+w),  (x+0.5+w),  (x+0.5+w)},
			{-(x+0.5+w), -(x+0.5+w), -(x+0.5+w),  (x+0.5+w),  (x+0.5+w), -(x+h  +w)},
			-- top
			{-(x+0.5+w),  (x+h  +w), -(x+0.5+w),  (x+0.5+w),  (x+0.5+w),  (x+0.5+w)},
			-- bottom
			{-(x+0.5+w), -(x+0.5+w), -(x+0.5+w),  (x+0.5+w), -(x+h  +w),  (x+0.5+w)},
			-- middle (surround protector)
			{-(  0.5+w), -(  0.5+w), -(  0.5+w),  (  0.5+w),  (  0.5+w),  (  0.5+w)},
		}
	end

	for _, v in ipairs(versions) do
		-- Display-zone node, Do NOT place the display as a node,
		-- it is made to be used as an entity (see above)
		minetest.register_node(v.node, {
			tiles = {"protector_display.png"},
			use_texture_alpha = "blend",
			walkable = false,
			drawtype = "nodebox",
			node_box = {
				type = "fixed",
				fixed = get_nodebox(v.radius),
			},
			selection_box = {
				type = "regular",
			},
			paramtype = "light",
			groups = utility.dig_groups("item", {not_in_creative_inventory = 1}),
			drop = "",
		})
	end
end
