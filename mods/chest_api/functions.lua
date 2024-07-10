
-- Localize for performance.
local F = minetest.formspec_escape
local vector_distance = vector.distance
local math_random = math.random


-- This function is responsible for triggering the update of vending
-- machines when a chest inventory is modified.
chest_api.update_vending = function(pos)
	local vendors = {}
	local node = nil

	local names = {
		"easyvend:vendor",
		"easyvend:vendor_on",
		"easyvend:depositor",
		"easyvend:depositor_on",
	}
	local valid_vendor = function(name)
		for k, v in ipairs(names) do
			if v == name then
				return true
			end
		end
	end

	local orig_pos = table.copy(pos)

	-- Search upwards.
	pos.y = pos.y + 1
	node = minetest.get_node_or_nil(pos)
	while node ~= nil do
		if easyvend.traversable_node_types[node.name] then
			if valid_vendor(node.name) then
				vendors[#vendors+1] = {pos=table.copy(pos), node=table.copy(node)}
			end
		else
			break
		end

		pos.y = pos.y + 1
		node = minetest.get_node_or_nil(pos)
	end

	pos = table.copy(orig_pos)

	-- Search downwards.
	pos.y = pos.y - 1
	node = minetest.get_node_or_nil(pos)
	while node ~= nil do
		if easyvend.traversable_node_types[node.name] then
			if valid_vendor(node.name) then
				vendors[#vendors+1] = {pos=table.copy(pos), node=table.copy(node)}
			end
		else
			break
		end

		pos.y = pos.y - 1
		node = minetest.get_node_or_nil(pos)
	end

	-- Perform vending checks!
	for k, v in ipairs(vendors) do
		easyvend.machine_check(v.pos, v.node)
		--minetest.chat_send_all("# Server: Machine check!")
	end
end

function chest_api.sort_chest(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	local inlist = inv:get_list("main")
	local typecnt = {}
	local typekeys = {}

	for _, st in ipairs(inlist) do
		if not st:is_empty() then
			local n = st:get_name()
			local k = string.format("%s", n)
			if not typecnt[k] then
				typecnt[k] = {st}
				table.insert(typekeys, k)
			else
				table.insert(typecnt[k], st)
			end
		end
	end

	table.sort(typekeys)
	inv:set_list("main", {})
	for _, k in ipairs(typekeys) do
		for _, item in ipairs(typecnt[k]) do
			inv:add_item("main", item)
		end
	end
end

local function get_share_names(meta)
  local share_names = meta:get_string("share_names") or ""
  if share_names ~= "" then
    local tb = minetest.parse_json(share_names)
    if tb and type(tb) == "table" then
			-- Count how many entries the share table has, and return that as second value.
			local c = 0
			for k, v in pairs(tb) do
				c = c + 1
			end
      return tb, c
    end
  end
  return {}, 0
end

chest_api.get_chest_formspec = function(name, desc, pos)
  local spos = pos.x .. "," .. pos.y .. "," .. pos.z
  local defgui = default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots
  local formspec
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	-- Permit grandfathering of old shared ironside chests.
	local shares, sharecount = get_share_names(meta)
  
	-- Obtain hooks into the trash mod's trash slot inventory.
	local ltrash, mtrash = trash.get_listname()
	local itrash = trash.get_iconname()

  -- Locked or unlocked gold chest.
  if string.find(name, "gold") then
    formspec = "size[12,10]" .. defgui ..
      "list[nodemeta:" .. spos .. ";main;0,1.3;12,4;]" ..
      "list[current_player;main;1,5.85;8,1;]" ..
      "list[current_player;main;1,7.08;8,3;8]" ..
      "listring[nodemeta:" .. spos .. ";main]" ..
      "listring[current_player;main]" ..
      "label[0,0;" .. desc .. "]" ..
      default.get_hotbar_bg(1, 5.85)

			-- Trash icon.
			.. "list[" .. ltrash .. ";" .. mtrash .. ";10,5.85;1,1;]" ..
			"image[10,5.85;1,1;" .. itrash .. "]"
    
    -- Locked gold chest.
    if string.find(name, "locked") then 
      local chest_name = F(meta:get_string("chest_name") or "")
      formspec = formspec .. "button[10,0;2,1;rename;Rename]" ..
        "field[8.25,0.45;2,0.75;name;;" .. chest_name .. "]" ..
        "field_close_on_enter[name;false]" ..
        "label[0,0.35;Label: <" .. chest_name .. ">]"
    end

	-- Locked or unlocked diamond chest.
  elseif string.find(name, "diamond") then
    formspec = "size[12,11]" .. defgui ..
      "list[nodemeta:" .. spos .. ";main;0,1.3;12,5;]" ..
      "list[current_player;main;1,6.85;8,1;]" ..
      "list[current_player;main;1,8.08;8,3;8]" ..
      "listring[nodemeta:" .. spos .. ";main]" ..
      "listring[current_player;main]" ..
      "label[0,0;" .. desc .. "]" ..
      default.get_hotbar_bg(1, 6.85)

			-- Trash icon.
			.. "list[" .. ltrash .. ";" .. mtrash .. ";10,6.85;1,1;]" ..
			"image[10,6.85;1,1;" .. itrash .. "]"

    -- Locked diamond chest.
    if string.find(name, "locked") then
      local chest_name = F(meta:get_string("chest_name") or "")
      formspec = formspec .. "button[10,0;2,1;rename;Rename]" ..
        "field[8.25,0.45;2,0.75;name;;" .. chest_name .. "]" ..
        "field_close_on_enter[name;false]" ..
        "label[0,0.35;Label: <" .. chest_name .. ">]"
    end

	-- Locked or unlocked mithril chest.
  elseif string.find(name, "mithril") then
    formspec = "size[14,11]" .. defgui ..
      "list[nodemeta:" .. spos .. ";main;0,1.3;14,5;]" ..
      "list[current_player;main;2,6.85;8,1;]" ..
      "list[current_player;main;2,8.08;8,3;8]" ..
      "listring[nodemeta:" .. spos .. ";main]" ..
      "listring[current_player;main]" ..
      "label[0,0;" .. desc .. "]" ..
      default.get_hotbar_bg(2, 6.85)

			-- Trash icon.
			.. "list[" .. ltrash .. ";" .. mtrash .. ";11,6.85;1,1;]" ..
			"image[11,6.85;1,1;" .. itrash .. "]"

    -- Locked mithril chest.
    if string.find(name, "locked") then
      local chest_name = F(meta:get_string("chest_name") or "")
      formspec = formspec .. "button[12,0;2,1;rename;Rename]" ..
        "field[10.25,0.45;2,0.75;name;;" .. chest_name .. "]" ..
        "field_close_on_enter[name;false]" ..
        "label[0,0.35;Label: <" .. chest_name .. ">]"
    end
    
  -- Locked silver chest. (This chest is shareable.) Grandfather in old ironside chests.
  elseif (string.find(name, "silver") and string.find(name, "locked")) or sharecount > 0 then
    local chest_name = F(meta:get_string("chest_name") or "")
    formspec = "size[10,10]" .. defgui ..
      "list[nodemeta:" .. spos .. ";main;0,1.3;8,4;]" ..
      "list[current_player;main;0,5.85;8,1;]" ..
      "list[current_player;main;0,7.08;8,3;8]" ..
      "listring[nodemeta:" .. spos .. ";main]" ..
      "listring[current_player;main]" ..
      "label[0,0;" .. desc .. "]" ..
      default.get_hotbar_bg(0, 5.85) ..
      "button[6,0;2,1;rename;Rename]" ..
      "field[4.25,0.45;2,0.75;name;;" .. chest_name .. "]" ..
      "field_close_on_enter[name;false]" ..
      "label[0,0.35;Label: <" .. chest_name .. ">]" ..
      "button[8,1.2;2,1;doshare;Share Chest]" ..
      "button[8,2.2;2,1;unshare;Unshare]" ..
      "tooltip[unshare;Warning:\n\nThis will remove all the players\nfrom the access list of this chest!]"

			-- Trash icon.
			.. "list[" .. ltrash .. ";" .. mtrash .. ";9,5.85;1,1;]" ..
			"image[9,5.85;1,1;" .. itrash .. "]"
    
    --formspec = formspec .. "textlist[8,1.26;1.70,3;sharelist;Item ##1,Item ##2,Item ##3]"
    
  -- Locked/unlocked copper, iron, or silver chests.
  elseif string.find(name, "iron") or
         string.find(name, "copper") or
         string.find(name, "silver") then 
		local locked = string.find(name, "locked")

		if locked then
			formspec = "size[9,10]"
		else
			formspec = "size[8,10]"
		end

		formspec = formspec .. defgui ..
      "list[nodemeta:" .. spos .. ";main;0,1.3;8,4;]" ..
      "list[current_player;main;0,5.85;8,1;]" ..
      "list[current_player;main;0,7.08;8,3;8]" ..
      "listring[nodemeta:" .. spos .. ";main]" ..
      "listring[current_player;main]" ..
      "label[0,0;" .. desc .. "]" ..
      default.get_hotbar_bg(0, 5.85)
    
    -- Locked copper or iron chest.
    -- (If chest was locked silver, then another if-statement already handled it.)
		-- Iron locked chests with existing shares are grandfathered in.
    if locked then
      local chest_name = F(meta:get_string("chest_name") or "")
      formspec = formspec .. "button[6,0;2,1;rename;Rename]" ..
        "field[4.25,0.45;2,0.75;name;;" .. chest_name .. "]" ..
        "field_close_on_enter[name;false]" ..
        "label[0,0.35;Label: <" .. chest_name .. ">]"

				-- Trash icon.
				.. "list[" .. ltrash .. ";" .. mtrash .. ";8,1.3;1,1;]" ..
				"image[8,1.3;1,1;" .. itrash .. "]"
		else
			-- Trash icon. This also applies to the unlocked silver chest!
			formspec = formspec
				.. "list[" .. ltrash .. ";" .. mtrash .. ";7,0;1,1;]" ..
				"image[7,0;1,1;" .. itrash .. "]"
    end

	-- Default chest or woodchest (old version). We MUST preserve the formspec for the old chest version!
	elseif inv:get_size("main") == 8*4 and (name:find("woodchest") or name:find("^chests:chest_")) then
    formspec = "size[8,9]" .. defgui ..
      "list[nodemeta:" .. spos .. ";main;0,0.3;8,4;]" ..
      "list[current_player;main;0,4.85;8,1;]" ..
      "list[current_player;main;0,6.08;8,3;8]" ..
      "listring[nodemeta:" .. spos .. ";main]" ..
      "listring[current_player;main]" ..
      default.get_hotbar_bg(0, 4.85)
    
  -- Locked/unlocked non-metalic chest (new version). Should have 8*3 size inventory.
  else 
    formspec = "size[9,8]" .. defgui ..
      "list[nodemeta:" .. spos .. ";main;0,0.3;8,3;]" ..
      "list[current_player;main;0,3.85;8,1;]" ..
      "list[current_player;main;0,5.08;8,3;8]" ..
      "listring[nodemeta:" .. spos .. ";main]" ..
      "listring[current_player;main]" ..
      default.get_hotbar_bg(0, 3.85)

			-- Trash icon.
			.. "list[" .. ltrash .. ";" .. mtrash .. ";8,0.3;1,1;]" ..
			"image[8,0.3;1,1;" .. itrash .. "]"
  end
  
  return formspec
end

local function get_chest_name(meta)
  local cname = meta:get_string("chest_name") or ""
  if cname == "" then
    return "this chest"
  else
    return "<" .. cname .. ">"
  end
end

local function add_share_name(meta, name, pname)
  if name == "" then return end -- Failsafe.
	name = rename.grn(name)
  -- Being able to get rid of ghosts from the past may be a good idea.
  -- Being able to shove them in the future probably isn't.
  if not minetest.player_exists(name) then
    minetest.chat_send_player(pname, "# Server: Can't add non-existent player <" .. rename.gpn(name) .. ">.")
    easyvend.sound_error(pname)
    return
  end
  local share_names, share_count = get_share_names(meta)
  if not share_names[name] then
    minetest.chat_send_player(pname, "# Server: Player <" .. rename.gpn(name) .. "> will now have access to " .. get_chest_name(meta) .. ".")
  end
  share_names[name] = 1
  local str = minetest.write_json(share_names)
  meta:set_string("share_names", str)
end

local function del_share_name(meta, name, pname)
  if name == "" then return end -- Failsafe.
	name = rename.grn(name)
  local share_names, share_count = get_share_names(meta)
  if share_names[name] then
    minetest.chat_send_player(pname, "# Server: Player <" .. rename.gpn(name) .. "> can no longer access " .. get_chest_name(meta) .. ".")
  else
    minetest.chat_send_player(pname, "# Server: Player <" .. rename.gpn(name) .. "> was not in the access list of " .. get_chest_name(meta) .. ".")
    easyvend.sound_error(pname)
  end
  share_names[name] = nil
  local str = minetest.write_json(share_names) -- Returns nil for empty table?
  meta:set_string("share_names", str)
end

-- Generate a share formspec. We need the chest metadata.
chest_api.get_share_formspec = function(pos, meta, delname)
  local node = minetest.get_node(pos)
  local nn = node.name
  local desc = minetest.reg_ns_nodes[nn].description
  local cname = meta:get_string("chest_name") or ""
  
  local formspec
  local defgui = default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots
  
  formspec = "size[8,5]" .. defgui ..
    "label[0,0;" .. F(utility.get_short_desc(desc)) .. "]" ..
    "label[0,0.35;Label: <" .. F(cname) .. ">]" ..
    "button[6,0;2,1;unshare;Unshare]" ..
    "tooltip[unshare;Warning:\n\nThis will remove all the players\nfrom the access list of this chest!]" ..
    "button_exit[6,4;2,1;quit;Close]" ..
    "button[2.5,2.14;2,1.02;addname;Add Name]" ..
    "button[2.5,3.14;2,1.02;delname;Remove Name]" ..
    "label[0,1.71;Add or remove access grants:]" ..
    "field[0.27,2.46;2.5,1;addname_field;;]" ..
    "field_close_on_enter[addname_field;false]" ..
    "field[0.27,3.46;2.5,1;delname_field;;" .. F(delname or "") .. "]" ..
    "field_close_on_enter[delname_field;false]" ..
    "label[0,4;Tip: any locked chest can be shared with a key.]"
  
  formspec = formspec ..
    "textlist[5,1;2.8,2.9;sharelist;"
  
  local share_names, share_count = get_share_names(meta)
  for k, v in pairs(share_names) do
    formspec = formspec .. F(rename.gpn(k)) .. ","
  end 
  formspec = string.gsub(formspec, ",$", "") -- Remove trailing comma.
  formspec = formspec .. "]"
  
  return formspec
end

-- This function is only used to check if a player is allowed to take/move/put
-- from a chest inventory, or is allowed to open the formspec.
local function has_locked_chest_privilege(pos, name, meta, player)
  if minetest.check_player_privs(player, "protection_bypass") then
    return true
  end
  
	if player:get_player_name() == meta:get_string("owner") then
		-- Owner can access the node to any time
		return true
	end

	-- Registered cheaters lose locked chest privileges.
	--
	-- Note: disabled as of [8/15/22]: the consequences of an accidental false
	-- positive include (but are not limited to): drama, emoting, rage-quitting,
	-- misunderstanding, fake news, incorrect information, assumptions, "stolen"
	-- items, returned items, banned items, items on fire, gossip, problems with
	-- family members, tale-bearing, suspicions that the admin is taking sides,
	-- unhelpful sisters, locked chests, unlocked chests, chests with stray pieces
	-- of underwear, missing time, verbal combat and other general mayhem, etc.
	-- etc. etc.
	--
	-- Update: re-enabled as of [8/16/22]: there is now a delay which allows the
	-- admin time to correct a mistake in the event of a wrong cheat detection.
	--
	-- Update [2024/5/27]: two years later I still think this comment is funny.
	-- Lol lol lol.
	do
		local cheater, time = sheriff.is_cheater(meta:get_string("owner"))
		if cheater then
			local week = 60*60*24*7
			if os.time() > (time + week) then
				return true
			end
		end
	end

  -- Locked silver chests have sharing functionality. Remember to grandfather in old shared ironside chests.
	if name:find("iron") or name:find("silver") then
		local share_names, share_count = get_share_names(meta)
		if (string.find(name, "silver") and string.find(name, "locked")) or share_count > 0 then
			if share_names[player:get_player_name()] then
				return true
			end
		end
	end
  
  -- Is player wielding the right key?
  local item = player:get_wielded_item()
  if item:get_name() == "key:key" or item:get_name() == "key:chain" then
    local key_meta = item:get_meta()
    
		if key_meta:get_string("secret") == "" then
			local key_oldmeta = item:get_metadata()
			if key_oldmeta == "" or not minetest.parse_json(key_oldmeta) then
				return false
			end

			key_meta:set_string("secret", minetest.parse_json(key_oldmeta).secret)
			item:set_metadata("")
		end

		return meta:get_string("key_lock_secret") == key_meta:get_string("secret")
  end

	-- Is chest open?
	do
		local node = minetest.get_node(pos)
		if string.find(node.name, "_open$") then
			-- Player must be near enough to the chest.
			if vector_distance(pos, player:get_pos()) < 6 then
				return true
			end
		end
	end
  
  return false
end
chest_api.has_locked_chest_privilege = has_locked_chest_privilege

local function chest_lid_obstructed(pos)
	local above = { x = pos.x, y = pos.y + 1, z = pos.z }
	local def = minetest.reg_ns_nodes[minetest.get_node(above).name]
	if not def then
		return true
	end
	-- allow ladders, signs, wallmounted things and torches to not obstruct
	if def.drawtype == "airlike" or
			def.drawtype == "signlike" or
			def.drawtype == "torchlike" or
			((def.drawtype == "nodebox" or def.drawtype == "mesh") and def.paramtype2 == "wallmounted") then
		return false
	end
	return true
end

chest_api.open_chests = chest_api.open_chests or {}
local open_chests = chest_api.open_chests

local function open_chest(def, pos, node, clicker)
	-- Player name.
	local pname = clicker:get_player_name()

	-- Chest basename.
	local name = def._chest_basename

	-- Delay before opening chest formspec.
	local admin = (gdac.player_is_admin(pname) and gdac_invis.is_invisible(pname))
	local open_delay = (not admin and 0.2 or 0)

	-- Don't play sound or open chest, if opener is admin and not invisible.
	if not admin then
		local meta = minetest.get_meta(pos)
		local last_oiled = meta:get_int("oiled_time")
		if (os.time() - last_oiled) > math_random(0, 60*60*24*30) then
			-- Play sound, open chest.
			ambiance.sound_play(def.sound_open, pos, 0.5, 20)
		else
			-- Oiled chests open faster.
			open_delay = 0
		end

		if not chest_lid_obstructed(pos) then
			minetest.swap_node(pos,
					{ name = name .. "_open",
					param2 = node.param2 })
		end
	end

  minetest.after(open_delay, minetest.show_formspec,
      clicker:get_player_name(),
      "default:chest",
			chest_api.get_chest_formspec(name, def.description, pos))

  open_chests[pname] = { 
    pos = pos,
    sound = def.sound_close,
    swap = name .. "_closed",
    orig = name .. "_open",
  }
end

local function close_chest(pn, pos, node, swap, sound)
	-- Don't play sound or open chest, if opener is admin and not invisible.
	local admin = (gdac.player_is_admin(pn) and gdac_invis.is_invisible(pn))

  open_chests[pn] = nil

	-- Skip sorting, sound, and chest-closing, if player is invisible admin.
	if admin then
		return
	end

  for k, v in pairs(open_chests) do
    if vector.equals(v.pos, pos) then
      return -- This checks if someone else has chest open.
    end
  end

	-- Play sound, close chest.	
  minetest.after(0.2, minetest.swap_node, pos, {
    name = swap,
    param2 = node.param2
  })

	local meta = minetest.get_meta(pos)
	local last_oiled = meta:get_int("oiled_time")
	if (os.time() - last_oiled) > math_random(0, 60*60*24*30) then
		ambiance.sound_play(sound, pos, 0.5, 20)
	end

	-- Mithril chests auto-sort when closed.
	-- Thus they are always already sorted when opened.
	if string.find(swap, "mithril") then
		chest_api.sort_chest(pos)
	end
end



function chest_api.on_leaveplayer(player, timeout)
  if not player or not player:is_player() then return end
  local pn = player:get_player_name()
  if open_chests[pn] then
    local pos = open_chests[pn].pos
    local node = minetest.get_node(pos)
    local sound = open_chests[pn].sound
    local swap = open_chests[pn].swap
    close_chest(pn, pos, node, swap, sound)
  end
end

function chest_api.on_dieplayer(player)
  if not player or not player:is_player() then return end
  local pn = player:get_player_name()
  if open_chests[pn] then
    local pos = open_chests[pn].pos
    local node = minetest.get_node(pos)
    local sound = open_chests[pn].sound
    local swap = open_chests[pn].swap
    close_chest(pn, pos, node, swap, sound)
  end
end



function chest_api.on_player_receive_fields(player, formname, fields)
  -- This function is valid for these callbacks only.
  if formname ~= "default:chest" and formname ~= "default:chest_share" then
    return -- Continue handling callbacks.
  end

	if not player then
		return true
	end
  local pn = player:get_player_name()

  -- Anticheat check.
  if not open_chests[pn] then
    minetest.chat_send_player(pn, "# Server: No chest opened.")
    return true -- Abort.
  end

  local pos = open_chests[pn].pos
  local node = minetest.get_node(pos)
  local nn = node.name
  local sound = open_chests[pn].sound
  local swap = open_chests[pn].swap
  local orig = open_chests[pn].orig
  local meta = minetest.get_meta(pos)
  local owner = meta:get_string("owner") or "" -- Only locked chests have owners.

  -- Failsafe.
  if nn ~= orig and nn ~= swap then
    minetest.chat_send_player(pn, "# Server: Error: 0xDEADBEEF (bad node)!")
    return true -- Abort.
  end

  if fields.rename or fields.key_enter_field == "name" then
    -- Anitcheat check.
    if (string.find(nn, "copper") or string.find(nn, "diamond") or
        string.find(nn, "iron") or
        string.find(nn, "silver") or
        string.find(nn, "gold") or
        string.find(nn, "mithril")) and string.find(nn, "locked") then
      if owner == pn or gdac.player_is_admin(pn) then
        minetest.chat_send_player(pn, "# Server: Chest name updated.")
				local new_name = (fields.name or "")
				new_name = new_name:trim()
        meta:set_string("chest_name", new_name)

        local owner = meta:get_string("owner") or ""
				local dname = rename.gpn(owner)
        local cname = meta:get_string("chest_name") or ""
        if cname == "" then
          meta:set_string("infotext", "Locked Chest (Owned by <" .. dname .. ">!)")
        else
          meta:set_string("infotext", "Locked Chest (Owned by <" .. dname .. ">!)\nLabel: <" .. cname .. ">")
        end

        local desc = minetest.reg_ns_nodes[nn].description
        minetest.show_formspec(pn, "default:chest", chest_api.get_chest_formspec(nn, desc, pos))
      else
        minetest.chat_send_player(pn, "# Server: You cannot relabel this chest.")
        easyvend.sound_error(pn)
      end
    else
      minetest.chat_send_player(pn, "# Server: This chest does not have labeling functionality.")
      easyvend.sound_error(pn)
    end
  end

  if fields.doshare then -- Button on main formspec.
		-- Permit grandfathering of old shared ironside chests.
		local shares, sharecount = get_share_names(meta)

    if (string.find(nn, "silver") and string.find(nn, "locked")) or sharecount > 0 then
      if owner == pn or gdac.player_is_admin(pn) then
        minetest.show_formspec(pn, "default:chest_share", chest_api.get_share_formspec(pos, meta))
      else
        minetest.chat_send_player(pn, "# Server: You do not have permission to manage shares for this chest.")
        easyvend.sound_error(pn)
      end
    else
      minetest.chat_send_player(pn, "# Server: This chest does not have sharing functionality.")
      easyvend.sound_error(pn)
    end
  end

  if fields.unshare then -- This button is on the sharing and main formspecs.
		-- Permit grandfathering of old shared ironside chests.
		local shares, sharecount = get_share_names(meta)

    if (string.find(nn, "silver") and string.find(nn, "locked")) or sharecount > 0 then
      if owner == pn or gdac.player_is_admin(pn) then
        meta:set_string("share_names", nil)
        minetest.chat_send_player(pn, "# Server: All share grants revoked for " .. get_chest_name(meta) .. ".")

        -- Refresh sharing formspec only if already being displayed.
        -- The main formspec doesn't need updating.
        if formname == "default:chest_share" then
          minetest.show_formspec(pn, "default:chest_share", chest_api.get_share_formspec(pos, meta))
        end
      else
        minetest.chat_send_player(pn, "# Server: You do not have permission to manage shares for this chest.")
        easyvend.sound_error(pn)
      end
    else
      minetest.chat_send_player(pn, "# Server: This chest does not have sharing functionality.")
      easyvend.sound_error(pn)
    end
  end

  if fields.addname or fields.key_enter_field == "addname_field" then -- Sharing formspec only.
		-- Permit grandfathering of old shared ironside chests.
		local shares, sharecount = get_share_names(meta)

    if (string.find(nn, "silver") and string.find(nn, "locked")) or sharecount > 0 then
      if owner == pn or gdac.player_is_admin(pn) then
        if fields.addname_field ~= "" then
          add_share_name(meta, fields.addname_field, pn)

          -- The sharing formspec is being displayed. Refresh it.
          minetest.show_formspec(pn, "default:chest_share", chest_api.get_share_formspec(pos, meta))
        else
          minetest.chat_send_player(pn, "# Server: You must specify a player name to add to the access list.")
          easyvend.sound_error(pn)
        end
      else
        minetest.chat_send_player(pn, "# Server: You do not have permission to manage shares for this chest.")
        easyvend.sound_error(pn)
      end
    else
      minetest.chat_send_player(pn, "# Server: This chest does not have sharing functionality.")
      easyvend.sound_error(pn)
    end
  end

  if fields.delname or fields.key_enter_field == "delname_field" then -- Sharing formspec only.
		-- Permit grandfathering of old shared ironside chests.
		local shares, sharecount = get_share_names(meta)

    if (string.find(nn, "silver") and string.find(nn, "locked")) or sharecount > 0 then
      if owner == pn or gdac.player_is_admin(pn) then
        if fields.delname_field ~= "" then
          del_share_name(meta, fields.delname_field, pn)

          -- The sharing formspec is being displayed. Refresh it.
          minetest.show_formspec(pn, "default:chest_share", chest_api.get_share_formspec(pos, meta))
        else
          minetest.chat_send_player(pn, "# Server: You must specify a player name to remove from the access list.")
          easyvend.sound_error(pn)
        end
      else
        minetest.chat_send_player(pn, "# Server: You do not have permission to manage shares for this chest.")
        easyvend.sound_error(pn)
      end
    else
      minetest.chat_send_player(pn, "# Server: This chest does not have sharing functionality.")
      easyvend.sound_error(pn)
    end
  end

  if fields.sharelist then
    -- Permit grandfathering of old shared ironside chests.
    local shares, sharecount = get_share_names(meta)

    if (string.find(nn, "silver") and string.find(nn, "locked")) or sharecount > 0 then
      if owner == pn or gdac.player_is_admin(pn) then
        local event = minetest.explode_textlist_event(fields.sharelist)
        if event.type == "DCL" then
          local idx = event.index
          if idx >= 1 and idx <= sharecount then
            -- NOTE: This is hacky and (cit.) ugly as sin! But per-player
            -- contexts sounds like over-engineering here.
            -- The problem is Lua gives no legit way to get a table key from its
            -- index. (There is no index at all!) Moreover, the order that pairs
            -- iterates through the keys of a table is unspecified. Moreover,
            -- the table I get here by calling get_share_names is not even the
            -- same that was used during the formspec generation, and it may
            -- even contain different names, or have them in a different order
            -- (although there is *no* order!) because the metadata from which
            -- it is created could have changed in the meanwhile.
            local delname
            for k, v in pairs(shares) do
              delname = k
              idx = idx - 1
              if idx == 0 then
                break
              end
            end
            delname = rename.gpn(delname)

            -- The sharing formspec is being displayed. Refresh it.
            minetest.show_formspec(pn, "default:chest_share", chest_api.get_share_formspec(pos, meta, delname))
          end
        end
      else
        minetest.chat_send_player(pn, "# Server: You do not have permission to manage shares for this chest.")
        easyvend.sound_error(pn)
      end
    else
      minetest.chat_send_player(pn, "# Server: This chest does not have sharing functionality.")
      easyvend.sound_error(pn)
    end
  end

  if not fields.quit then
    return true
  end

  -- Close chest.
  close_chest(pn, pos, node, swap, sound)
  return true
end



function chest_api.protected_on_construct(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("infotext", "Locked Chest")
	meta:set_string("owner", "")
	local inv = meta:get_inventory()
	local name = minetest.get_node(pos).name
	if string.find(name, "gold") then
		inv:set_size("main", 12*4)
	elseif string.find(name, "diamond") then
		inv:set_size("main", 12*5)
	elseif string.find(name, "mithril") then
		inv:set_size("main", 14*5)
	elseif name:find("woodchest") or name:find("^chests:chest_") then
		inv:set_size("main", 8*3)
	else
		inv:set_size("main", 8*4)
	end
end

function chest_api.protected_after_place_node(pos, placer)
	local meta = minetest.get_meta(pos)
	local owner = placer:get_player_name() or ""
	local dname = rename.gpn(owner)
	meta:set_string("owner", owner)
	meta:set_string("rename", dname)
	meta:set_string("infotext", "Locked Chest (Owned by <" .. dname .. ">!)")
	meta:set_string("formspec", nil)
end

function chest_api.protected_can_dig(pos, player)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner") or ""
	local pname = player:get_player_name()
	local inv = meta:get_inventory()
	
	-- Only chest owners can dig shared locked chests.
	-- If chests is owned by the server, or by no one, then anyone can dig.
	return inv:is_empty("main") and (owner == pname or owner == "" or owner == "server")
end

function chest_api.protected_allow_metadata_inventory_move(
	pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local name = minetest.get_node(pos).name
	if not has_locked_chest_privilege(pos, name, meta, player) then
		return 0
	end
	return count
end

function chest_api.protected_allow_metadata_inventory_put(
	pos, listname, index, stack, player)
	local meta = minetest.get_meta(pos)
	local name = minetest.get_node(pos).name
	if not has_locked_chest_privilege(pos, name, meta, player) then
		return 0
	end
	return stack:get_count()
end

function chest_api.protected_allow_metadata_inventory_take(
	pos, listname, index, stack, player)
	local meta = minetest.get_meta(pos)
	local name = minetest.get_node(pos).name
	if not has_locked_chest_privilege(pos, name, meta, player) then
		return 0
	end
	return stack:get_count()
end

function chest_api.protected_on_rightclick(pos, node, clicker)
	local meta = minetest.get_meta(pos)
	local def = minetest.reg_ns_nodes[minetest.get_node(pos).name]
	local name = def._chest_basename
	if not has_locked_chest_privilege(pos, name, meta, clicker) then
		ambiance.sound_play("default_chest_locked", pos, 1.0, 20)
		return
	end

	local meta = minetest.get_meta(pos)

	local owner = meta:get_string("owner") or ""
	local dname = rename.gpn(owner)
	local cname = meta:get_string("chest_name") or ""

	if cname == "" then
		meta:set_string("infotext", "Locked Chest (Owned by <" .. dname .. ">!)")
	else
		meta:set_string("infotext", "Locked Chest (Owned by <" .. dname .. ">!)\nLabel: <" .. cname .. ">")
	end

	-- Upgrade inventory size.
	if string.find(name, "gold") then
		local inv = meta:get_inventory()
		local inv_sz = inv:get_size("main")
		if inv_sz ~= 12*4 then
			inv:set_size("main", 12*4)
		end
	elseif string.find(name, "mithril") then
		local inv = meta:get_inventory()
		local inv_sz = inv:get_size("main")
		if inv_sz ~= 14*5 then
			inv:set_size("main", 14*5)
		end
	end

	-- Do NOT update inventory sides for old woodchests/default chests.
	-- They are relied on by too many players. Only new chests will have smaller inventories.

	open_chest(def, pos, node, clicker)
end

function chest_api.protected_on_key_use(pos, player)
	local node = minetest.get_node(pos)
	local def = minetest.reg_ns_nodes[node.name]
	local name = def._chest_basename

	-- Failsafe.
	if node.name ~= name .. "_closed" then return end
	if not player or not player:is_player() then return end

	local meta = minetest.get_meta(pos)
	local secret = meta:get_string("key_lock_secret")
	local itemstack = player:get_wielded_item()
	local key_meta = itemstack:get_meta()

	if key_meta:get_string("secret") == "" then
		local key_oldmeta = itemstack:get_metadata()
		if key_oldmeta == "" or not minetest.parse_json(key_oldmeta) then
			return false
		end

		key_meta:set_string("secret", minetest.parse_json(key_oldmeta).secret)
		itemstack:set_metadata("")
	end

	if secret ~= key_meta:get_string("secret") then
		minetest.chat_send_player(player:get_player_name(), "# Server: Key does not fit lock!")
		return
	end

	local owner = meta:get_string("owner") or ""
	local dname = rename.gpn(owner)
	local cname = meta:get_string("chest_name") or ""
	if cname == "" then
		meta:set_string("infotext", "Locked Chest (Owned by <" .. dname .. ">!)")
	else
		meta:set_string("infotext", "Locked Chest (Owned by <" .. dname .. ">!)\nLabel: <" .. cname .. ">")
	end

	-- Upgrade inventory size.
	if string.find(name, "gold") then
		local inv = meta:get_inventory()
		local inv_sz = inv:get_size("main")
		if inv_sz ~= 12*4 then
			inv:set_size("main", 12*4)
		end
	elseif string.find(name, "mithril") then
		local inv = meta:get_inventory()
		local inv_sz = inv:get_size("main")
		if inv_sz ~= 14*5 then
			inv:set_size("main", 14*5)
		end
	end

	-- Do NOT update inventory sides for old woodchests/default chests.
	-- They are relied on by too many players. Only new chests will have smaller inventories.

	open_chest(def, pos, node, player)
end

function chest_api.protected_on_skeleton_key_use(pos, player, newsecret)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	local pname = player:get_player_name()

	-- verify placer is owner of lockable chest
	if not gdac.player_is_admin(pname) then
		if owner ~= pname then
			minetest.record_protection_violation(pos, pname)
			minetest.chat_send_player(pname, "# Server: You do not own this chest.")
			return nil
		end
	end

	local secret = meta:get_string("key_lock_secret")
	if secret == "" then
		secret = newsecret
		meta:set_string("key_lock_secret", secret)
	end

	return secret, "a locked chest", owner
end

function chest_api.protected_on_rename_check(pos)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	-- Nobody placed this block.
	if owner == "" then
		return
	end
	local dname = rename.gpn(owner)
	meta:set_string("rename", dname)

	local label = meta:get_string("chest_name") or ""
	if label == "" then
		meta:set_string("infotext", "Locked Chest (Owned by <" .. dname .. ">!)")
	else
		meta:set_string("infotext", "Locked Chest (Owned by <" .. dname .. ">!)\nLabel: <" .. label .. ">")
	end
end

function chest_api.public_on_construct(pos)
	local meta = minetest.get_meta(pos)
	local name = minetest.get_node(pos).name
	meta:set_string("infotext", "Unlocked Chest")
	local inv = meta:get_inventory()
	if string.find(name, "gold") then
		inv:set_size("main", 12*4)
	elseif string.find(name, "diamond") then
		inv:set_size("main", 12*5)
	elseif string.find(name, "mithril") then
		inv:set_size("main", 14*5)
	elseif name:find("woodchest") or name:find("^chests:chest_") then
		inv:set_size("main", 8*3)
	else
		inv:set_size("main", 8*4)
	end
end

function chest_api.public_can_dig(pos,player)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	return inv:is_empty("main")
end

function chest_api.public_on_rightclick(pos, node, clicker)
	local meta = minetest.get_meta(pos)
	local def = minetest.reg_ns_nodes[minetest.get_node(pos).name]
	local name = def._chest_basename
	meta:set_string("infotext", "Unlocked Chest")
	meta:set_string("formspec", nil)

	-- Upgrade inventory size.
	if string.find(name, "gold") then
		local inv = meta:get_inventory()
		local inv_sz = inv:get_size("main")
		if inv_sz ~= 12*4 then
			inv:set_size("main", 12*4)
		end
	elseif string.find(name, "mithril") then
		local inv = meta:get_inventory()
		local inv_sz = inv:get_size("main")
		if inv_sz ~= 14*5 then
			inv:set_size("main", 14*5)
		end
	end

	-- Do NOT update inventory sides for old woodchests/default chests.
	-- They are relied on by too many players. Only new chests will have smaller inventories.

	open_chest(def, pos, node, clicker)
end

function chest_api.on_receive_fields(pos, formname, fields, sender)
	if not sender or not sender:is_player() then return end
	-- convert chest by removing the formspec and renaming the inv
	-- the order here is chosen to minimize the chance of two conversion
	-- attempts running at the same time from racing.
	-- after this function runs, it destroys the formspec in the metadata
	-- and will never be called again for this chest.
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", nil)

	-- We do not attempt to switch the inventory.
	--local inv = meta:get_inventory()
	--local list = inv:get_list("main")
	--inv:set_list("main", nil)
	--inv:set_size("default:chest", 8*4)
	--inv:set_list("default:chest", list)
end

function chest_api.on_metadata_inventory_move(
	pos, from_list, from_index, to_list, to_index, count, player)
	minetest.log("action", player:get_player_name() ..
		" moves stuff in chest at " .. minetest.pos_to_string(pos))

	if string.find(minetest.get_node(pos).name, "locked") then
		minetest.after(0, function() chest_api.update_vending(pos) end)
	end
end

function chest_api.on_metadata_inventory_put(pos, listname, index, stack, player)
	minetest.log("action", player:get_player_name() ..
		" moves " .. stack:get_name() ..
		" to chest at " .. minetest.pos_to_string(pos))

	if string.find(minetest.get_node(pos).name, "locked") then
		minetest.after(0, function() chest_api.update_vending(pos) end)
	end
end

function chest_api.on_metadata_inventory_take(pos, listname, index, stack, player)
	minetest.log("action", player:get_player_name() ..
		" takes " .. stack:get_name() ..
		" from chest at " .. minetest.pos_to_string(pos))

	if string.find(minetest.get_node(pos).name, "locked") then
		minetest.after(0, function() chest_api.update_vending(pos) end)
	end
end

function chest_api.on_blast(pos)
	local def = minetest.reg_ns_nodes[minetest.get_node(pos).name]
	local name = def._chest_basename
	local drops = {}
	default.get_inventory_drops(pos, "main", drops)
	drops[#drops+1] = name .. "_closed"
	minetest.remove_node(pos)
	return drops
end

