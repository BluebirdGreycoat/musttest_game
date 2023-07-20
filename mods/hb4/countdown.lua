
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

	-- Current timestamp, as a number.
	local ct = os.time()

	-- Timestamp of next shutdown.
	local nt = countdown.time

	-- If our restart time is in the past, we're done.
	if nt <= ct then
		local message = "# Server: RESTART IMMINENT - WAITING FOR OS SIGNAL."
		chat_logging.log_server_message(message)
		minetest.chat_send_all(color .. message)
		countdown.quit = true
		return
	end

	-- Calculate remaining time (subtract future time in seconds from current time, also in seconds).
	local rt = nt - ct
	local rd = os.date("!*t", rt)

	local report = false
	local delay = 60

	-- Debug.
	--delay = 10
	--report = true
	--minetest.chat_send_all("Seconds remaining: " .. rt)

	local msgtype = 0

	-- Calculate how long until next public message.
	do
		-- Report on every hour change.
		if data.hour ~= rd.hour then
			report = true
		end

		if rd.hour > 0 then
			-- Report the nearest rounded hour.
			msgtype = 3
		end

		if rd.hour == 0 and rd.min <= 60 then
			msgtype = 2
		end

		-- Report every minute once there are 10 or less minutes.
		if rd.hour == 0 and rd.min <= 10 and data.min ~= rd.min then
			report = true
			delay = 5
			msgtype = 2
		end

		-- Report every second of the last 20 seconds.
		if rd.hour == 0 and rd.min == 0 and rd.sec <= 20 and data.sec ~= rd.sec then
			report = true
			delay = 1
			msgtype = 1
		end

		-- Record time of last timecheck.
		data.hour = rd.hour
		data.min = rd.min
		data.sec = rd.sec
	end

	if report then
		local message = "# Server: Nightly restart in: " .. string.format("%02d:%02d:%02d", rd.hour, rd.min, rd.sec) .. "."

		if msgtype == 1 then
			local p = "s"
			if rd.sec == 1 then p = "" end
			message = "Server: Restart in " .. rd.sec .. " second" .. p .. "."
		elseif msgtype == 2 then
			local p = "s"
			if rd.min == 1 then p = "" end
			message = "Server: Restarting in " .. rd.min .. " minute" .. p .. "."
		elseif msgtype == 3 then
			local h = rd.hour + math.floor((rd.min / 60) + 0.5)
			local p = "s"
			if h == 1 then p = "" end
			message = "Server: Nightly restart in " .. h .. " hour" .. p .. "."
		end

		chat_logging.log_server_message(message)
		minetest.chat_send_all(color .. message)
	end

	-- Wait for next check.
	minetest.after(delay, countdown.step, data)
end

if not countdown.registered then
	-- Get current timestamp as a datetime table.
	local cd = os.date("*t")

	-- Should be 1 hour after midnight, CST. 6 AM UTC.
	local nd = table.copy(cd)
	nd.day = nd.day + 1
	nd.hour = 1
	nd.min = 0
	nd.sec = 0

	-- Store shutdown timestamp as time in seconds in the future.
	countdown.time = os.time(nd)

	local delay = 60

	-- Debug.
	--delay = 10

	minetest.after(delay, countdown.step, {})
	countdown.registered = true
end

