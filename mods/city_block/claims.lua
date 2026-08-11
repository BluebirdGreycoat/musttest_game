
-- Here's my idea for determining how protections relate to cityblocks.
-- The goal is to determine if a specific protector is "slaved" to a cityblock.
-- The following conditions have to be met:
--   1. [X] The protector is within the cityblock's area of control.
--   2. [X] The protector is newer than the cityblock.
--   3. [X] The owner of the protector has not logged in for 180 days.
--   4. [X] The owner of the cityblock has at least 50k build XP.
--   5. [X] The owner of the cityblock has 50k xp MORE than the owner of the prot.
--   6. [X] The owner of the prot is not an admin.
--   7. [X] If the prot has members, all members must pass these conditions.
--      [X] If cityblock owner is a member, skip checks for that member.
--   8. [X] All other cityblocks in the area of control must be owned by the owner.
--      [X] OR, all other cityblocks must be newer that this one.
-- The intended purpose of these conditions is to allow city mayors to control
-- (even revoke) protections for low-quality builders/builds within their area
-- of control, while keeping the potential for administrative abuse as low as
-- possible.

local LAST_LOGIN_DAYS = 60 * 60 * 24 * 180
local PROTECTOR_PLACETIME_OFFSET = 60 * 60 * 24 * 3
city_block.BUILDXP_FOR_MAYOR = 20000
local MAYOR_MINIMUM_BUILDXP = 30000
local CITYBLOCK_BOROUGH_RADIUS = 22 -- Covers a 45x45x45 area.

local PROTECTOR_NAMES = {
	"protector:protect",
	"protector:protect2",
	"protector:protect3",
	"protector:protect4",
}

local DISPLAY_ENTITY_NAME = {
	["protector:protect"] = "protector:display",
	["protector:protect2"] = "protector:display",
	["protector:protect3"] = "protector:display_small",
	["protector:protect4"] = "protector:display_small",
}

local function is_protector_name(name)
	for k, v in ipairs(PROTECTOR_NAMES) do
		if name == v then
			return true
		end
	end
end

local EXPIRED_PROTECTOR_NAMES = {
	"protector:expired1",
	"protector:expired2",
}

local function is_expired_protector_name(name)
	for k, v in ipairs(EXPIRED_PROTECTOR_NAMES) do
		if name == v then
			return true
		end
	end
end

local NODES_OF_INTEREST = {
	"protector:protect",
	"protector:protect2",
	"protector:protect3",
	"protector:protect4",
	"city_block:cityblock",
	"protector:expired1",
	"protector:expired2",
}

local function is_node_of_interest(name)
	for k, v in ipairs(NODES_OF_INTEREST) do
		if name == v then
			return true
		end
	end
end

local CITYBLOCK_NAMES = {
	"city_block:cityblock",
}

local function is_cityblock_name(name)
	for k, v in ipairs(CITYBLOCK_NAMES) do
		if name == v then
			return true
		end
	end
end

-- Grok function.
local function parse_protector_placedate(timestr)
  local year, month, day = timestr:match("^(%d+)/(%d+)/(%d+) UTC$")
  if not year then
    return nil  -- invalid format
  end

  local t = {
    year  = tonumber(year),
    month = tonumber(month),
    day   = tonumber(day),
    hour  = 0,
    min   = 0,
    sec   = 0,
    isdst = false
  }

  -- Current timezone offset (seconds to add to a UTC time to get local time)
  local now = os.time()
  local offset = now - os.time(os.date("!*t", now))

  -- os.time(t) treats the fields as local time, so adjust to produce
  -- the Unix timestamp for 00:00:00 UTC on the given date
  return os.time(t) + offset
end

local function get_protector_timestamp(meta)
	local placedate = meta:get_string("placedate")
	local placetime = tonumber(meta:get_string("placetime")) -- May be nil.

	-- Convert placetime to placedate if we have to.
	if placetime == 0 or placetime == nil and placedate ~= "" then
		placetime = parse_protector_placedate(placedate)
	end

	-- Protections owned by admin are maximally old.
	local owner = meta:get_string("owner")
	if gdac.player_is_admin(owner) then
		placetime = nil
	end

	if placetime and placetime ~= 0 then
		return placetime
	end
end

--- Count unique content IDs in the region [minp, maxp]
--- @param minp vector
--- @param maxp vector
--- @return table  -- { [content_id] = count, ... }
function count_content_ids(minp, maxp)
	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(minp, maxp)
	local data = vm:get_data()
	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}

	local counts = {}

	-- Iterate only the requested region (read_from_map may emerge a larger mapblock-aligned volume)
	for z = minp.z, maxp.z do
		for y = minp.y, maxp.y do
			for x = minp.x, maxp.x do
				local vi = area:index(x, y, z)
				local cid = data[vi]
				counts[cid] = (counts[cid] or 0) + 1
			end
		end
	end

	return counts
end

local PROTECTOR_RADIUS = {
	["protector:protect"] = 5,
	["protector:protect2"] = 5,
	["protector:protect3"] = 3,
	["protector:protect4"] = 3,
}

local function calc_costinfo_for_protector(prot_pos)
	local prot_node = minetest.get_node(prot_pos)
	local prot_meta = minetest.get_meta(prot_pos)
	if not is_protector_name(prot_node.name) then
		return 0
	end
	if prot_meta:get_string("owner") == "" then
		return 0
	end
	local R = PROTECTOR_RADIUS[prot_node.name]
	if not R then
		return 0
	end

	local minp = vector.subtract(prot_pos, R)
	local maxp = vector.add(prot_pos, R)
	local counts = count_content_ids(minp, maxp)

	-- Find num unique content IDs.
	local count = 0
	for k, v in pairs(counts) do
		count = count + 1
	end

	local multiplier = 100
	if count > 10 then
		multiplier = 500
	elseif count > 20 then
		multiplier = 1000
	elseif count > 30 then
		multiplier = 1500
	end

	local cost = count * multiplier
	return count, cost
end

-- Returns 1 if protector can be controled by the cityblock.
-- Returns 2 if protector is expired.
-- Returns 0 if protector is independant.
-- Returns -1 on error (node/meta invalid, etc.).
-- Second return value: string message with explanation.
-- This function has final responsibility for all security checks!
local function get_protector_slave_status(prot_pos, city_pos)
	local rpos = vector.subtract(prot_pos, city_pos)
	local D = CITYBLOCK_BOROUGH_RADIUS

	-- All must be true to pass.
	local in_cityblock_area = false
	local protector_is_newer = false
	local protowner_is_away = false
	local protowner_not_admin = false
	local cityowner_has_xp = false
	local cityowner_has_xp_morethanprot = false
	local cityblocks_all_allow = false
	local protmembers_pass = false

	-- Check if the cityblock is valid.
	local cblock = city_block.get_block(city_pos)
	if not cblock then
		return -1, "Invalid city block."
	end

	-- Check if the protector is in the city block's area of control.
	if rpos.x >= -D and rpos.x <= D then
		if rpos.y >= -D and rpos.y <= D then
			if rpos.z >= -D and rpos.z <= D then
				in_cityblock_area = true
			end
		end
	end

	-- Check if the nodes are actually valid.
	local protnode = minetest.get_node(prot_pos)
	local citynode = minetest.get_node(city_pos)
	if not (is_protector_name(protnode.name) or is_expired_protector_name(protnode.name)) then
		return -1, "Invalid protection node."
	end
	if not is_cityblock_name(citynode.name) then
		return -1, "Invalid city block."
	end
	if is_expired_protector_name(protnode.name) then
		return 2, "Expired protector."
	end

	local meta = minetest.get_meta(prot_pos)
	local owner = meta:get_string("owner")
	if owner == "" then
		return -1, "Protector node lacks owner." -- Don't call get_auth() with an empty string.
	end

	-- If cityblock and protector owner are same, allow control.
	-- Shortcut all remaining checks.
	if cblock.owner and owner == cblock.owner then
		return 1, "Protector and city block owners are same."
	end

	-- Check if protector owner is admin.
	if not gdac.player_is_admin(owner) then
		protowner_not_admin = true
	end

	-- Check if cityblock owner has needed minimum XP.
	-- Also check other XP requirements.
	if cblock.owner then
		local cityXP = xp.get_xp(cblock.owner, "buildxp")
		local protXP = xp.get_xp(owner, "buildxp")
		if cityXP >= MAYOR_MINIMUM_BUILDXP then
			cityowner_has_xp = true
		end
		-- Check if city owner XP is more than twice as much as prot owner XP.
		if cityXP >= (protXP * 2) then
			cityowner_has_xp_morethanprot = true
		end
	end

	-- Check if the protector owner is away for extended time.
	local pauth = minetest.get_auth_handler().get_auth(owner)
	if pauth and pauth.last_login and pauth.last_login ~= -1 then
		local tnow = os.time()
		local tlast = pauth.last_login
		local tdiff = tnow - tlast
		local delay = LAST_LOGIN_DAYS
		if tdiff > delay then
			protowner_is_away = true
		end
	else
		-- Account no longer exists OR 'last_login' was never initialized.
		protowner_is_away = true
	end

	-- Check if the protector is newer than the city block.
	local city_time = cblock.time -- or nil.
	-- Special: if the cityblock is owned by the admin,
	-- then it is the oldest thing on the server.
	if cblock.owner and gdac.player_is_admin(cblock.owner) then
		city_time = 0
	end
	if city_time then
		local placetime = get_protector_timestamp(meta)

		if placetime and placetime ~= 0 then
			-- Protector must be significantly newer.
			placetime = placetime + PROTECTOR_PLACETIME_OFFSET
			if placetime > city_time then
				protector_is_newer = true
			end
		end
	end

	-- Check all neighboring cityblocks for age and ownership.
	-- If the city owner is admin, skip this check.
	if cblock.owner and city_time and not gdac.player_is_admin(cblock.owner) then
		local allblocks = city_block.blocks
		local cityowner = cblock.owner or ""
		local good = true

		for k = 1, #allblocks do
			local block = allblocks[k]
			local bowner = block.owner
			local btime = block.time
			local vpos = block.pos
			local cpos = city_pos
			local r = CITYBLOCK_BOROUGH_RADIUS * 2
			if bowner and gdac.player_is_admin(bowner) then
				btime = 0
			end
			if bowner and btime and vpos then
				if vpos.x >= (cpos.x - r) and vpos.x <= (cpos.x + r) and
					vpos.z >= (cpos.z - r) and vpos.z <= (cpos.z + r) and
					vpos.y >= (cpos.y - r) and vpos.y <= (cpos.y + r) then
					-- All other city blocks must be owned by this city owner, or be
					-- yonger than the current city block.
					-- Note: ownername check is especially needed because self is always
					-- included in the array of blocks we're looking at.
					if not (bowner == cityowner or btime <= city_time) then
						good = false
						break
					end
				end
			end
		end

		if good then
			cityblocks_all_allow = true
		end
	end
	-- For testing.
	--cityblocks_all_allow = true

	-- Check if protector has members, and if all members pass.
	local memberlist = protector.get_member_list(meta)
	if memberlist and #memberlist > 0 and cblock.owner then
		local cityowner = cblock.owner or ""
		local good = true

		for _, membername in ipairs(memberlist) do
			if cityowner ~= membername then	-- Skip checks for the cityblock owner, if a member.
				-- Check if member logged in recently.
				local pauth = minetest.get_auth_handler().get_auth(membername)
				if pauth and pauth.last_login and pauth.last_login ~= -1 then
					local tnow = os.time()
					local tlast = pauth.last_login
					local tdiff = tnow - tlast
					local delay = LAST_LOGIN_DAYS
					if tdiff <= delay then
						good = false
					end
				else
					-- Account no longer exists OR 'last_login' was never initialized.
					good = false
				end

				if gdac.player_is_admin(membername) then
					good = false
				end

				local cityXP = xp.get_xp(cityowner, "buildxp")
				local memberXP = xp.get_xp(membername, "buildxp")
				-- Check if city owner XP is more than twice as much as member XP.
				if cityXP < (memberXP * 2) then
					good = false
				end
			end
		end

		if good then
			protmembers_pass = true
		end
	else
		-- No members.
		protmembers_pass = true
	end

	-- For exclusively testing neighbor city block age/ownership conditions.
	--[[
	cityowner_has_xp = true
	cityowner_has_xp_morethanprot = true
	protowner_not_admin = true
	protowner_is_away = true
	protector_is_newer = true
	protmembers_pass = true
	--]]

	if in_cityblock_area
			and protector_is_newer
			and protowner_is_away
			and protowner_not_admin
			and cityowner_has_xp
			and cityowner_has_xp_morethanprot
			and cityblocks_all_allow
			and protmembers_pass
	then
		return 1, "Protector is enslaved." -- Be extra, extra offensive to "sensitive" people.
	end
	return 0, "Protector is independant."
end

local function get_protector_slave_status_color(prot_pos, city_pos)
	local status = get_protector_slave_status(prot_pos, city_pos)

	if status == 0 then
		return "#FFFFFF" -- White. Protector is normal (or independant) claim.
	elseif status == 1 then
		return "#55FF55" -- Green. Protector is slaved to the cityblock.
	end
	return "#FF5555" -- Red. Use this for already-expired protectors.
end



local function do_protector_scan(pos, pname, guiobj)
	local D = CITYBLOCK_BOROUGH_RADIUS
	local minp = vector.subtract(pos, D)
	local maxp = vector.add(pos, D)

	local prots = minetest.find_nodes_in_area(minp, maxp, NODES_OF_INTEREST)
	if not prots then
		prots = {} -- Nil check.
	end

	local owner_set = {}
	for _, vpos in ipairs(prots) do
		local node = minetest.get_node(vpos)
		local meta = minetest.get_meta(vpos)

		if is_node_of_interest(node.name) then
			if is_protector_name(node.name) or is_expired_protector_name(node.name) then
				local owner = meta:get_string("owner")
				if owner ~= "" then
					if not owner_set[owner] then
						owner_set[owner] = 1
					else
						owner_set[owner] = owner_set[owner] + 1
					end
				end
			else
				-- Is cityblock.
			end
		end
	end

	local owner_list = {}
	local owner_list_data = {}
	for owner, count in pairs(owner_set) do
		table.insert(owner_list, ("%s (%d)"):format(rename.gpn(owner), count))
		table.insert(owner_list_data, {owner=owner, count=count})
	end
	-- Must be an array of strings.
	guiobj:get_control_by_name("player_list").itemlist = owner_list
	guiobj:get_usertable().datalist = owner_list_data
	guiobj:get_usertable().protlist = prots -- All blocks.

	return #prots - 1, -- Always includes self in search, so -1.
		#owner_list
end



local FORMTABLE = {
	size = {x=10.7, y=6.7},
	children = {
		{h=6.7, texture="gui_formbg.png", type="background9", w=10.7, x=0, x1=50, y=0},
		{FORMID="cityblock_age", h=0.3, text="City age: unknown.", type="label", w=9.5, x=0.5, y=0.4},
		{h=0.4, text="Landowners:", type="label", w=3, x=0.5, y=1},
		{h=0.4, text="Properties:", type="label", w=3, x=3.3, y=1},
		{h=0.4, text="Claim Info:", type="label", w=3, x=6.1, y=1},
		{h=3.4, name="player_list", type="textlist", w=2.5, x=0.5, y=1.4},
		{h=3.4, name="block_list", type="textlist", w=2.5, x=3.3, y=1.4},
		{h=3.4, label="", name="claim_infotext", text="", type="textarea", w=4.1, x=6.1, y=1.4},
		{h=0.5, label="Find Claims", name="protector_scan", tooltip="Find all protectors near cityblock.", type="button", w=2.5, x=0.5, y=4.9},
		{h=0.5, label="Show Grid", name="show_protgrid", type="button", w=2.5, x=3.3, y=4.9},
		{h=0.5, label="Force Expiry", name="force_expiry", style={bgcolor="red"}, tooltip="This action cannot be undone.", type="button", w=2, x=6.1, y=4.9},
		{h=0.5, label="Add M. Self", name="become_member", tooltip="Add yourself as a member of this protector.", type="button", w=2, x=8.2, y=4.9},
		{color="#101010", h=0.5, type="box", w=9.7, x=0.5, y=5.7},
		{FORMID="info_message", h=0.3, text="No info.", type="label", w=9.5, x=0.6, y=5.8},
	},
}



function city_block.create_mayor_formspec(pos, pname, blockdata)
	local guiobj = city_block.guiobjs[pname]
	if not guiobj then
		local key = pname .. ":" .. minetest.pos_to_string(pos)
		guiobj = city_block.saved_guiobjs[key]
		city_block.saved_guiobjs[key] = nil
		if not guiobj then
			guiobj = formspec.create_gui_object(FORMTABLE)
		end
		city_block.guiobjs[pname] = guiobj

		-- Add some additional methods.
		if not guiobj.set_message then
			function guiobj:set_message(msg)
				self:get_control_by_id("info_message").text = (msg or "No info.")
			end
		end

		-- Initial message.
		guiobj:set_message("Hello, block captain.")
	end

	do
		local label = guiobj:get_control_by_id("cityblock_age")
		local age = blockdata.time and os.date("!%Y/%m/%d", blockdata.time) or "N/A"
		local owner = blockdata.owner and rename.gpn(blockdata.owner) or "N/A"

		label.text = ("Borough incorporated: %s | Block captain: %s"):format(age, owner)
	end

	return guiobj:to_formspec()
end



function city_block.on_mayor_fields(player, formname, fields)
	if formname ~= "city_block:mayor" then
		return
	end
	if not player or not player:is_player() then
		return
	end

	local pname = player:get_player_name()
	local pos = city_block.formspecs[pname]
	local guiobj = city_block.guiobjs[pname]

	-- Context should have been created in 'on_rightclick'. CSM protection.
	if not pos or not guiobj then
		return true
	end

	-- TODO: Not yet available.
	if not gdac.player_is_admin(pname) then
		return true
	end

	if xp.get_xp(pname, "buildxp") < city_block.BUILDXP_FOR_MAYOR then
		return true
	end

	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")

	-- Form sender must be owner.
	if pname ~= owner then
		return true
	end

	if fields.quit then
		city_block.formspecs[pname] = nil
		local key = pname .. ":" .. minetest.pos_to_string(pos)
		city_block.saved_guiobjs[key] = city_block.guiobjs[pname]
		city_block.guiobjs[pname] = nil
		return true
	end

	if fields.protector_scan then
		local count, count_owners = do_protector_scan(pos, pname, guiobj)
		guiobj:get_control_by_name("player_list").selected = -1 -- Apparently nil doesn't work.
		guiobj:get_control_by_name("block_list").selected = -1
		guiobj:get_control_by_name("claim_infotext").text = nil
		guiobj:set_message(("Scanned claims: %d (unique landowners: %d)"):format(count, count_owners))
	end

	if fields.player_list then
		local tab = minetest.explode_textlist_event(fields.player_list)
		if tab.type == "CHG" and tab.index then
			guiobj:get_control_by_name("player_list").selected = tab.index
			guiobj:get_control_by_name("block_list").selected = -1
			guiobj:get_control_by_name("claim_infotext").text = nil

			-- Update contents of the block list whenever playername selected.
			local data = guiobj:get_usertable().datalist or {}
			local prots = guiobj:get_usertable().protlist or {}
			local info = data[guiobj:get_control_by_name("player_list").selected]

			local list = {}
			local datalist = {}

			if info then
				for _, vpos in ipairs(prots) do
					local node = minetest.get_node(vpos)
					local meta = minetest.get_meta(vpos)
					if is_protector_name(node.name) or is_expired_protector_name(node.name) then
						local vowner = meta:get_string("owner")
						if vowner ~= "" and vowner == info.owner then
							local p = vector.subtract(vpos, pos)
							local color = get_protector_slave_status_color(vpos, pos)
							local str = ("%s%s"):format(color, minetest.pos_to_string(p))
							table.insert(list, str)
							table.insert(datalist, {pos=vpos, owner=info.owner})
						end
					end
				end
			else
				guiobj:set_message("0xDEADBEEF: Bad GUI selection.")
			end

			guiobj:get_control_by_name("block_list").itemlist = list
			guiobj:get_usertable().current_block_list = datalist
		end
	end

	if fields.block_list then
		local tab = minetest.explode_textlist_event(fields.block_list)
		if tab.type == "CHG" and tab.index then
			guiobj:get_control_by_name("block_list").selected = tab.index
		end

		local list = guiobj:get_usertable().current_block_list or {}
		local info = list[tab.index] -- May be nil.
		if info then
			local vpos = info.pos
			local node = minetest.get_node(vpos)
			if is_protector_name(node.name) or is_expired_protector_name(node.name) then
				local is_expired = is_expired_protector_name(node.name)
				local nmeta = minetest.get_meta(vpos)
				local members = protector.get_member_list(nmeta)
				local timestamp = get_protector_timestamp(nmeta) or 0
				local timestr = timestamp ~= 0 and os.date("!%Y/%m/%d", timestamp) or "N/A"
				local areaname = nmeta:get_string("area_name")
				areaname = areaname ~= "" and areaname or "N/A"
				local unique_ids, total_cost = calc_costinfo_for_protector(vpos)

				local last_login = "N/A"
				if not gdac.player_is_admin(info.owner) then -- Admin login time is hidden.
					local pauth = minetest.get_auth_handler().get_auth(info.owner)
					if pauth and pauth.last_login and pauth.last_login ~= -1 then
						last_login = os.date("!%Y/%m/%d", pauth.last_login)
					end
				end

				local textarea = guiobj:get_control_by_name("claim_infotext")
				if textarea then
					local lines = {
						("Registered To: %s"):format(rename.gpn(info.owner)),
						("Last Login: %s"):format(last_login),
						("GPS: %s"):format(minetest.pos_to_string(vector.subtract(vpos, pos))),
						("Date of Claim: %s"):format(timestr),
						("Unique Blocks: %d"):format(unique_ids),
						("Location: %s"):format(areaname),
						("Members: %d"):format(#members),
					}
					if is_expired then
						table.insert(lines, "*** EXPIRED ***")
					else
						for k, v in ipairs(members) do
							table.insert(lines, ("  %d: %s"):format(k, rename.gpn(v)))
						end
						table.insert(lines, ("Reclaim Cost: %d Build XP"):format(total_cost))
					end
					textarea.text = table.concat(lines, '\n')
				end
			else
				guiobj:set_message("0xDEADBEEF: Node is not a protector.")
			end
		else
			guiobj:set_message("0xDEADBEEF: Bad GUI selection.")
		end
	end

	-- Currently allows showing the protector grids of protections user doesn't own.
	-- This may be useful, IDK.
	if fields.show_protgrid then
		local idx = guiobj:get_control_by_name("block_list").selected
		local list = guiobj:get_usertable().current_block_list or {}
		local info = list[idx] -- May be nil.
		if info then
			local vpos = info.pos
			local node = minetest.get_node(vpos)
			local entity = DISPLAY_ENTITY_NAME[node.name]
			if is_protector_name(node.name) and entity then
				if protector.toggle_area_display(vpos, entity) then
					guiobj:set_message("Grid shown.")
				else
					guiobj:set_message("Grid hidden.")
				end
			elseif is_expired_protector_name(node.name) then
				guiobj:set_message("Protector is expired.")
			else
				guiobj:set_message("0xDEADBEEF: Node is not a protector.")
			end
		else
			guiobj:set_message("0xDEADBEEF: Bad GUI selection.")
		end
	end

	if fields.force_expiry then
		local idx = guiobj:get_control_by_name("block_list").selected
		local list = guiobj:get_usertable().current_block_list or {}
		local info = list[idx] -- May be nil.
		if info then
			local vpos = info.pos
			local cpos = pos
			local status, errmsg = get_protector_slave_status(vpos, cpos)
			if status == 1 then
				local oldnode = minetest.get_node(vpos)
				local oldndef = minetest.registered_nodes[oldnode.name] or {}
				if oldndef._expired_protector_name then
					local name = oldndef._expired_protector_name
					local param2 = oldnode.param2
					minetest.swap_node(vpos, {name=name, param2=param2})
					-- Remove infotext. However, we leave the rest of the meta so
					-- we have something to show in the cityblock GUI.
					-- It's harmless since the first thing the protector code looks for
					-- is the nodename.
					minetest.get_meta(vpos):set_string("infotext", "")
					protector.remove_area_display(vpos)
					guiobj:set_message("Protector successfully expired.")
				else
					guiobj:set_message("0xDEADBEEF: Unknown node.")
				end
			elseif status == -1 then
				guiobj:set_message("0xDEADBEEF: Map/GUI data mismatch.")
			else
				guiobj:set_message("Selected protector cannot be managed: " .. errmsg)
			end
		else
			guiobj:set_message("0xDEADBEEF: Bad GUI selection.")
		end
	end

	if fields.become_member then
		local idx = guiobj:get_control_by_name("block_list").selected
		local list = guiobj:get_usertable().current_block_list or {}
		local info = list[idx] -- May be nil.
		if info then
			local vpos = info.pos
			local cpos = pos
			local status, errmsg = get_protector_slave_status(vpos, cpos)
			if status == 1 then
				local vmeta = minetest.get_meta(vpos)
				local vnode = minetest.get_node(vpos)
				local vndef = minetest.registered_nodes[vnode.name] or {}
				if vndef._protector_supports_members then
					if vmeta:get_string("owner") ~= pname then
						if not protector.is_member(vmeta, pname) then
							protector.add_member(vmeta, pname)
							guiobj:set_message("Member list updated.")
						else
							guiobj:set_message("You are already a member of the selected protector.")
						end
					else
						guiobj:set_message("You can't be a member of your own protector.")
					end
				else
					guiobj:set_message("Protector does not support member lists.")
				end
			elseif status == -1 then
				guiobj:set_message("0xDEADBEEF: Map/GUI data mismatch.")
			else
				guiobj:set_message("Selected protector cannot be managed: " .. errmsg)
			end
		else
			guiobj:set_message("0xDEADBEEF: Bad GUI selection.")
		end
	end

	minetest.show_formspec(pname, "city_block:mayor", guiobj:to_formspec())
	return true
end
