
if not minetest.global_exists("network_whois") then network_whois = {} end
network_whois.modpath = minetest.get_modpath("network_whois")

-- If it's an IPV6-mapped IPV4 address, convert to plain IPV4 to make it easier to read.
local function sanitize_ipv4(ip)
    if ip:find("::ffff:") then
        ip = ip:sub(8)
    end
    return ip
end

local function ip2str(ver)
	if ver == 4 then
		return "IPv4"
	elseif ver == 6 then
		return "IPv6"
	else
		return tostring(ver)
	end
end

function network_whois.display(name, target, formatting)
	local player = minetest.get_player_by_name(target)
	if not player then
		minetest.chat_send_player(name, "# Server: Player <" .. rename.gpn(target) .. "> not found.")
		return
	end

	local info = minetest.get_player_information(target)
	if not info then
		minetest.chat_send_player(name, "# Server: Information for player <" .. rename.gpn(target) .. "> not found!")
		return
	end

	if formatting == "table" then
		local tb = {
			"IP Address:        " .. sanitize_ipv4(info.address),
			"IP Version:        " .. ip2str(info.ip_version),
			"Connection Uptime: " .. info.connection_uptime,
			"Avg RTT:           " .. info.avg_rtt or "N/A",
			"Min RTT:           " .. info.min_rtt or "N/A",
			"Max RTT:           " .. info.max_rtt or "N/A",
			"Protocol Version:  " .. info.protocol_version,
			"Formspec Version:  " .. info.formspec_version,
			"Language Code:     " .. info.lang_code or "N/A",
			"Login Name:        " .. rename.grn(target),
		}

		minetest.chat_send_player(name, "# Server: WHOIS data for account <" .. rename.gpn(target) .. ">:")
		for k, v in ipairs(tb) do
			minetest.chat_send_player(name, "# Server:     " .. v)
		end
	else
		minetest.chat_send_player(name, "# Server: Account <" .. rename.gpn(target) ..
			">: ADR " .. sanitize_ipv4(info.address) ..
			", IPV " .. info.ip_version ..
			", CU " .. info.connection_uptime ..
			", AVG RTT " .. info.avg_rtt ..
			", PV " .. info.protocol_version ..
			", RN <" .. rename.grn(target) .. ">" ..
			".")
	end
end



function network_whois.whois(name, param)
	if param == nil or param == "" then
		local players = minetest.get_connected_players()
		for k, v in pairs(players) do
			local pname = v:get_player_name()
			network_whois.display(name, pname)
		end
		return true
	end

	network_whois.display(name, param, "table")
	return true
end



if not network_whois.registered then
	minetest.register_privilege("whois", {
		description = "User can get connection info.",
		give_to_singleplayer = false,
	})

	minetest.register_chatcommand("whois", {
		params = "[<player>]",
		description = "Get player's connection info.",
		privs = {whois=true},

		func = function(...)
			return network_whois.whois(...)
		end
	})

	local c = "whois:core"
	local f = network_whois.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	network_whois.registered = true
end

