
function serveressentials.check_outback_reset()
	local meta = serveressentials.modstorage
	local stime = meta:get_string("outback_reset_time")

	-- If timestamp is missing, then initialize it to the current time.
	-- Outback reset will be schedualed after the timeout.
	if not stime or stime == "" then
		stime = tostring(os.time())
		meta:set_string("outback_reset_time", stime)

		-- Note: we reach here only when a new world is first started.
		serveressentials.rebuild_outback()
		return
	end

	local time = tonumber(stime) -- Time of last reset (or initialization).
	local days = serveressentials.reset_timeout -- Timeout in days.
	local timeout = 60 * 60 * 24 * days
	local now = os.time() -- Current time.
	local later = time + timeout -- Time of next reset.

	if now >= later then
		stime = tostring(later)
		meta:set_string("outback_reset_time", stime)

		serveressentials.rebuild_outback()
		minetest.chat_send_all("# Server: The desert wind ceases to blow across the Outback.")
		minetest.chat_send_all("# Server: When it resumes, there is nothing left of what went before.")
	end
end
-- After all mods loaded and server running.
minetest.after(0, function() serveressentials.check_outback_reset() end)



function serveressentials.check_midfeld_reset()
	local meta = serveressentials.modstorage
	local stime = meta:get_string("midfeld_reset_time")

	-- If timestamp is missing, then initialize it to the current time.
	-- Outback reset will be schedualed after the timeout.
	if not stime or stime == "" then
		stime = tostring(os.time())
		meta:set_string("midfeld_reset_time", stime)

		-- Note: we reach here only when a new world is first started.
		serveressentials.rebuild_gaterealm()
		return
	end

	local time = tonumber(stime) -- Time of last reset (or initialization).
	local days = serveressentials.midfeld_reset_timeout -- Timeout in days.
	local timeout = 60 * 60 * 24 * days
	local now = os.time() -- Current time.
	local later = time + timeout -- Time of next reset.

	if now >= later then
		stime = tostring(later)
		meta:set_string("midfeld_reset_time", stime)

		serveressentials.rebuild_gaterealm()
		minetest.chat_send_all("# Server: The fog of time settles on Midfeld.")
		minetest.chat_send_all("# Server: When it lifts, all is as it was at the beginning.")
	end
end
-- After all mods loaded and server running.
minetest.after(0, function() serveressentials.check_midfeld_reset() end)
