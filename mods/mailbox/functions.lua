
mailbox.get_owner_formspec = 
function(pos)
  local spos = pos.x .. "," .. pos.y .. "," .. pos.z
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	local reject = meta:get_string("reject")

	-- Fallback in case value not defined.
	if reject ~= "false" and reject ~= "true" then
		reject = "false"
	end

  local formspec = "size[8,8.5]" ..
    default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots ..
    "label[0,0;" .. minetest.formspec_escape("<" .. owner .. ">'s Mailbox") .. "]" ..
    "list[nodemeta:" .. spos .. ";main;0,0.5;8,1;]" ..
    
    "label[6,1.75;Upgrades]" ..
    "list[nodemeta:" .. spos .. ";cfg;6,2.25;2,1;]" ..
    
    "button[0,1.75;2,1;get;Get Mail]" ..
		"item_image[2,1.65;1,1;mailbox:mailbox]" ..
		"checkbox[0,2.55;reject;Reject Noob Items;" .. reject .. "]" ..
    
    "list[current_player;main;0,4.25;8,1;]" ..
    "list[current_player;main;0,5.5;8,3;8]" ..
    
    "listring[nodemeta:" .. spos .. ";main]"..
    "listring[current_player;main]"..
    default.get_hotbar_bg(0, 4.25)
        
  return formspec
end



mailbox.on_receive_fields = 
function(player, formname, fields)
  if string.find(formname, "^mailbox:mailbox_owner:") then
    local key = string.sub(formname, string.len("mailbox:mailbox_owner:") + 1)
    local pos = minetest.string_to_pos(key)
    if pos then
      local pname = player:get_player_name()
      local meta = minetest.get_meta(pos)
      local owner = meta:get_string('owner')
      if pname == owner or gdac.player_is_admin(pname) then

        if fields.get then
          local minv = meta:get_inventory()
          local pinv = player:get_inventory()
          for i = 1, minv:get_size('main'), 1 do
            local stack = minv:get_stack('main', i)
            if pinv:room_for_item('main', stack) then
              pinv:add_item('main', stack)
              minv:set_stack('main', i, ItemStack(nil))
            end
          end
        end

				if fields.reject and type(fields.reject) == "string" then
					--minetest.chat_send_player("MustTest", fields.reject)
					local reject = fields.reject
					if reject == "false" or reject == "true" then
						meta:set_string("reject", fields.reject)
					else
						meta:set_string("reject", "false")
					end
				end

      end
    end
    return true
  end
end



mailbox.get_insert_formspec = 
function(pos)
  local meta = minetest.get_meta(pos)
  local owner = meta:get_string('owner')
  local spos = pos.x .. "," .. pos.y .. "," ..pos.z
  
  local title = "Mailbox (Owned by <" .. owner .. ">!)"
    
  local formspec = "size[8,7.5]" ..
    default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots ..
    "label[0,0;" .. minetest.formspec_escape(title) .. "]" ..
    
    "label[3.5,1;Drop Slot]" ..
    "list[nodemeta:" .. spos .. ";drop;3.5,1.5;1,1;]" ..
    
    "list[current_player;main;0,3.25;8,1;]" ..
    "list[current_player;main;0,4.5;8,3;8]" ..
    
    "listring[nodemeta:" .. spos .. ";drop]"..
    "listring[current_player;main]"..
    default.get_hotbar_bg(0, 3.25)
        
  return formspec
end



mailbox.on_punch = 
function(pos, node, puncher, pointed_thing)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  
  inv:set_size('cfg', 2)
  
  -- Update infotext to new format.
  local owner = meta:get_string("owner") or ""
  meta:set_string("infotext", "Mailbox (Owned by <" .. owner .. ">!)")
end



mailbox.after_place_node = 
function(pos, placer, itemstack)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local owner = placer:get_player_name()
	local dname = rename.gpn(owner)
  
  meta:set_string("owner", owner)
	meta:set_string("rename", dname)
  meta:set_string("infotext", "Mailbox (Owned by <" .. dname .. ">!)")
  
  inv:set_size("main", 8)
  inv:set_size("drop", 1)
  inv:set_size("cfg", 2)
end



mailbox.on_destruct = 
function(pos)
	-- Nothing here ATM.
end



mailbox.on_blast =
function(pos, intensity)
  -- Unblastable.
end



mailbox.on_rightclick = 
function(pos, node, clicker, itemstack)
  local meta    = minetest.get_meta(pos)
  local pname   = clicker:get_player_name()
  local owner   = meta:get_string("owner")
  local meta    = minetest.get_meta(pos)
  
  if owner == pname then
    local formspec = mailbox.get_owner_formspec(pos)
    local spos = minetest.pos_to_string(pos)
    minetest.show_formspec(pname, "mailbox:mailbox_owner:" .. spos, formspec)
	elseif gdac.player_is_admin(pname) and clicker:get_player_control().aux1 then
		minetest.chat_send_player(pname, "# Server: You are viewing <" .. rename.gpn(owner) .. ">'s mailbox.")
    local formspec = mailbox.get_owner_formspec(pos)
    local spos = minetest.pos_to_string(pos)
    minetest.show_formspec(pname, "mailbox:mailbox_owner:" .. spos, formspec)
  else
    local formspec = mailbox.get_insert_formspec(pos)
    minetest.show_formspec(pname, "mailbox:mailbox_insert", formspec)
  end
  
  return itemstack
end



mailbox.can_dig = 
function(pos, player)
  local meta = minetest.get_meta(pos);
  local pname = player:get_player_name()
  local owner = meta:get_string("owner")
  local inv = meta:get_inventory()
  return pname == owner and
    inv:is_empty("main") and
    inv:is_empty("cfg")
end



mailbox.on_metadata_inventory_put = 
function(pos, listname, index, stack, player)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  if listname == "drop" and inv:room_for_item("main", stack) then
    inv:remove_item("drop", stack)
    inv:add_item("main", stack)

		local desc = "Unknown Item(s)"
		local def = minetest.registered_items[stack:get_name()]
		if def and def.description then
			desc = utility.get_short_desc(def.description)
		end

		local ownername = rename.gpn(meta:get_string("owner"))

		minetest.chat_send_player(player:get_player_name(),
			string.format("# Server: You put %d '%s' in <%s>'s mailbox.",
			stack:get_count(), desc, ownername))
  end
end



mailbox.allow_metadata_inventory_put = 
function(pos, listname, index, stack, player)
  local pname = player:get_player_name()
  if listname == "drop" then
    local meta = minetest.get_meta(pos)
    local owner = meta:get_string('owner')
    if owner == pname then return 0 end -- No cheating!

		local reject = meta:get_string("reject")
		if reject == "true" then
			for k, v in pairs(give_initial_stuff.items) do
				if stack:get_name() == v:get_name() then
					minetest.chat_send_player(pname, "# Server: This mail box does not accept starting items, sorry!")
					return 0
				end
			end
			for k, v in ipairs(mailbox.reject_items) do
				if stack:get_name() == ItemStack(v):get_name() then
					minetest.chat_send_player(pname, "# Server: This mail box does not accept noob items, sorry!")
					return 0
				end
			end
		end

    local inv = meta:get_inventory()
    if inv:room_for_item("main", stack) then
      local have_clu = false
      local cfg = inv:get_list('cfg')
      if cfg then -- Inventory may not exist for old mailboxes.
        for k, v in ipairs(cfg) do
          if v:get_name() == "techcrafts:control_logic_unit" and v:get_count() == 1 then
            have_clu = true
            break
          end
        end
      else
        inv:set_size('cfg', 2)
      end
      if have_clu then
        local desc = "Unknown Item(s)"
        local def = minetest.registered_items[stack:get_name()]
        if def and def.description then
          desc = utility.get_short_desc(def.description)
        end
        local from = "SERVER"
        local to = owner
        local subject = "Mailbox Delivery"
        local message = "Player <" .. rename.gpn(pname) .. "> put " ..
          stack:get_count() ..
          " '" .. desc .. "' in your mailbox @ " ..
          rc.pos_to_namestr(pos) .. "!"
        email.send_mail_single(from, to, subject, message)
      end
      return -1
    else
      minetest.chat_send_player(pname, "# Server: <" .. rename.gpn(owner) .. ">'s mailbox is full!")
    end
  end
  if listname == "cfg" and stack:get_name() == "techcrafts:control_logic_unit" then
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local owner = meta:get_string('owner')
    if owner == pname or gdac.player_is_admin(pname) then
      if inv:get_stack('cfg', index):get_count() == 0 then
        return 1
      end
    end
  end
  return 0
end



mailbox.allow_metadata_inventory_move = 
function(pos, from_list, from_index, to_list, to_index, count, player)
  return 0
end



mailbox.allow_metadata_inventory_take = 
function(pos, listname, index, stack, player)
  local meta = minetest.get_meta(pos)
  local owner = meta:get_string('owner')
  local pname = player:get_player_name()
  if owner == pname or gdac.player_is_admin(pname) then
		return stack:get_count()
	end
  return 0
end
