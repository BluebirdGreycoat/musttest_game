
function serveressentials.get_short_stack_desc(stack)
	local def = minetest.registered_items[stack:get_name()]
	local meta = stack:get_meta()
	local description = meta:get_string("description")
	if description ~= "" then
		return utility.get_short_desc(description):trim()
	elseif def and def.description then
		return utility.get_short_desc(def.description):trim()
	end
end

-- Get the number of seconds until the next schedualed reset of the Outback.
-- This is also used by the calendar item.
function serveressentials.get_outback_timeout()
	local meta = serveressentials.modstorage
	local stime = meta:get_string("outback_reset_time")

	-- If timestamp is missing, then initialize it to the current time.
	if not stime or stime == "" then
		stime = tostring(os.time())
		meta:set_string("outback_reset_time", stime)
	end

	local time = tonumber(stime) -- Time of last reset (or initialization).
	local days = serveressentials.reset_timeout
	local timeout = 60 * 60 * 24 * days
	local now = os.time() -- Current time.
	local later = time + timeout -- Time of next reset.

	return (later - now)
end

function serveressentials.get_midfeld_timeout()
	local meta = serveressentials.modstorage
	local stime = meta:get_string("midfeld_reset_time")

	-- If timestamp is missing, then initialize it to the current time.
	if not stime or stime == "" then
		stime = tostring(os.time())
		meta:set_string("midfeld_reset_time", stime)
	end

	local time = tonumber(stime) -- Time of last reset (or initialization).
	local days = serveressentials.midfeld_reset_timeout
	local timeout = 60 * 60 * 24 * days
	local now = os.time() -- Current time.
	local later = time + timeout -- Time of next reset.

	return (later - now)
end
