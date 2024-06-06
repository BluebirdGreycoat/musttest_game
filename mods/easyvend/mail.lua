
easyvend.purchase_reports = {}
local tb = easyvend.purchase_reports

local RECORD_MERGE_TIME = 60 * 10
local MAIL_FROM = "SERVER"
local SUBJECT_SELL = "Vendor Sold Stuff"
local SUBJECT_BUY = "Depositor Bought Stuff"
local SUBJECT_OFF = "Shop Closed"
local MSG_SELL = "You sold %s from your vending machine near \"%s\" at %s."
local MSG_BUY = "You bought %s through your depositing machine near \"%s\" at %s."
local MSG_OFF = "Your %s %s near \"%s\" at %s is closed."

-- Get the nearest named region, if there is one.
local function nearest_city(pos)
	local cityinfo = "outlands"
	local cityblock = city_block:nearest_named_region(pos)
	if cityblock and cityblock[1] and cityblock[1].area_name then
		cityinfo = cityblock[1].area_name
	end
	return cityinfo
end

-- Check if this record was already recorded during this session.
-- A record is considered "same" if positions are the same.
-- It is necessarily the case that vendors and depositors MUST have different
-- positions, likewise different items require machines with different positions.
-- BUT! If the current time is much newer than the last record, we can record it.
local function record_exists(data)
	for k, v in ipairs(tb) do
		if vector.equals(v.pos, data.pos) then
			if os.time() < (v.record_time + RECORD_MERGE_TIME) then
				return true
			end
		end
	end
end



-- To be called when a purchase is made.
function easyvend.record_purchase(data)
	if record_exists(data) then
		return
	end

	tb[#tb + 1] = data
	tb[#tb].record_time = os.time()

	local idef = minetest.registered_items[data.item]
	if not idef or not idef.description then
		return
	end

	local to = data.owner
	local message = MSG_SELL:format(
		utility.get_short_desc(idef.description),
		nearest_city(data.pos),
		rc.pos_to_namestr(data.pos)
	)

	email.send_mail_single(MAIL_FROM, to, SUBJECT_SELL, message)
end

-- To be called when a deposit is made.
function easyvend.record_deposit(data)
	if record_exists(data) then
		return
	end

	tb[#tb + 1] = data
	tb[#tb].record_time = os.time()

	local idef = minetest.registered_items[data.item]
	if not idef or not idef.description then
		return
	end

	local to = data.owner
	local message = MSG_BUY:format(
		utility.get_short_desc(idef.description),
		nearest_city(data.pos),
		rc.pos_to_namestr(data.pos)
	)

	email.send_mail_single(MAIL_FROM, to, SUBJECT_BUY, message)
end

-- To be called when a vending machine is disabled (usually because out of stock).
function easyvend.record_disable(data)
	tb[#tb + 1] = data
	tb[#tb].record_time = os.time()

	local idef = minetest.registered_items[data.item]
	if not idef or not idef.description then
		return
	end

	local to = data.owner
	local message = MSG_OFF:format(
		utility.get_short_desc(idef.description),
		data.machine_type,
		nearest_city(data.pos),
		rc.pos_to_namestr(data.pos)
	)

	email.send_mail_single(MAIL_FROM, to, SUBJECT_OFF, message)
end
