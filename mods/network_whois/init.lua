
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

local function get_truefalse(slave)
	if slave == true then
		return "YES"
	elseif slave == false then
		return "NO"
	else
		return "N/A"
	end
end

local function get_stringna(str)
	if str == nil then
		return "N/A"
	elseif str == "" then
		return "N/A"
	else
		return str
	end
end

local function get_authdate(authdata)
	local s
	local t = authdata.first_login or 0
	if t ~= 0 then
		s = os.date("!%Y-%m-%d", t)
	else
		-- For a lot of players, first login info was populated from the chatlog.
		-- There's no useable data before this date;
		-- players whos played before the chatlog was added have a first login of 0.
		s = "Pre 2017-07-03"
	end
	return s
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
		local vpn = anti_vpn.get_vpn_data_for(info.address) or {}
		local authdata = minetest.get_auth_handler().get_auth(target)

		local tb = {
			"IP Address:        " .. sanitize_ipv4(info.address),
			"IP Version:        " .. ip2str(info.ip_version),
			"Connection Uptime: " .. info.connection_uptime,
			"Avg RTT:           " .. (info.avg_rtt and string.format("%.3f", info.avg_rtt)) or "N/A",
			"Min RTT:           " .. (info.min_rtt and string.format("%.3f", info.min_rtt)) or "N/A",
			"Max RTT:           " .. (info.max_rtt and string.format("%.3f", info.max_rtt)) or "N/A",
			"Protocol Version:  " .. info.protocol_version,
			"Formspec Version:  " .. info.formspec_version,
			"Language Code:     " .. get_stringna(info.lang_code),
			"Login Name:        " .. rename.grn(target),
			"First Login:       " .. get_authdate(authdata),
			"VPN Last Updated:  " .. ((vpn.created and os.date("!%Y-%m-%d", vpn.created)) or "Never"),
			"ASN:               " .. get_stringna(vpn.asn),
			"ASO:               " .. get_stringna(vpn.aso),
			"ISP:               " .. get_stringna(vpn.isp),
			"City:              " .. get_stringna(vpn.city),
			"District:          " .. get_stringna(vpn.district),
			"Zip:               " .. get_stringna(vpn.zip),
			"Region:            " .. get_stringna(vpn.region),
			"Country:           " .. get_stringna(vpn.country),
			"Continent:         " .. get_stringna(vpn.continent),
			"Region Code:       " .. get_stringna(vpn.region_code),
			"Country Code:      " .. get_stringna(vpn.country_code),
			"Continent Code:    " .. get_stringna(vpn.continent_code),
			"Latitude:          " .. get_stringna(vpn.lat),
			"Longitude:         " .. get_stringna(vpn.lon),
			"Time Zone:         " .. get_stringna(vpn.time_zone),
			"EU Vassal Slave:   " .. get_truefalse(vpn.is_in_eu), -- Have to put some humor in this. >:[
			"Is VPN:            " .. get_truefalse(vpn.is_vpn),
			"Is Proxy:          " .. get_truefalse(vpn.is_proxy),
			"Is Tor:            " .. get_truefalse(vpn.is_tor),
			"Is Relay:          " .. get_truefalse(vpn.is_relay),
			"Is Mobile:         " .. get_truefalse(vpn.is_mobile),
			"Is Hosting:        " .. get_truefalse(vpn.is_hosting),
		}

		minetest.chat_send_player(name, "# Server: WHOIS data for account <" .. rename.gpn(target) .. ">:")
		for k, v in ipairs(tb) do
			minetest.chat_send_player(name, "# Server:     " .. v)
		end
	else
		-- Basic info only.
		minetest.chat_send_player(name, "# Server: Account <" .. rename.gpn(target) ..
			">: ADR " .. sanitize_ipv4(info.address) ..
			", IPV " .. info.ip_version ..
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

