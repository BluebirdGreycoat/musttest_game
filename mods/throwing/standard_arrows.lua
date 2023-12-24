
-- Localize for performance.
local math_random = math.random



function throwing_register_arrow_standard (kind, desc, eq, toughness, craft, craftcount)
	minetest.register_craftitem("throwing:arrow_" .. kind, {
		description = desc .. " Arrow",
		inventory_image = "throwing_arrow_" .. kind .. ".png",
	})
	
	minetest.register_node("throwing:arrow_" .. kind .. "_box", {
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
		tiles = {"throwing_arrow_" .. kind .. ".png", "throwing_arrow_" .. kind .. ".png", "throwing_arrow_" .. kind .. "_back.png", "throwing_arrow_" .. kind .. "_front.png", "throwing_arrow_" .. kind .. "_2.png", "throwing_arrow_" .. kind .. ".png"},
		groups = {not_in_creative_inventory=1},
	})
	
	local THROWING_ARROW_ENTITY = {
		_name = "throwing:arrow_" .. kind,
		physical = false,
		timer=0,
		visual = "wielditem",
		visual_size = {x=0.1, y=0.1},
		textures = {"throwing:arrow_" .. kind .. "_box"},
		lastpos={},
		collisionbox = {0,0,0,0,0,0},
		static_save = false,
	}
	
	function THROWING_ARROW_ENTITY.hit_player(self, obj, intersection_point)
		local vel = self.object:get_velocity()
		local speed = vector.length(vel) / 2
		local damage = ((speed + eq)^1.2)/5
		throwing_arrow_punch_entity(obj, self, damage*500)
	end

	function THROWING_ARROW_ENTITY.hit_object(self, obj, intersection_point)
		local vel = self.object:get_velocity()
		local speed = vector.length(vel) / 2
		local damage = ((speed + eq)^1.2)/5

		local luaent = obj:get_luaentity()
		if luaent and (luaent.mob or luaent._cmi_is_mob) then
			if luaent.add_item_drop then
				--minetest.chat_send_all('adding!')
				luaent:add_item_drop("throwing:arrow_" .. kind)
			end
		end

		throwing_arrow_punch_entity(obj, self, damage*500)
		ambiance.sound_play("throwing_arrow_hit", obj:get_pos(), 1.0, 32)
	end

	function THROWING_ARROW_ENTITY.hit_node(self, under, above, intersection_point)
		if math_random() < toughness then
			local ent = minetest.add_item(above, 'throwing:arrow_' .. kind)
			if ent then
				local luaent = ent:get_luaentity()
				if not luaent then
					ent:remove()
					return
				end

				local liquid = false
				local node = minetest.get_node(under)
				local ndef = minetest.registered_nodes[node.name]
				if ndef.liquidtype ~= "none" then
					liquid = true
				end

				if intersection_point then
					ent:set_pos(intersection_point)
					ent:set_velocity({x=0, y=0, z=0})

					if not liquid then
						-- I wish the API used quaternions. :(
						local op = self.lastpos
						local v = vector.normalize(vector.subtract(intersection_point, op))
						local O = vector.length({x=v.x, y=0, z=v.z})
						local A = v.y
						local pitch = 0
						if math.abs(O) > 0 then
							pitch = math.atan(A/O)
						end

						ent:set_properties({
							automatic_rotate = 0,
							physical = true,
							collide_with_objects = true,
							collisionbox = {-0.2, -0.2, -0.2, 0.2, 0.2, 0.2},
						})

						ent:set_rotation({x=0, y=self.object:get_yaw(), z=pitch})
						ent:set_acceleration({x=0, y=0, z=0})

						luaent.stuck_arrow = true
					end
				end
			end
		else
			minetest.add_item(above, 'default:stick')
		end
		ambiance.sound_play("throwing_arrow_hit", under, 1.0, 32)
	end

	THROWING_ARROW_ENTITY.on_step = function(self, dtime)
		throwing.do_fly(self, dtime)
	end
	
	minetest.register_entity("throwing:arrow_" .. kind .. "_entity", THROWING_ARROW_ENTITY)
	
	if craftcount == 1 then
		minetest.register_craft({
			output = 'throwing:arrow_' .. kind .. ' ' .. craftcount,
			recipe = {
				{craft, 'default:stick', 'default:stick'},
			}
		})
	elseif craftcount == 3 then
		minetest.register_craft({
			output = 'throwing:arrow_' .. kind .. ' ' .. craftcount,
			recipe = {
				{'', 'default:stick', 'default:stick'},
				{craft, 'default:stick', 'default:stick'},
				{'', 'default:stick', 'default:stick'},
			}
		})
	end
end

throwing_register_arrow_standard ('stone', 'Stone', 5, 0.88, 'default:cobble', 3)
throwing_register_arrow_standard ('steel', 'Steel', 15, 0.94, 'default:steel_ingot', 3)
throwing_register_arrow_standard ('diamond', 'Diamond', 25, 0.97, 'dusts:diamond_shard', 1)
throwing_register_arrow_standard ('obsidian', 'Obsidian', 20, 0.88, 'default:obsidian_shard', 1)
throwing_register_arrow_standard ('mese', 'Mese', 17, 0.90, 'default:mese_crystal_fragment', 1)
