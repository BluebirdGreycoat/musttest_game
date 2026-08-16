
-- Display entity shown when protector node is punched

if not protector.displayent_registered then
	protector.displayent_registered = true

	minetest.register_entity("protector:display", {
		physical = false,
		collisionbox = {0, 0, 0, 0, 0, 0},
		visual = "wielditem",
		-- wielditem seems to be scaled to 1.5 times original node size
		visual_size = {x = 1.0 / 1.5, y = 1.0 / 1.5},
		textures = {"protector:display_node"},
		timer = 0,
		glow = 14,
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

	minetest.register_entity("protector:display_small", {
		physical = false,
		collisionbox = {0, 0, 0, 0, 0, 0},
		visual = "wielditem",
		-- wielditem seems to be scaled to 1.5 times original node size
		visual_size = {x = 1.0 / 1.5, y = 1.0 / 1.5},
		textures = {"protector:display_node_small"},
		timer = 0,
		glow = 14,
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

	-- Display-zone node, Do NOT place the display as a node,
	-- it is made to be used as an entity (see above)

	do
		local x = protector.radius
		minetest.register_node("protector:display_node", {
			tiles = {"protector_display.png"},
			use_texture_alpha = "blend",
			walkable = false,
			drawtype = "nodebox",
			node_box = {
				type = "fixed",
				fixed = {
					-- sides
					{-(x+.55), -(x+.55), -(x+.55), -(x+.45), (x+.55), (x+.55)},
					{-(x+.55), -(x+.55), (x+.45), (x+.55), (x+.55), (x+.55)},
					{(x+.45), -(x+.55), -(x+.55), (x+.55), (x+.55), (x+.55)},
					{-(x+.55), -(x+.55), -(x+.55), (x+.55), (x+.55), -(x+.45)},
					-- top
					{-(x+.55), (x+.45), -(x+.55), (x+.55), (x+.55), (x+.55)},
					-- bottom
					{-(x+.55), -(x+.55), -(x+.55), (x+.55), -(x+.45), (x+.55)},
					-- middle (surround protector)
					{-.55,-.55,-.55, .55,.55,.55},
				},
			},
			selection_box = {
				type = "regular",
			},
			paramtype = "light",
			groups = utility.dig_groups("item", {not_in_creative_inventory = 1}),
			drop = "",
		})
	end

	do
		local x = protector.radius_small
		minetest.register_node("protector:display_node_small", {
			tiles = {"protector_display.png"},
			use_texture_alpha = "blend",
			walkable = false,
			drawtype = "nodebox",
			node_box = {
				type = "fixed",
				fixed = {
					-- sides
					{-(x+.55), -(x+.55), -(x+.55), -(x+.45), (x+.55), (x+.55)},
					{-(x+.55), -(x+.55), (x+.45), (x+.55), (x+.55), (x+.55)},
					{(x+.45), -(x+.55), -(x+.55), (x+.55), (x+.55), (x+.55)},
					{-(x+.55), -(x+.55), -(x+.55), (x+.55), (x+.55), -(x+.45)},
					-- top
					{-(x+.55), (x+.45), -(x+.55), (x+.55), (x+.55), (x+.55)},
					-- bottom
					{-(x+.55), -(x+.55), -(x+.55), (x+.55), -(x+.45), (x+.55)},
					-- middle (surround protector)
					{-.55,-.55,-.55, .55,.55,.55},
				},
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
