
if not minetest.global_exists("countdown") then countdown = {} end
countdown.modpath = minetest.get_modpath("hb4")
countdown.quit = false

local color = minetest.get_color_escape_sequence("#ffff00")

function countdown.step(data)
	-- Halt when done.
	if countdown.quit then
		return
	end

	data = data or {hour = -1, min = -1, sec = -1}

	-- Current time, as a number.
	local ct = os.time()
	local cd = os.date("!*t")

	-- Datetime of next shutdown.
	assert(countdown.time)
	local nd = countdown.time
	local nt = os.time(nd)

	-- If our restart time is in the past, we're done.
	if nt <= ct then
		local message = "# Server: RESTART IMMINENT - WAITING FOR OS SIGNAL."
		chat_logging.log_server_message(message)
		minetest.chat_send_all(color .. message)
		countdown.quit = true
		return
	end

	assert(nt >= ct)
	local rt = os.difftime(nt, ct)
	local rd = os.date("!*t", rt)

	local report = false
	local delay = 60

	-- Calculate how long until next public message.
	do
		-- Report on every hour change.
		if data.hour ~= rd.hour then
			report = true
		end

		-- Report every minute once there are 10 or less minutes.
		if rd.hour == 0 and rd.min <= 10 and data.min ~= rd.min then
			report = true
		end

		-- Report every second of the last 20 seconds.
		if rd.hour == 0 and rd.min == 0 and rd.sec <= 20 then
			report = true
		end

		-- Reduce delay to 5 seconds once there are 10 minutes remaining to restart.
		if rd.hour == 0 and rd.min <= 10 then
			delay = 5
		end

		-- And reduce to 1 second when there are 20 or less seconds remaining.
		if rd.hour == 0 and rd.min == 0 and rd.sec <= 20 then
			delay = 1
		end

		-- Record time of last timecheck.
		data.hour = rd.hour
		data.min = rd.min
		data.sec = rd.sec
	end

	if report then
		local message = "# Server: Nightly restart in: " .. string.format("%02d:%02d:%02d", rd.hour, rd.min, rd.sec) .. "."
		chat_logging.log_server_message(message)
		minetest.chat_send_all(color .. message)
	end

	-- Wait for next check.
	minetest.after(delay, countdown.step, data)
end

if not countdown.registered then
	-- Calculate time to next shutdown.
	local cd = os.date("!*t")
	-- Should be 01:00:00 of next day UTC (1 hour after midnight, CST).
	local nd = table.copy(cd)
	nd.day = nd.day + 1
	nd.hour = 6
	nd.min = 0
	nd.sec = 0
	nd = os.date("!*t", os.time(nd))
	countdown.time = nd

	minetest.after(60, countdown.step, {})
	countdown.registered = true
end

