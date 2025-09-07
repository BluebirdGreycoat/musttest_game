-- Staff of Abundance
local MAX_RANGE = 128

local function pluralize(count, singular, plural)
	if count == 1 then
		return singular
	end

	return plural
end

local function refresh_stacks(toinv, frominv)
	local tolist = toinv:get_list("main")
	local fromlist = frominv:get_list("main")
	local items_were_moved = false
	local num_stacks_refreshed = 0

	for _, tostack in ipairs(tolist) do
		for _, fromstack in ipairs(fromlist) do
			if tostack:get_name() == fromstack:get_name() then
				-- Exclude tools and tool-like items.
				if tostack:get_stack_max() > 1 then
					local tocountmax = tostack:get_stack_max()
					local tocount = tostack:get_count()
					local fromcount = fromstack:get_count()

					if tocount < tocountmax then
						local numwanted = tocountmax - tocount
						local numwanted = math.min(numwanted, fromcount)

						if numwanted > 0 then
							tostack:set_count(tocount + numwanted)
							fromstack:set_count(fromcount - numwanted)

							items_were_moved = true
							num_stacks_refreshed = num_stacks_refreshed + 1
						end
					end
				end
			end
		end
	end

	if items_were_moved then
		toinv:set_list("main", tolist)
		frominv:set_list("main", fromlist)
		return true, num_stacks_refreshed
	end
end

function stoneworld.oerkki_soa(itemstack, user, pt)
  if not user or not user:is_player() then return end

  local pname = user:get_player_name()
  local staffmeta = itemstack:get_meta()
  local node, nodepos, is_chest
  local chest_location = minetest.string_to_pos(staffmeta:get_string("chest_location"))
  local user_location = vector.round(user:get_pos())

  if pt.type == "node" then
		nodepos = pt.under
		node = minetest.get_node(pt.under)
	end

	if node and nodepos then
		if minetest.get_item_group(node.name, "chest_node") ~= 0 then
			is_chest = true
		end
	end

	if is_chest then
		local chest_owner = minetest.get_meta(nodepos):get_string("owner")
		if chest_owner == "" or chest_owner == pname then
			staffmeta:set_string("chest_location", minetest.pos_to_string(nodepos))
			minetest.chat_send_player(pname, "# Server: Chest coordinates secured.")
			return itemstack
		else
			-- However, if someone else initializes the staff and shares it with
			-- another player, they will still be able to teleport items.
			minetest.chat_send_player(pname, "# Server: This chest is locked!")
			return
		end
	end

	if chest_location and vector.distance(chest_location, user_location) < MAX_RANGE then
		local chest_inv = minetest.get_meta(chest_location):get_inventory()
		local user_inv = user:get_inventory()
		local success, numstacks = refresh_stacks(user_inv, chest_inv)
		if success then
			minetest.chat_send_player(pname, "# Server: " .. numstacks .. " " ..
				pluralize(numstacks, "stack", "stacks") .. " refreshed.")
		else
			minetest.chat_send_player(pname, "# Server: Nothing to do.")
		end
		return
	end

	minetest.chat_send_player(pname, "# Server: Nothing happens ...")
end

minetest.register_tool("stoneworld:oerkki_soa", {
	description = "Staff Of Abundance",
	inventory_image = "stoneworld_oerkki_staff.png",

	-- Tools with dual-use functions MUST put the secondary use in this callback,
	-- otherwise normal punches do not work!
	on_place = stoneworld.oerkki_soa,
	on_secondary_use = stoneworld.oerkki_soa,

  -- Using it on a live player? >:)
  -- Damage info is stored by sysdmg.
	tool_capabilities = {
    full_punch_interval = 3.0,
  },
})

-- Not craftable. Item is loot ONLY.
--------------------------------------------------------------------------------
