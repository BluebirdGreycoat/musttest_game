
chest_api = chest_api or {}
chest_api.modpath = minetest.get_modpath("chest_api")

dofile(chest_api.modpath .. "/functions.lua")

if not chest_api.run_once then
	-- Guard against players leaving the game while a chest is open.
	minetest.register_on_leaveplayer(function(...)
		return chest_api.on_leaveplayer(...)
	end)

	-- Or if they die while holding a chest open.
	minetest.register_on_dieplayer(function(...)
		return chest_api.on_dieplayer(...)
	end)

	minetest.register_on_player_receive_fields(function(...)
		return chest_api.on_player_receive_fields(...)
	end)

	-- Chest registration function.
	function chest_api.register_chest(name, def)
		def.drawtype = "mesh"
		def.visual = "mesh"
		def.paramtype = "light"
		def.paramtype2 = "facedir"
		def.legacy_facedir_simple = true
		def.is_ground_content = false
		def._chest_basename = name

		def.groups = def.groups or {}
		-- Now that node metadata is preserved, we don't need this anymore.
		--def.groups.immovable = 1
		local protected = def.protected

		if def.protected then
			def.on_construct = function(...)
				return chest_api.protected_on_construct(...)
			end

			local original_after_place_node = def.after_place_node
			def.after_place_node = function(...)
				chest_api.protected_after_place_node(...)

				-- Allow registrations to include their own "after_place_node" functionality.
				if original_after_place_node then
					return original_after_place_node(...)
				end
			end

			def.can_dig = function(...)
				return chest_api.protected_can_dig(...)
			end

			def.allow_metadata_inventory_move = function(...)
				return chest_api.protected_allow_metadata_inventory_move(...)
			end

			def.allow_metadata_inventory_put = function(...)
				return chest_api.protected_allow_metadata_inventory_put(...)
			end

			def.allow_metadata_inventory_take = function(...)
				return chest_api.protected_allow_metadata_inventory_take(...)
			end

			def.on_rightclick = function(...)
				return chest_api.protected_on_rightclick(...)
			end

			-- Another way to open a locked chest.
			def.on_key_use = function(...)
				return chest_api.protected_on_key_use(...)
			end

			def.on_skeleton_key_use = function(...)
				return chest_api.protected_on_skeleton_key_use(...)
			end

			-- Called by rename LBM.
			def._on_rename_check = function(...)
				return chest_api.protected_on_rename_check(...)
			end
		else
			def.on_construct = function(...)
				return chest_api.public_on_construct(...)
			end

			def.can_dig = function(...)
				return chest_api.public_can_dig(...)
			end

			def.on_rightclick = function(...)
				return chest_api.public_on_rightclick(...)
			end
		end

		def.on_receive_fields = function(...)
			return chest_api.on_receive_fields(...)
		end

		def.on_metadata_inventory_move = function(...)
			return chest_api.on_metadata_inventory_move(...)
		end

		def.on_metadata_inventory_put = function(...)
			return chest_api.on_metadata_inventory_put(...)
		end

		def.on_metadata_inventory_take = function(...)
			return chest_api.on_metadata_inventory_take(...)
		end

		def.on_blast = function(...)
			return chest_api.on_blast(...)
		end

		local def_opened = table.copy(def)
		local def_closed = table.copy(def)

		def_opened.mesh = "chest_open.obj"
		def_opened.drop = name .. "_closed"
		def_opened.groups.not_in_creative_inventory = 1
		def_opened.groups.chest_opened = 1
		def_opened.selection_box = {
			type = "fixed",
			fixed = { -1/2, -1/2, -1/2, 1/2, 3/16, 1/2 },
			}

		-- Chests are not diggable while opened.
		def_opened.can_dig = function()
			return false
		end

		def_closed.mesh = "chest_close.obj"
		def_closed.groups.chest_closed = 1

		minetest.register_node(name .. "_closed", def_closed)
		minetest.register_node(name .. "_open", def_opened)
	end

	local c = "chest_api:core"
	local f = chest_api.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	chest_api.run_once = true
end
