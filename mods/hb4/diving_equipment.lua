
diving_equipment = diving_equipment or {}
diving_equipment.modpath = minetest.get_modpath("hb4")
diving_equipment.airtime = 60
diving_equipment.steptime = 5
diving_equipment.players = diving_equipment.players or {}

-- Localize for performance.
local math_floor = math.floor

-- Must return true if player is wearing the diving helmet.
function diving_equipment.have_equipment(pref)
	local inv = pref:get_inventory()
	if not inv then return end
	local have_equipment = false

	-- Make sure player isn't trying to cheat by wearing multiple helmets.
	for i=1, 6 do
		local stackname = inv:get_stack("armor", i):get_name()
		if string.find(stackname, "^3d_armor:helmet_") then
			if stackname == "3d_armor:helmet_scuba" then
				have_equipment = true
			else
				return false
			end
		end
	end

	return have_equipment
end

function diving_equipment.replenish_air(pname, time)
	local player = minetest.get_player_by_name(pname)
	if not player then
		-- We cannot give player their bottle back.
		diving_equipment.players[pname] = nil
		return
	end -- Player left game.

	if time < 0 then
		-- Add empty iron bottle back to player's inventory.
		local leftover = player:get_inventory():add_item("main", ItemStack("vessels:steel_bottle"))
		minetest.add_item(player:get_pos(), leftover)
		diving_equipment.players[pname] = nil
		ambiance.sound_play("default_dug_metal", player:get_pos(), 1.0, 20)
		minetest.chat_send_player(pname, "# Server: Air canister is empty!")
		return
	end -- Air ran out.

	if not diving_equipment.have_equipment(player) then
		-- Add empty iron bottle back to player's inventory.
		local leftover = player:get_inventory():add_item("main", ItemStack("vessels:steel_bottle"))
		minetest.add_item(player:get_pos(), leftover)
		diving_equipment.players[pname] = nil
		ambiance.sound_play("default_dug_metal", player:get_pos(), 1.0, 20)
		minetest.chat_send_player(pname, "# Server: Diving helmet is not worn!")
		return
	end -- Lost diving helmet.

	-- Play breath sound on initial breath from new canister.
	if time == diving_equipment.airtime then
		ambiance.sound_play("drowning_gasp", player:get_pos(), 1.0, 20)
	end

	player:set_breath(11)

	minetest.after(diving_equipment.steptime, diving_equipment.replenish_air,
		pname, (time - diving_equipment.steptime))
end

function diving_equipment.on_use(itemstack, user, pt)
	if not user or not user:is_player() then return end
	local pname = user:get_player_name()

	if not diving_equipment.have_equipment(user) then
		minetest.chat_send_player(pname, "# Server: You must be wearing a diving helmet!")
		return
	end -- No diving helmet is worn.

	if diving_equipment.players[pname] then
		minetest.chat_send_player(pname, "# Server: An air canister is already attached!")
		return
	end -- Canister already installed.
	diving_equipment.players[pname] = true

	minetest.after(diving_equipment.steptime, diving_equipment.replenish_air,
		pname, diving_equipment.airtime)

	minetest.chat_send_player(pname, "# Server: Air canister attached; you have " .. math_floor(diving_equipment.airtime) .. " seconds of air.")
	ambiance.sound_play("default_place_node_metal", user:get_pos(), 1.0, 20)

	-- An empty bottle will be added back when used up.
	itemstack:take_item()
	return itemstack
end

function diving_equipment.on_place(itemstack, placer, pt)
	-- Pass through interactions to nodes that define them (like chests).
	-- This also fixes a bug where player can get unlimited steel bottles (and
	-- thus steel ingots) by putting compressed air into item frames.
	if pt.type == "node" then
		local under = minetest.get_node(pt.under)
		local nn = under.name
		local def = minetest.reg_ns_nodes[nn] or minetest.registered_nodes[nn]
    if def and def.on_rightclick then
      return def.on_rightclick(pt.under, under, placer, itemstack, pt)
    end
  end

	local fakestack = ItemStack("vessels:steel_bottle")
	local retstack, success, position = minetest.item_place(fakestack, placer, pt)

	if success and position then
		local meta = minetest.get_meta(position)
		meta:set_string("infotext", "Compressed Air Canister")
		meta:set_string("nodetype_on_dig", "scuba:air")
		meta:mark_as_private("nodetype_on_dig")
		coresounds.play_sound_node_place(pt.above, "vessels:steel_bottle")
		itemstack:take_item()
	end

	return itemstack
end

if not diving_equipment.registered then
	minetest.register_craftitem(":scuba:air", {
		description = "Compressed Air Canister\n\nUse with a diving helmet.\nLets you stay underwater.",
		inventory_image = "musttest_compressed_air.png",
		on_use = function(...)
			return diving_equipment.on_use(...)
		end,
		on_place = function(...)
			return diving_equipment.on_place(...)
		end,
	})

	-- The diving mask.
  minetest.register_tool(":3d_armor:helmet_scuba", {
    description = "Ocean Diving Helmet\n\nUse with compressed air.\nLets you stay underwater.",
    inventory_image = "3d_armor_inv_helmet_scuba.png",
    groups = {armor_head=1, armor_heal=0, armor_use=2000},
    wear = 0,
  })

  minetest.register_craft({
    output = "3d_armor:helmet_scuba",
    recipe = {
      {"default:steel_ingot", "plastic:plastic_sheeting", "default:steel_ingot"},
      {"default:steel_ingot", "default:glass", "default:steel_ingot"},
      {"farming:cloth", "vessels:steel_bottle", "farming:cloth"},
    },
  })

	minetest.register_craft({
		type = "compressing",
		output = "scuba:air",
		recipe = 'vessels:steel_bottle',
		time = 6,
	})

	diving_equipment.registered = true
end
