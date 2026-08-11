
-- Here's my idea for determining how protections relate to cityblocks.
-- The goal is to determine if a specific protector is "slaved" to a cityblock.
-- The following conditions have to be met:
--   1. The protector is within the cityblock's area of control.
--   2. The protector is newer than the cityblock.
--   3. The owner of the protector has not logged in for 180 days.
--   4. The owner of the cityblock has at least 50k build XP.
--   5. The owner of the cityblock has 50k xp MORE than the owner of the prot.
--   6. The owner of the prot is not an admin.
--   7. The owner of the prot has < 10k build XP.
--   8. If the prot has members, all members must pass these conditions.
--   9. All other cityblocks in the area of control must be owned by the owner.
--      OR, all other cityblocks must be newer that this one.
-- The intended purpose of these conditions is to allow city mayors to control
-- (even revoke) protections for low-quality builders/builds within their area
-- of control, while keeping the potential for administrative abuse as low as
-- possible.

local LAST_LOGIN_DAYS = 60 * 60 * 24 * 180
local PROTECTOR_PLACETIME_OFFSET = 60 * 60 * 24 * 3
local BUILDXP_FOR_MAYOR = 20000
local CITYBLOCK_BOROUGH_RADIUS = 22 -- Covers a 45x45x45 area.

local PROTECTOR_NAMES = {
	"protector:protect",
	"protector:protect2",
	"protector:protect3",
	"protector:protect4",
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

local function get_protector_slave_status(prot_pos, city_pos)
	local rpos = vector.subtract(prot_pos, city_pos)
	local D = CITYBLOCK_BOROUGH_RADIUS

	-- All must be true to pass.
	local in_cityblock_area = false
	local protector_is_newer = false
	local protowner_is_away = false

	-- Check if the protector is in the city block's area of control.
	if rpos.x >= -D and rpos.x <= D then
		if rpos.y >= -D and rpos.y <= D then
			if rpos.z >= -D and rpos.z <= D then
				in_cityblock_area = true
			end
		end
	end

	local meta = minetest.get_meta(prot_pos)
	local owner = meta:get_string("owner")
	local pauth = minetest.get_auth_handler().get_auth(owner)

	-- Check if the protector owner is away for extended time.
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
	local cblock = city_block.get_block(city_pos)
	local city_time = cblock.time -- or nil.
	-- Special: if the cityblock age is unknown and is owned by the admin,
	-- then it is the oldest thing on the server.
	if cblock and not city_time then
		if cblock.owner and gdac.player_is_admin(cblock.owner) then
			city_time = 0
		end
	end
	if cblock and city_time then
		local placedate = meta:get_string("placedate")
		local placetime = tonumber(meta:get_string("placetime")) -- May be nil.

		-- Convert placetime to placedate if we have to.
		if placetime == 0 or placetime == nil and placedate ~= "" then
			placetime = parse_protector_placedate(placedate)
		end

		-- Protections owned by admin are maximally old.
		if gdac.player_is_admin(owner) then
			placetime = nil
		end

		if placetime and placetime ~= 0 then
			-- Protector must be significantly newer.
			placetime = placetime + PROTECTOR_PLACETIME_OFFSET
			if placetime > city_time then
				protector_is_newer = true
			end
		end
	end

	if in_cityblock_area and protector_is_newer and protowner_is_away then
		return 1
	end
	return 0
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
				if not owner_set[owner] then
					owner_set[owner] = 1
				else
					owner_set[owner] = owner_set[owner] + 1
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
		{h=0.5, label="Find Claims", name="protector_scan", tooltip="Find all protectors near cityblock.", type="button", w=2, x=0.5, y=4.9},
		{h=0.5, label="Force Expiry", name="force_expiry", style={bgcolor="red"}, tooltip="This action cannot be undone.", type="button", w=2, x=6.1, y=4.9},
		{h=0.5, label="Add M. Self", name="become_member", tooltip="Add yourself as a member of this protector.", type="button", w=2, x=8.2, y=4.9},
		{color="#101010", h=0.5, type="box", w=9.7, x=0.5, y=5.7},
		{FORMID="info_message", h=0.3, text="No info.", type="label", w=9.5, x=0.6, y=5.8},
	},
}



function city_block.create_mayor_formspec(pos, pname, blockdata)
	local guiobj = city_block.guiobjs[pname]
	if not guiobj then
		guiobj = formspec.create_gui_object(FORMTABLE)
		city_block.guiobjs[pname] = guiobj

		-- Add some additional methods.
		function guiobj:set_message(msg)
			self:get_control_by_id("info_message").text = (msg or "No info.")
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

	if xp.get_xp(pname, "buildxp") < BUILDXP_FOR_MAYOR then
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
		city_block.guiobjs[pname] = nil
		return true
	end

	if fields.protector_scan then
		do_protector_scan(pos, pname, guiobj)
		guiobj:get_control_by_name("player_list").selected = -1 -- Apparently nil doesn't work.
		guiobj:get_control_by_name("block_list").selected = -1
	end

	if fields.player_list then
		local tab = minetest.explode_textlist_event(fields.player_list)
		if tab.type == "CHG" and tab.index then
			guiobj:get_control_by_name("player_list").selected = tab.index
			guiobj:get_control_by_name("block_list").selected = -1

			-- Update contents of the block list whenever playername selected.
			local data = guiobj:get_usertable().datalist or {}
			local prots = guiobj:get_usertable().protlist or {}
			local info = data[guiobj:get_control_by_name("player_list").selected]

			local list = {}
			if info then
				for _, vpos in ipairs(prots) do
					local node = minetest.get_node(vpos)
					local meta = minetest.get_meta(vpos)
					if is_protector_name(node.name) or is_expired_protector_name(node.name) then
						if meta:get_string("owner") == info.owner then
							local p = vector.subtract(vpos, pos)
							local color = get_protector_slave_status_color(vpos, pos)
							local str = ("%s%s"):format(color, minetest.pos_to_string(p))
							table.insert(list, str)
						end
					end
				end
			end
			--table.insert(list, "#55FF55Green item")
			guiobj:get_control_by_name("block_list").itemlist = list
		end
	end

	minetest.show_formspec(pname, "city_block:mayor", guiobj:to_formspec())
	return true
end
