
stat2 = stat2 or {}
stat2_hv = stat2_hv or {}
stat2_mv = stat2_mv or {}
stat2_lv = stat2_lv or {}



-- It shall not be possible for a network to span more than 2000
-- meters (2 kilometers) in any of the 3 dimensions. This allows us
-- to optimize caches by their location in the world. Max is 64!
function stat2.chain_limit(tier)
	if tier == "lv" then
		return 16
	elseif tier == "mv" then
		return 32
	elseif tier == "hv" then
		return 64
	end
	return 0
end



local direction_rules = {
  ["n"] = "z",
  ["s"] = "z",
  ["w"] = "x",
  ["e"] = "x",
  ["u"] = "y",
  ["d"] = "y",
}



-- Invalidate all nearby hubs from a position: NSEW, UD.
-- This should cause them to re-update their routing.
-- This would need to be done if a hub or cable is removed.
stat2.invalidate_hubs =
function(pos, tier)
	for m, n in ipairs({
		{d="n"},
		{d="s"},
		{d="e"},
		{d="w"},
		{d="u"},
		{d="d"},
	}) do
		local p = stat2.find_hub(pos, n.d, tier)
		if p then
			local meta = minetest.get_meta(p)
			for i, j in ipairs({
				{m="np"},
				{m="sp"},
				{m="ep"},
				{m="wp"},
				{m="up"},
				{m="dp"},
			}) do
				meta:set_string(j.m, "DUMMY")
				local owner = meta:get_string("owner")
				net2.clear_caches(p, owner, tier)
			end

			-- Trigger node update.
			_G["stat2_" .. tier].trigger_update(p)
		end
	end
end



-- Find a network hub, starting from a position and continuing in a direction.
-- Cable nodes (with the right axis) may intervene between hubs.
-- This function must return the position of the next hub, if possible, or nil.
stat2.find_hub =
function(pos, dir, tier)
	local meta = minetest.get_meta(pos)

	local p = vector.new(pos.x, pos.y, pos.z)
	local d = stat2.direction_to_vector(dir)

	local station_name = "stat2:" .. tier
	local cable_name = "cb2:" .. tier

	-- Max cable length. +1 because a switching station takes up 1 meter of length.
	local cable_length = cable.get_max_length(tier)+1

	-- Seek a limited number of meters in a direction.
	for i = 1, cable_length, 1 do
		p = vector.add(p, d)
		local node = minetest.get_node(p)
		if node.name == station_name then
			-- Compatible switching station found!
			return p
		elseif node.name == cable_name then
			-- It's a cable node. We need to check its rotation.
			local paxis = stat2.cable_rotation_to_axis(node.param2)
			if paxis then
				local daxis = direction_rules[dir]
				if not daxis or paxis ~= daxis then
					-- Cable has bad axis. Stop scanning.
					return nil
				end
			else
				-- Invalid param2. We stop scanning.
				return nil
			end
		-- Unless these items can automatically update switching stations when removed, we can't allow this.
		--elseif minetest.get_item_group(node.name, "conductor") > 0 and minetest.get_item_group(node.name, "block") > 0 then
			-- Anything that is both in group `conductor` and `block` is treated as a cable node.
			-- This allows cables to pass through walls without requiring ugly holes.
		else
			-- Anything other than a cable node or switching station blocks search.
			return nil
		end
	end
	return nil
end



-- Get a unit vector from a cardinal direction, or up/down.
stat2.direction_to_vector =
function(dir)
	local d = vector.new(0, 0, 0)
	if dir == "n" then
		d.z = 1
	elseif dir == "s" then
		d.z = -1
	elseif dir == "w" then
		d.x = -1
	elseif dir == "e" then
		d.x = 1
	elseif dir == "u" then
		d.y = 1
	elseif dir == "d" then
		d.y = -1
	else
		return nil
	end
	return d
end



local param2_rules = {
  [0] = "x",
  [1] = "z",
  [2] = "x",
  [3] = "z",

  [4] = "x",
  [5] = "y",
  [6] = "x",
  [7] = "y",

  [8] = "x",
  [9] = "y",
  [10] = "x",
  [11] = "y",

  [12] = "y",
  [13] = "z",
  [14] = "y",
  [15] = "z",

  [16] = "y",
  [17] = "z",
  [18] = "y",
  [19] = "z",

  [20] = "x",
  [21] = "z",
  [22] = "x",
  [23] = "z",
}



-- Get cable axis alignment from a param2 value.
-- Cable nodes must have nodeboxes that match this.
-- All cable nodes must align to the same axis.
stat2.cable_rotation_to_axis =
function(param2)
  if param2 >= 0 and param2 <= 23 then
    return param2_rules[param2]
  end
end



stat2.refresh_hubs =
function(pos, tier)
  local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	local changed = false
  for k, v in ipairs({
    {n="n", m="np"},
    {n="s", m="sp"},
    {n="e", m="ep"},
    {n="w", m="wp"},
    {n="u", m="up"},
    {n="d", m="dp"},
  }) do
    local p = stat2.find_hub(pos, v.n, tier)
		local p2 = meta:get_string(v.m)
		local p3 = ""
		if p then
			p3 = minetest.pos_to_string(p)
		end
		if p2 ~= p3 then
			changed = true
			-- Something changed, so we'll need to clear the caches.
		end
    if p then
			local m = minetest.get_meta(p)
			if m:get_string("owner") == owner then
				meta:set_string(v.m, minetest.pos_to_string(p))
			else
				meta:set_string(v.m, "DUMMY")
			end
    else
      meta:set_string(v.m, "DUMMY")
    end
  end
	if changed then
		net2.clear_caches(pos, owner, tier)
		nodestore.update_hub_info(pos)
	end
end



-- Create copies of these functions by tier.
for k, v in ipairs({
  {tier="hv", up="HV"},
  {tier="mv", up="MV"},
  {tier="lv", up="LV"},
}) do
  -- Which function table are we operating on?
  local functable = _G["stat2_" .. v.tier]

  functable.update_infotext_and_formspec =
  function(pos)
    local meta = minetest.get_meta(pos)

    local formspec =
      "size[6,4.5]" ..
      default.formspec.get_form_colors() ..
      default.formspec.get_form_image() ..
      default.formspec.get_slot_colors()

    formspec = formspec ..
			"label[0,0.5;Routing Controls]"

		local routing = "Routing: ["
		for m, n in ipairs({
			{d="n", n="N", x=0, y=1, m="np", e="ne"},
			{d="s", n="S", x=1, y=1, m="sp", e="se"},
			{d="e", n="E", x=2, y=1, m="ep", e="ee"},
			{d="w", n="W", x=3, y=1, m="wp", e="we"},
			{d="u", n="U", x=4, y=1, m="up", e="ue"},
			{d="d", n="D", x=5, y=1, m="dp", e="de"},
		}) do
			-- Determine valid routing values.
      local p = minetest.string_to_pos(meta:get_string(n.m))
			local c = meta:get_int(n.e)

			local e = ""
			local r = ""
			local x = "x"

      if not p then
				e = "!"
      end
			if c == 1 then
				x = "o"
				r = n.n
				if not p then
					r = "!"
				end
			end

			routing = routing .. r
			formspec = formspec ..
				"button[" .. n.x .. "," .. n.y .. ";1,1;" ..
				n.d .. ";" .. n.n .. " (" .. x .. e .. ")]"
		end
		routing = routing .. "]"

		formspec = formspec ..
			"label[0,2.5;" .. minetest.formspec_escape(routing) .. "]" ..
			"button[0,3;3,1;autoconf;Auto Route & Prune]"

		local infotext = v.up .. " Cable Box\n" .. routing

    meta:set_string("formspec", formspec)
		meta:set_string("infotext", infotext)
  end

  functable.trigger_update =
  function(pos)
    local timer = minetest.get_node_timer(pos)
    if not timer:is_started() then
      timer:start(1.0)
    end
		local meta = minetest.get_meta(pos)
		meta:set_int("needupdate", 1)
  end

  functable.on_punch =
  function(pos, node, puncher, pointed_thing)
    functable.trigger_update(pos)
		functable.update_infotext_and_formspec(pos)

		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")

		if owner == "" then
			meta:set_string("owner", puncher:get_player_name())
		end

		functable.privatize(meta)
  end

  functable.can_dig =
  function(pos, player)
		return true
  end

  functable.on_metadata_inventory_move =
  function(pos, from_list, from_index, to_list, to_index, count, player)
    functable.trigger_update(pos)
  end

  functable.on_metadata_inventory_put =
  function(pos, listname, index, stack, player)
    functable.trigger_update(pos)
  end

  functable.on_metadata_inventory_take =
  function(pos, listname, index, stack, player)
    functable.trigger_update(pos)
  end

  functable.allow_metadata_inventory_put =
  function(pos, listname, index, stack, player)
		return 0
  end

  functable.allow_metadata_inventory_move =
  function(pos, from_list, from_index, to_list, to_index, count, player)
    return 0
  end

  functable.allow_metadata_inventory_take =
  function(pos, listname, index, stack, player)
		return 0
  end

  functable.on_construct =
  function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("buffer", 1)

		meta:set_string("np", "DUMMY")
		meta:set_string("sp", "DUMMY")
		meta:set_string("ep", "DUMMY")
		meta:set_string("wp", "DUMMY")
		meta:set_string("up", "DUMMY")
		meta:set_string("dp", "DUMMY")
		meta:set_string("ne", "DUMMY")
		meta:set_string("se", "DUMMY")
		meta:set_string("ee", "DUMMY")
		meta:set_string("we", "DUMMY")
		meta:set_string("ue", "DUMMY")
		meta:set_string("de", "DUMMY")
		meta:set_string("owner", "DUMMY")
		meta:set_string("nodename", "DUMMY")
		meta:set_int("needupdate", 0)

		functable.privatize(meta)
  end

	functable.privatize = function(meta)
		meta:mark_as_private({
			"needupdate",
			"owner",
			"nodename",
			"np", "sp", "wp", "ep", "up", "dp",
			"ne", "se", "we", "ee", "ue", "de",
		})
	end

  functable.on_destruct =
  function(pos)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		stat2.invalidate_hubs(pos, v.tier)
		net2.clear_caches(pos, owner, v.tier)
		nodestore.del_node(pos)
  end

  functable.on_blast =
  function(pos, intensity)
    local drops = {}
    drops[#drops+1] = "stat2:" .. v.tier
    minetest.remove_node(pos)
    return drops
  end

  functable.on_timer =
  function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		if meta:get_int("needupdate") == 1 then
			stat2.refresh_hubs(pos, v.tier)
			functable.update_infotext_and_formspec(pos)
			meta:set_int("needupdate", 0)
		end
  end

  functable.after_place_node =
  function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name())
		meta:set_string("nodename", minetest.get_node(pos).name)

		-- All routing allowed by default.
		-- But player can still manually configure.
		-- This gives most options with least hassle.
		for k, v in ipairs({
			{m="ne"},
			{m="se"},
			{m="ee"},
			{m="we"},
			{m="ue"},
			{m="de"},
		}) do
			meta:set_int(v.m, 1)
		end

		local owner = meta:get_string("owner")
		stat2.invalidate_hubs(pos, v.tier)
		stat2.refresh_hubs(pos, v.tier)
		functable.update_infotext_and_formspec(pos)
		net2.clear_caches(pos, owner, v.tier)
		nodestore.add_node(pos)
  end

	functable.on_receive_fields =
	function(pos, formname, fields, sender)
		local pname = sender:get_player_name()
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")

		if fields.quit then
			return
		end

		-- Check authorization.
		if pname ~= owner and not gdac.player_is_admin(pname) then
			minetest.chat_send_player(pname, "# Server: No authorization to modify cable box.")
			easyvend.sound_error(pname)
			return
		end

		for k, v in ipairs({
			{d="n", m="np", e="ne"},
			{d="s", m="sp", e="se"},
			{d="e", m="ep", e="ee"},
			{d="w", m="wp", e="we"},
			{d="u", m="up", e="ue"},
			{d="d", m="dp", e="de"},
		}) do
			if fields[v.d] then
				local enabled = meta:get_int(v.e)
				if enabled == 0 then
					enabled = 1
				else
					enabled = 0
				end
				meta:set_int(v.e, enabled)
			end
		end

		if fields.autoconf then
			for k, v in ipairs({
				{n="ne", m="np"},
				{n="se", m="sp"},
				{n="ee", m="ep"},
				{n="we", m="wp"},
				{n="ue", m="up"},
				{n="de", m="dp"},
			}) do
				local p = minetest.string_to_pos(meta:get_string(v.m))
				if p then
					meta:set_int(v.n, 1)
				else
					meta:set_int(v.n, 0)
				end
			end
			meta:set_int("needupdate", 1)
		end

		functable.update_infotext_and_formspec(pos)
		functable.trigger_update(pos)
	end
end



-- One-time initialization.
if not stat2.run_once then
  for k, v in ipairs({
    {tier="hv", name="HV"},
    {tier="mv", name="MV"},
    {tier="lv", name="LV"},
  }) do
    -- Which function table are we operating on?
    local functable = _G["stat2_" .. v.tier]

		local nodebox = {
			{2, 2, 2, 14, 14, 14}, -- Inner box.

			-- Front face.
			{0, 0, 0, 4, 16, 4},
			{12, 0, 0, 16, 16, 4},
			{0, 12, 0, 16, 16, 4},
			{0, 0, 0, 16, 4, 4},

			-- Back face.
			{0, 0, 12, 4, 16, 16},
			{12, 0, 12, 16, 16, 16},
			{0, 12, 12, 16, 16, 16},
			{0, 0, 12, 16, 4, 16},

			-- Left face.
			{0, 12, 0, 4, 16, 16},
			{0, 0, 0, 4, 4, 16},

			-- Right face.
			{12, 12, 0, 16, 16, 16},
			{12, 0, 0, 16, 4, 16},
		}
		for k, v in ipairs(nodebox) do
			for m, n in ipairs(v) do
				local p = nodebox[k][m]
				p = p / 16
				p = p - 0.5
				nodebox[k][m] = p
			end
		end

    minetest.register_node(":stat2:" .. v.tier, {
			drawtype = "nodebox",
      description = v.name .. " Cable Box\n\nBox resistance limit: " .. stat2.chain_limit(v.tier) .. ".\nCables do not turn corners by themselves.\nCable boxes allow them to do so.",
      tiles = {"switching_station_" .. v.tier .. ".png"},

      groups = utility.dig_groups("machine"),
      node_box = {
        type = "fixed",
        fixed = nodebox,
      },
			selection_box = {
				type = "fixed",
				fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
			},

			paramtype = "light",
      paramtype2 = "facedir",
      is_ground_content = false,
      sounds = default.node_sound_metal_defaults(),

      on_rotate = function(...)
				return screwdriver.rotate_simple(...) end,
      on_punch = function(...)
        return functable.on_punch(...) end,
      can_dig = function(...)
        return functable.can_dig(...) end,
      on_timer = function(...)
        return functable.on_timer(...) end,
      on_construct = function(...)
        return functable.on_construct(...) end,
      after_place_node = function(...)
        return functable.after_place_node(...) end,
      on_blast = function(...)
        return functable.on_blast(...) end,
      on_destruct = function(...)
        return functable.on_destruct(...) end,
      on_metadata_inventory_move = function(...)
        return functable.on_metadata_inventory_move(...) end,
      on_metadata_inventory_put = function(...)
        return functable.on_metadata_inventory_put(...) end,
      on_metadata_inventory_take = function(...)
        return functable.on_metadata_inventory_take(...) end,
      allow_metadata_inventory_put = function(...)
        return functable.allow_metadata_inventory_put(...) end,
      allow_metadata_inventory_move = function(...)
        return functable.allow_metadata_inventory_move(...) end,
      allow_metadata_inventory_take = function(...)
        return functable.allow_metadata_inventory_take(...) end,
			on_receive_fields = function(...)
				return functable.on_receive_fields(...) end,
    })
  end

  local c = "stat2:core"
  local f = switching_station.modpath .. "/stat2.lua"
  reload.register_file(c, f, false)

	stat2.run_once = true
end
