
if not minetest.global_exists("wizard") then wizard = {} end
wizard.modpath = minetest.get_modpath("wizard")



function wizard.on_construct(pos)
end



function wizard.on_destruct(pos)
end



function wizard.on_pre_fall(pos)
end



function wizard.on_blast(pos)
end



function wizard.on_collapse_to_entity(pos, node)
end



function wizard.on_finish_collapse(pos, node)
end



function wizard.on_rightclick(pos, node, user, itemstack, pt)
end



function wizard.allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, user)
end



function wizard.on_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, user)
end



function wizard.allow_metadata_inventory_put(pos, listname, index, stack, user)
end



function wizard.on_metadata_inventory_put(pos, listname, index, stack, user)
end



function wizard.allow_metadata_inventory_take(pos, listname, index, stack, user)
end



function wizard.on_metadata_inventory_take(pos, listname, index, stack, user)
end



function wizard.after_place_node(pos, user, itemstack, pt)
	--[[
	if not user or not user:is_player() then
		return
	end

	local pname = user:get_player_name()
	if not gdac.player_is_admin(pname) then
		return
	end

	local meta = minetest.get_meta(pos)
	meta:set_int("down", 50)
	meta:set_int("up", 350)
	meta:mark_as_private({"down", "up"})

	local timer = minetest.get_node_timer(pos)
	timer:start(1)
	--]]
end



function wizard.on_punch(pos, node, user, pt)
end



function wizard.on_timer(pos, elapsed)
	--[[
	local meta = minetest.get_meta(pos)
	local under = vector.add(pos, {x=0, y=-1, z=0})
	local above = vector.add(pos, {x=0, y=1, z=0})

	local nodeunder = minetest.get_node(under)
	local nodeabove = minetest.get_node(above)

	if nodeunder.name == "ignore" or nodeabove.name == "ignore" then
		return true
	end

	if nodeunder.name ~= "air" and meta:get_int("down") > 0 then
		if nodeunder.name ~= "wizard:stone" then
			minetest.set_node(under, {name="wizard:stone"})
			local nmeta = minetest.get_meta(under)
			nmeta:set_int("down", meta:get_int("down") - 1)
			nmeta:mark_as_private("down")
			meta:set_string("down", "")
			local ntimer = minetest.get_node_timer(under)
			ntimer:start(1)
		end
	else
		meta:set_string("down", "")
	end

	if meta:get_int("up") > 0 then
		if nodeabove.name ~= "wizard:stone" then
			minetest.set_node(above, {name="wizard:stone"})
			local nmeta = minetest.get_meta(above)
			nmeta:set_int("up", meta:get_int("up") - 1)
			nmeta:mark_as_private("up")
			meta:set_string("up", "")
			local ntimer = minetest.get_node_timer(above)
			ntimer:start(1)
		end
	else
		meta:set_string("up", "")
	end
	--]]
end



function wizard.can_dig(pos, user)
end



function wizard.on_rotate(pos, node, user, mode, new_param2)
end



function wizard.banish_staff(itemstack, user, pt)
  if not user or not user:is_player() then
		return
	end

	if pt.type ~= "node" then
		return
	end

	local node = minetest.get_node(pt.under)
	local nodename = node.name

	-- Must be a rune slab.
	if nodename ~= "signs:sign_wall_stone" then
		return
	end

	local pname = user:get_player_name()
	local meta = minetest.get_meta(pt.under)
	local text = meta:get_string("text"):trim()
	local author = meta:get_string("author")

	local tokens = text:split(":")
	if #tokens == 0 or #tokens > 2 then
		return
	end

	local target_name = (tokens[2] or tokens[1]):trim()

	-- Staff user must be sign author.
	if author ~= pname then
		return
	end

	local ptarget = minetest.get_player_by_name(target_name)
	if not ptarget or not ptarget:is_player() then
		return
	end

	-- 10% for the Big Guy.
	if minetest.check_player_privs(ptarget, {server=true}) then
		local pos = user:get_pos()
		minetest.after(0, function()
			tnt.boom(pos, {
				radius = 5,
				ignore_protection = false,
				ignore_on_blast = false,
				damage_radius = 5,
				disable_drops = true,
			})
		end)

		itemstack:take_item()
		return itemstack
	end

	-- Staff user can specify an origin other than himself.
	-- The wizard may use a minion to extend his power.
	local origin = user:get_pos()
	if tokens[1] and tokens[2] then
		local origin_name = tokens[1]:trim()
		if origin_name ~= target_name then
			local origin_ref = minetest.get_player_by_name(origin_name)
			if origin_ref then
				origin = origin_ref:get_pos()
			end
		end
	end

	-- Range limit.
	if vector.distance(origin, ptarget:get_pos()) > 100 then
		return
	end

	-- Perform kick action AFTER returning from the current stack frame.
	-- User might kick self.
	local ntarget = ptarget:get_player_name()
	minetest.after(0, function()
		minetest.kick_player(ntarget, "Momentarily banished.")
	end)

	-- Take 15 hp of health from the wizard.
	minetest.after(0, function()
		local pref = minetest.get_player_by_name(pname)
		if pref then
			utility.damage_player(pref, "fleshy", 15 * 500)
		end
	end)
end



if not wizard.registered then
	wizard.registered = true

	minetest.register_node("wizard:stone", {
		description = "Wizard Stone (You Hacker)",
		tiles = {"default_obsidian.png"},
		on_rotate = function(...) return wizard.on_rotate(...) end,

		groups = utility.dig_groups("obsidian", {stone=1, immovable=1}),
		drop = "",
		sounds = default.node_sound_stone_defaults(),
		crushing_damage = 20*500,
		node_dig_prediction = "",

		on_construct = function(...) return wizard.on_construct(...) end,
		on_destruct = function(...) return wizard.on_destruct(...) end,
		on_blast = function(...) return wizard.on_blast(...) end,
		on_collapse_to_entity = function(...) return wizard.on_collapse_to_entity(...) end,
		on_finish_collapse = function(...) return wizard.on_finish_collapse(...) end,
		on_rightclick = function(...) return wizard.on_rightclick(...) end,
		allow_metadata_inventory_move = function(...) return wizard.allow_metadata_inventory_move(...) end,
		allow_metadata_inventory_put = function(...) return wizard.allow_metadata_inventory_put(...) end,
		allow_metadata_inventory_take = function(...) return wizard.allow_metadata_inventory_take(...) end,
		on_metadata_inventory_move = function(...) return wizard.on_metadata_inventory_move(...) end,
		on_metadata_inventory_put = function(...) return wizard.on_metadata_inventory_put(...) end,
		on_metadata_inventory_take = function(...) return wizard.on_metadata_inventory_take(...) end,
		after_place_node = function(...) return wizard.after_place_node(...) end,
		on_punch = function(...) return wizard.on_punch(...) end,
		on_timer = function(...) return wizard.on_timer(...) end,
		can_dig = function(...) return wizard.can_dig(...) end,
		_on_update_infotext = function(...) return wizard.update_infotext(...) end,
		_on_update_formspec = function(...) return wizard.update_formspec(...) end,
		_on_update_entity = function(...) return wizard.update_entity(...) end,
		_on_pre_fall = function(...) return wizard.on_pre_fall(...) end,
	})

	minetest.register_tool("wizard:banish_staff", {
		description = "Banishing Staff",
		inventory_image = "stoneworld_oerkki_staff.png",

		-- Tools with dual-use functions MUST put the secondary use in this callback,
		-- otherwise normal punches do not work!
		on_place = function(...) return wizard.banish_staff(...) end,
		on_secondary_use = function(...) return wizard.banish_staff(...) end,

		-- Damage info is stored by sysdmg.
		tool_capabilities = {
			full_punch_interval = 3.0,
		},

		groups = {not_repaired_by_anvil = 1, disable_repair = 1},
	})

	-- Register mod reloadable.
	local c = "wizard:core"
	local f = wizard.modpath .. "/init.lua"
	reload.register_file(c, f, false)
end
