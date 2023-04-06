
if not minetest.global_exists("itemburn") then itemburn = {} end
itemburn.modpath = minetest.get_modpath("itemburn")

-- Localize for performance.
local vector_round = vector.round
local math_random = math.random
local math_min = math.min



-- Use an offset for finding the node under the drop,
-- to allow thin slab shielding for lava, etc.
itemburn.footstep=-0.25
function itemburn.get_fs()
	return itemburn.footstep
end



-- mods/default/item_entity.lua

local builtin_item = minetest.registered_entities["__builtin:item"]

local item = {
	set_item = function(self, itemstring)
		builtin_item.set_item(self, itemstring)

		local stack = ItemStack(itemstring)
		local itemdef = minetest.registered_items[stack:get_name()]
		if itemdef and itemdef.groups.flammable ~= 0 then
			self.flammable = itemdef.groups.flammable
		end
	end,

	burn_up = function(self, lava)
		-- disappear in a smoke puff
		self.itemstring = ""

		local p = self.object:get_pos()
		minetest.sound_play("default_item_smoke", {
			pos = p,
			max_hear_distance = 8,
		}, true)
		minetest.add_particlespawner({
			amount = 3,
			time = 0.1,
			minpos = {x = p.x - 0.1, y = p.y + 0.1, z = p.z - 0.1 },
			maxpos = {x = p.x + 0.1, y = p.y + 0.2, z = p.z + 0.1 },
			minvel = {x = 0, y = 2.5, z = 0},
			maxvel = {x = 0, y = 2.5, z = 0},
			minacc = {x = -0.15, y = -0.02, z = -0.15},
			maxacc = {x = 0.15, y = -0.01, z = 0.15},
			minexptime = 4,
			maxexptime = 6,
			minsize = 5,
			maxsize = 5,
			collisiondetection = true,
			texture = "default_item_smoke.png"
		})
		if lava then
			local node = minetest.get_node(p)
			lava_extras.spawn_particles(p, node)
		end

		self.object:remove()
	end,

	melt_in_lava = function(self, lpos)
		local p = self.object:get_pos()
		ambiance.sound_play("default_cool_lava", p, 2.0, 16)

		self.itemstring = ""
		self.object:remove()

		local node = minetest.get_node(lpos)
		lava_extras.spawn_particles(lpos, node)
	end,

	on_step = function(self, dtime, moveresult)
		builtin_item.on_step(self, dtime, moveresult)

		local is_falling = false
		local vel = self.object:get_velocity()

		-- Fix spurious error.
		-- Note: documentation explains this is caused by :remove() being called
		-- inside the original on_step() function; see just a few lines above, where
		-- it gets called.
		if not vel then
			return
		end

		if vel.y < -0.1 then
			is_falling = true
			self.need_lava_check = true
			--minetest.chat_send_all("# Server: Falling!")
		end

		if not is_falling and self.need_lava_check then
			--minetest.chat_send_all("# Server: Lava check!")
			local pos = self.object:get_pos()
			local node = minetest.get_node(pos)
			--minetest.chat_send_all("# Server: A=" .. node.name)
			if string.find(node.name, ":lava_") then
				self:melt_in_lava(vector_round(pos))
				return
			else
				local pb = vector_round({x=pos.x, y=pos.y+itemburn.get_fs(), z=pos.z})
				local node = minetest.get_node(pb)
				--minetest.chat_send_all("# Server: U=" .. node.name)
				if string.find(node.name, ":lava_") then
					self:melt_in_lava(pb)
					return
				end
			end
			self.need_lava_check = false
		end

		-- flammable, check for igniters
		self.ignite_timer = (self.ignite_timer or 0) - dtime
		if self.ignite_timer < 0 then
			self.ignite_timer = math_random(10, 100)/10

			local pos = self.object:get_pos()
			local node = minetest.get_node_or_nil(pos)
			if not node then
				return
			end

			-- Immediately burn up flammable items in lava
			if minetest.get_item_group(node.name, "lava") > 0 then
				self:melt_in_lava(vector_round(pos))
			else
				-- Check if sitting on top of lava.
				local pb = vector_round({x=pos.x, y=pos.y+itemburn.get_fs(), z=pos.z})
				local nb = minetest.get_node_or_nil(pb)
				if nb then
					local l = minetest.get_item_group(nb.name, "lava")
					if l > 0 then
						self:melt_in_lava(pb)
						return
					end
				end

				--  otherwise there'll be a chance based on its igniter value
				local burn_chance = (self.flammable or 1) * minetest.get_item_group(node.name, "igniter")
				if burn_chance > 0 and math_random(0, burn_chance) ~= 0 then
					self:burn_up()
				end
			end
		end
	end,

	on_punch = function(self, hitter)
		local inv = hitter:get_inventory()
		if not inv then
			return
		end

		-- Do not allow pickup of items inside fire.
		do
			local nn = minetest.get_node(vector.round(self.object:get_pos())).name
			if minetest.get_item_group(nn, "fire") ~= 0 then
				return
			end
		end

		local clear = true

		if self.itemstring ~= "" then
			local stack = ItemStack(self.itemstring)
			local name = stack:get_name()
			local count = stack:get_count()

			local left
			local index
			local inserted = false
			local newstack

			for i=1, inv:get_size("main"), 1 do
				local s2 = inv:get_stack("main", i)
				local n2 = s2:get_name()
				local empty = s2:is_empty()
				if name == n2 or empty then
					if empty then
						local s3 = stack:take_item(math_min(stack:get_count(), stack:get_stack_max()))
						left = stack
						index = i
						inv:set_stack("main", i, s3)
						newstack = ItemStack(s3) -- A copy of the stack being added.
						inserted = true
						break
					elseif name == n2 and s2:get_free_space() > 0 then
						newstack = ItemStack(stack):take_item(math_min(s2:get_free_space(), stack:get_count())) -- A copy of the stack being added.
						left = s2:add_item(stack)
						index = i
						inv:set_stack("main", i, s2)
						inserted = true
						break
					end
				end
			end

			-- If something was added to the inv, we update the entity, but do not clear it.
			if left and not left:is_empty() then
				count = count - left:get_count()
				self:set_item(left)
				clear = false
			end

			-- If nothing was added to the inventory, we cannot remove the entity.
			if not inserted then
				clear = false
			end

			if inserted then
				minetest.log("action", hitter:get_player_name() .. " picks item-entity " ..
					stack:get_name() .. " " .. count .. " at " .. minetest.pos_to_string(vector_round(self.object:get_pos())))

				-- Execute player inventory callbacks.
				-- Note: inventory callbacks are called when player drops item (Q) so this
				-- implements the reciprocal.
				for _, func in ipairs(core.registered_on_player_inventory_actions) do
					func(hitter, "put", inv, {listname="main", index=index, stack=newstack})
				end
			end
		end

		if clear then
			self.itemstring = ""
			self.object:remove()
		end
	end,
}

-- set defined item as new __builtin:item, with the old one as fallback table
setmetatable(item, builtin_item)
minetest.register_entity(":__builtin:item", item)


