-- Minetest Chat Anti-VPN
-- license: Apache 2.0
--
-- Our namespace.
anti_vpn = {}

-- By default, talk to local testing stub.  For production, you should
-- configure the settings in `minetest.conf`.  See the `README.md` file.
local DEFAULT_VPNAPI_URL = 'http://localhost:48888'
local DEFAULT_IPAPI_URL = 'http://localhost:48888'

-- User agent to transmit with HTTP requests.
local USER_AGENT = 'https://github.com/EdenLostMinetest/anti_vpn'

-- Timeout (seconds) when sending HTTP requests.
local DEFAULT_TIMEOUT = 10

-- How long to use old data in cache before doing a refetch from provider.
local CACHE_TIMEOUT = 60*60*24*3

-- How long old entries can remain in the IP cache before getting deleted.
local CLEAN_OLD_AFTER = 60*60*24*90

-- How often (seconds) to run the async background tasks.
local ASYNC_WORKER_DELAY = 5

-- For testing.  Normally this table should be empty.
-- Map a player name (string) to an IPV4 address (string).
local testdata_player_ip = {}

-- Passed from `init.lua`.  It can only be obtained from there.
local http_api = nil

-- Operating mode (string).  Values are "off", "dryrun", "enforce".
-- https://github.com/EdenLostMinetest/anti_vpn/issues/3
local operating_mode = 'enforce'

-- Cache of vpnapi.io lookups, in mod_storage().
-- Key = IP address.
-- Value = table:
--   'asn' (string) autonomous system number.
--   'blocked' (boolean).
--   'country' (string) two-letter country code.
--   'created' (seconds since unix epoch).
--   'provider' (string) internal name for where this data came from.
local ip_data = {}

-- Queue of IP addresses that we need to lookup.
-- Key = IP.  Value = timestamp submitted (used for pruning stale entries).
local ip_queue = {}

-- Count of outstanding HTTP requests.
local active_requests_vpnapi = 0
local active_requests_ipapi = 0

-- Allow/Deny/Lockdown info, per player.
-- Key = player name
-- Value = table:
--  'banned' (bool) outright ban the player.
--  'bypass' (bool) always allow the player.
local player_data = {}

-- Storage backing the cache.
local mod_storage = minetest.get_mod_storage()

-- Never expose the APIKEY outside this mod.
-- This is used with vpnapi.io
local apikey = nil

local vpnapi_url = DEFAULT_VPNAPI_URL
local ipapi_url = DEFAULT_IPAPI_URL

local function count_keys(tbl)
    local count = 0
    for k in pairs(tbl) do count = count + 1 end
    return count
end

-- If address is IPV6-mapped IPV4, convert to plain IPV4.
-- Otherwise, does nothing with real IPV6 addresses.
-- This appears to be necessary because the online service treats all
-- IPV6-mapped IPV4 addresses as private, and they don't give us the real info.
local function sanitize_ipv4(ip)
    if ip:find("::ffff:") then
        ip = ip:sub(8)
    end
    return ip
end

local function get_engine_ip(pname)
    return sanitize_ipv4(minetest.get_player_ip(pname))
end

-- An IPv6 address consists of 8 groups of 1 to 4 hexadecimal digits, separated by colons.
local function is_ipv6_normal(address)
    -- Split the address into groups by colon.
    local groups = {}
    for group in address:gmatch("[^:]+") do
        table.insert(groups, group)
    end

    -- Check if the number of groups is exactly 8.
    if #groups ~= 8 then return false end

    -- Verify each group has 1 to 4 hexadecimal digits.
    for _, group in ipairs(groups) do
        if not group:match("^%x%x?%x?%x?$") then
            return false
        end
    end

    -- Passed all checks, it's a valid IPv6 in normal form.
    return true
end

local IPV4_PATTERN = '^(%d+)%.(%d+)%.(%d+)%.(%d+)$'

anti_vpn.is_valid_ip = function(ip)
    local octets = {string.match(ip, IPV4_PATTERN)}
    local count = 0

    for _, v in ipairs(octets) do
        if v == nil then return false end
        local x = tonumber(v) or 257
        if (x < 0) or (x > 255) then return false end
        count = count + 1
    end

    return count == 4 or is_ipv6_normal(ip)
end

-- https://www.rfc-editor.org/rfc/rfc1918
local function is_private_ip(ip)
    local a, b, c, d = string.match(ip, IPV4_PATTERN)
    if a and b and c and d then
        a, b = tonumber(a), tonumber(b)
        return (a == 10) -- 10.0.0.0/8
        or ((a == 172) and (b >= 16) and (b <= 31)) -- 172.16.0.0/12
        or ((a == 192) and (b == 168)) -- 192.168.0.0/16
        or (a == 127) -- loopback
    end
    return false
end

local function get_kick_text(pname, ip)
    return 'Proxy connections disallowed. ' .. (minetest.settings:get('anti_vpn.kick_text') or '')
end

local function kick_player(pname, ip)
    if operating_mode == 'enforce' then
        minetest.kick_player(pname, get_kick_text(pname, ip))
        minetest.log('warning', '[anti_vpn] kicking player ' .. pname .. ' from ' .. ip)
    end
end

anti_vpn.get_player_ip = function(pname)
    return testdata_player_ip[pname] or get_engine_ip(pname)
end

-- Returns text suitable for sending to player via chat message.
anti_vpn.set_operating_mode = function(mode)
    local valid_modes = {off = true, dryrun = true, enforce = true}
    if valid_modes[mode] == nil then
        return 'Invalid mode. Valid modes are "off", "dryrun", "enforce".'
    end

    local old_opmode = operating_mode
    local msg = 'Changing Anti VPN operating mode from ' .. old_opmode .. ' to ' .. mode .. '.'
    minetest.log('action', '[anti_vpn] ' .. msg)
    operating_mode = mode
    mod_storage:set_string('operating_mode', mode)

    if old_opmode ~= "enforce" and mode == "enforce" then
        anti_vpn.enqueue_connected_players()
    end

    return msg
end

-- Returns raw operating mode string ("off", "dryrun", "enforce")
anti_vpn.get_operating_mode = function()
    return operating_mode
end

-- Add or remove a player name from the VPN whitelist.
-- If added, this player will be exempt from VPN kicking.
-- Pass 'nil' to simply query if player in whitelist.
anti_vpn.whitelist_player = function(pname, whitelist)
    local was_whitelisted = false
    if player_data[pname] and player_data[pname].bypass then
        was_whitelisted = true
    end
    if whitelist == true then
        -- Don't erase other stuff if it might exist.
        if player_data[pname] then
            player_data[pname].bypass = true
        else
            player_data[pname] = {bypass = true}
        end
        anti_vpn.flush_mod_storage()
    elseif whitelist == false then
        -- Don't erase other stuff if it might exist.
        if player_data[pname] and player_data[pname].bypass then
            player_data[pname].bypass = nil
        end
        anti_vpn.flush_mod_storage()
    end
    return was_whitelisted
end

-- Returns multiple results:
--   [1] (bool) "found" - Was the IP found in the ip_data?
--   [2] (bool) "blocked" - Does this IP address map to a proxy or VPN?
--   [3] (bool) "whitelisted" - Is this account name in whitelist?
--
-- Note: in the case of a whitelisted VPN user, whose IP data we have, this
-- function will return 'true, true, true'.
anti_vpn.lookup = function(pname, ip)
    assert(type(pname) == 'string')
    assert(type(ip) == 'string')

    local found, blocked, whitelisted = false, false, false

    -- Private IPs are always whitelisted.
    if is_private_ip(ip) then
        whitelisted = true
    end

    -- Check name against VPN whitelist.
    if player_data[pname] and player_data[pname].bypass then
        whitelisted = true
    end

    -- Check if we HAVE the data for this IP.
    local data = ip_data[ip]
    if data ~= nil then
        -- If the IP data is too old, pretend we don't have it.
        -- This should cause a refetch from our provider.
        if ((data.created or 0) + CACHE_TIMEOUT) >= os.time() then
            found = true
        end

        -- This really just signals if the IP maps to a proxy or VPN.
        if data.blocked then
            blocked = true
        end
    end

    -- Return all flags.
    return found, blocked, whitelisted
end

anti_vpn.add_override_ip = function(ip, blocked)
    if not anti_vpn.is_valid_ip(ip) then return end

    local asn = ip_data[ip] and ip_data[ip]['asn'] or ''
    local country = ip_data[ip] and ip_data[ip]['country'] or ''

    ip_data[ip] = {
        asn = asn,
        blocked = blocked,
        country = country,
        created = os.time(),
        provider = 'manual'
    }

    ip_queue[ip] = nil

    anti_vpn.flush_mod_storage()
end

anti_vpn.delete_ip = function(ip)
    if not anti_vpn.is_valid_ip(ip) then return end

    ip_data[ip] = nil
    ip_queue[ip] = nil

    anti_vpn.flush_mod_storage()
end

-- Forward declare function.
local process_ip_queue

-- VPNAPI.io seems to give us the goods w.r.t. whether connection is a VPN.
local function handle_vpnapi_response(result)
    if result.succeeded then
        local tbl = minetest.parse_json(result.data)
        if type(tbl) ~= 'table' then
            minetest.log('error', '[anti_vpn] vpnapi.io HTTP response is not JSON?')
            -- Don't write to console, that could mess it up.
            --minetest.log('error', dump(result))
            return
        end

        if tbl['ip'] == nil then
            minetest.log('error', '[anti_vpn] vpnapi.io HTTP response is missing the original IP address.')
            --minetest.log('error', dump(result))
            return
        end

        local ip = tbl.ip
        local blocked = false

        -- Expected keys are 'vpn', 'proxy', 'tor', 'relay'.
        -- We'll reject the IP if any are true.
        for k, v in pairs(tbl.security) do blocked = blocked or v end

        local asn = tbl['network'] and tbl.network.autonomous_system_number or ''
        local aso = tbl['network'] and tbl.network.autonomous_system_organization or ''
        local network = tbl['network'] and tbl.network.network or ''
        local country = tbl['location'] and tbl.location.country_code or ''
        local city = tbl['location'] and tbl.location.city or ''
        local region = tbl['location'] and tbl.location.region or ''
        local continent = tbl['location'] and tbl.location.continent or ''
        local timezone = tbl['location'] and tbl.location.time_zone or ''
        local is_eu = tbl['location'] and tbl.location.is_in_european_union or false
        local lat = tbl['location'] and tbl.location.latitude or ''
        local lon = tbl['location'] and tbl.location.longitude or ''
        local locale_code = tbl['location'] and tbl.location.locale_code or ''
        local metro_code = tbl['location'] and tbl.location.metro_code or ''
        local region_code = tbl['location'] and tbl.location.region_code or ''
        local country_code = tbl['location'] and tbl.location.country_code or ''
        local continent_code = tbl['location'] and tbl.location.continent_code or ''
        local is_vpn = tbl['security'] and tbl.security.vpn or false
        local is_proxy = tbl['security'] and tbl.security.proxy or false
        local is_tor = tbl['security'] and tbl.security.tor or false
        local is_relay = tbl['security'] and tbl.security.relay or false

        -- Don't remove existing data, but we may overwrite.
        ip_data[ip] = ip_data[ip] or {}

        ip_data[ip]['asn'] = asn
        ip_data[ip]['aso'] = aso
        ip_data[ip]['network'] = network
        ip_data[ip]['blocked'] = blocked
        ip_data[ip]['country'] = country
        ip_data[ip]['city'] = city
        ip_data[ip]['region'] = region
        ip_data[ip]['continent'] = continent
        ip_data[ip]['time_zone'] = timezone
        ip_data[ip]['lat'] = lat
        ip_data[ip]['lon'] = lon
        ip_data[ip]['locale_code'] = locale_code
        ip_data[ip]['metro_code'] = metro_code
        ip_data[ip]['region_code'] = region_code
        ip_data[ip]['country_code'] = country_code
        ip_data[ip]['continent_code'] = continent_code
        ip_data[ip]['is_in_eu'] = is_eu
        ip_data[ip]['created'] = os.time()
        ip_data[ip]['provider'] = 'vpnapi'
        ip_data[ip]['is_vpn'] = is_vpn
        ip_data[ip]['is_proxy'] = is_proxy
        ip_data[ip]['is_tor'] = is_tor
        ip_data[ip]['is_relay'] = is_relay

        anti_vpn.flush_mod_storage()

        -- Make the log message somewhat parseable w/ "awk", in case we
        -- need to reconstruct our database from just the log files.
        minetest.log('action', '[anti_vpn] vpnapi.io HTTP response: ip:' .. ip .. ' blocked:' .. tostring(blocked) .. ' asn:' .. asn .. ' country:' .. country)
    else
        minetest.log('error', '[anti_vpn] vpnapi.io HTTP request failed')
        --minetest.log('error', dump(result))
    end

    active_requests_vpnapi = active_requests_vpnapi - 1

    -- Start a new lookup immediately, if we have one, and if previous
    -- was successful.
    if result.succeeded then process_ip_queue() end
end

-- We query IP-API.com to get a little more information ...
local function handle_ipapi_response(result)
    if result.succeeded then
        local tbl = minetest.parse_json(result.data)
        if type(tbl) ~= 'table' then
            minetest.log('error', '[anti_vpn] ip-api.com HTTP response is not JSON?')
            -- Don't write to console, that could mess it up.
            --minetest.log('error', dump(result))
            return
        end

        if tbl['query'] == nil then
            minetest.log('error', '[anti_vpn] ip-api.com HTTP response is missing the original IP address.')
            --minetest.log('error', dump(result))
            return
        end

        local ip = tbl.query

        local district = tbl.district or ''
        local zipcode = tbl.zip or ''
        local isp = tbl.isp or ''
        local mobile = tbl.mobile or false
        local hosting = tbl.hosting or false
        local proxy = tbl.proxy or false

        -- Don't remove existing data, but we may overwrite.
        ip_data[ip] = ip_data[ip] or {}

        ip_data[ip]['district'] = district
        ip_data[ip]['zip'] = zipcode
        ip_data[ip]['isp'] = isp
        ip_data[ip]['is_mobile'] = mobile
        ip_data[ip]['is_hosting'] = hosting

        -- This one is also obtained from vpnapi.io
        -- Set 'true' if either provider set 'true'.
        ip_data[ip]['is_proxy'] = ip_data[ip]['is_proxy'] or proxy

        anti_vpn.flush_mod_storage()

        minetest.log('action', '[anti_vpn] ip-api.com HTTP response: ip:' .. ip)
    else
        minetest.log('error', '[anti_vpn] ip-api.com HTTP request failed')
        --minetest.log('error', dump(result))
    end

    active_requests_ipapi = active_requests_ipapi - 1

    -- Start a new lookup immediately, if we have one, and if previous
    -- was successful.
    if result.succeeded then process_ip_queue() end
end

local function fetch_vpnapi_provider(ip)
    -- API key required.
    if apikey == nil then return end

    -- Only one request at a time please.
    if active_requests_vpnapi > 0 then return end
    active_requests_vpnapi = active_requests_vpnapi + 1

    -- Queue up an external lookup.  This is async and can take several
    -- seconds, so we don't want to block the server during this time.
    -- We'll allow the login for now, and kick the player later if needed.
    local url = vpnapi_url .. '/api/' .. ip
    minetest.log('action', '[anti_vpn] fetching ' .. url)

    http_api.fetch({
        url = url .. '?key=' .. apikey,
        method = 'GET',
        user_agent = USER_AGENT,
        timeout = DEFAULT_TIMEOUT
    }, handle_vpnapi_response)
end

local function fetch_ipapi_provider(ip)
    -- Only one request at a time please.
    if active_requests_ipapi > 0 then return end
    active_requests_ipapi = active_requests_ipapi + 1

    -- Queue up an external lookup.  This is async and can take several
    -- seconds, so we don't want to block the server during this time.
    -- We'll allow the login for now, and kick the player later if needed.
    local url = ipapi_url .. '/json/' .. ip
    local fields = "17556000"
    minetest.log('action', '[anti_vpn] fetching ' .. url)

    http_api.fetch({
        url = url .. '?fields=' .. fields,
        method = 'GET',
        user_agent = USER_AGENT,
        timeout = DEFAULT_TIMEOUT
    }, handle_ipapi_response)
end

-- Called on demand, and from async timer, to serially process the ip_queue.
process_ip_queue = function()
    if operating_mode == 'off' then return end

    -- Is the ip_queue empty?
    if next(ip_queue) == nil then return end

    -- Is the HTTP API properly loaded?
    if http_api == nil then
        minetest.log('error', '[anti_vpn] http_api failed to allocate.  Add ' .. minetest.get_current_modname() .. ' to secure.http_mods.')
        return
    end

    local ip = next(ip_queue)
    ip_queue[ip] = nil

    fetch_vpnapi_provider(ip)
    fetch_ipapi_provider(ip)
end

function anti_vpn.get_vpn_data_for(ip)
    return ip_data[sanitize_ipv4(ip)] -- Or nil.
end

-- If IP is in ip_data, do nothing.  If not, queue up a remote lookup.
-- Returns nothing.
anti_vpn.enqueue_lookup = function(ip, pname)
    if not anti_vpn.is_valid_ip(ip) then return end

    -- Don't bother looking up private/LAN IPs.
    if is_private_ip(ip) then return end

    -- If IP is already cached, then do nothing.
    if ip_data[ip] ~= nil then return end

    -- If IP is already queued, then do nothing.
    if ip_queue[ip] ~= nil then return end

    ip_queue[ip] = os.time()

    local namestr = ""
    if pname then
        namestr = " (" .. pname .. ")"
    end
    minetest.log('action', '[anti_vpn] Queueing request for ' .. ip .. namestr)

    process_ip_queue()
end

-- prejoin must return either 'nil' (allow the login) or a string (reject login
-- with the string as the error message).
anti_vpn.on_prejoinplayer = function(pname, ip)
    if operating_mode == 'off' then return nil end
    ip = sanitize_ipv4(ip)

    ip = testdata_player_ip[pname] or ip -- Hack for testing.
    local found, blocked, whitelisted = anti_vpn.lookup(pname, ip)

    -- Always get IP data for everyone, including whitelisted.
    if not found then anti_vpn.enqueue_lookup(ip, pname) end

    if found and blocked and not whitelisted then
        minetest.log('warning', '[anti_vpn] blocking player ' .. pname .. ' from ' .. ip .. ' mode=' .. operating_mode)
        if operating_mode == 'enforce' then
            return get_kick_text(pname, ip)
        else
            return nil
        end
    end

    return nil
end

anti_vpn.on_joinplayer = function(player, last_login)
    if operating_mode == 'off' then return end

    local pname = player:get_player_name()
    local ip = anti_vpn.get_player_ip(pname) or ''

    local found, blocked, whitelisted = anti_vpn.lookup(pname, ip)

    -- Always get IP data for everyone, including whitelisted.
    if not found then anti_vpn.enqueue_lookup(ip, pname) end

    if found and blocked and not whitelisted then
        minetest.log('warning', '[anti_vpn] kicking player ' .. pname .. ' from ' .. ip .. ' mode=' .. operating_mode)
        kick_player(pname, ip)
    end
end

anti_vpn.flush_mod_storage = function()
    local json_ip_data = minetest.write_json(ip_data)
    local json_players = minetest.write_json(player_data)

    mod_storage:set_string('ip_data', json_ip_data)
    mod_storage:set_string('players', json_players)

    -- For debugging.  mod_storage is powerful, but our data ends up being
    -- double encoded as a JSON payload, stringified, as a JSON value in a
    -- map.  Its a PITA to analyze offline.  See README.md for `jq` recipes.
    if minetest.settings:get_bool('anti_vpn.debug.json', false) then
        local dir = minetest.get_worldpath()
        minetest.safe_file_write(dir .. '/anti_vpn_ip_data.json', json_ip_data)
        minetest.safe_file_write(dir .. '/anti_vpn_players.json', json_players)
    end
end

-- To be called at server start ONLY.
anti_vpn.drop_old_ips = function()
    local ips_to_drop = {}
    local cur_time = os.time()

    for ip, v in pairs(ip_data) do
        if ((v.created or 0) + CLEAN_OLD_AFTER) < cur_time then
            ips_to_drop[#ips_to_drop+1] = ip
        end
    end

    for idx, ip in ipairs(ips_to_drop) do
        ip_data[ip] = nil
    end

    if #ips_to_drop > 0 then
        anti_vpn.flush_mod_storage()
        minetest.log('action', '[anti_vpn] dropped ' .. #ips_to_drop .. ' old records.')
    end
end

anti_vpn.init = function(http_api_provider)
    http_api = http_api_provider

    operating_mode = (mod_storage:contains('operating_mode') and mod_storage:get_string('operating_mode')) or 'enforce'
    minetest.log('action', '[anti_vpn] operating_mode: ' .. operating_mode)

    local json_ip_data = mod_storage:get('ip_data')
    local json_players = mod_storage:get('players')

    ip_data = json_ip_data and minetest.parse_json(json_ip_data) or {}
    player_data = json_players and minetest.parse_json(json_players) or {}

    minetest.log('action', '[anti_vpn] Loaded ' .. count_keys(ip_data) .. ' IP lookups.')
    minetest.log('action', '[anti_vpn] Loaded ' .. count_keys(player_data) .. ' players.')

    -- Remove old/stale IPs from database, so we don't end up keeping them forever.
    anti_vpn.drop_old_ips()

    apikey = minetest.settings:get('anti_vpn.provider.vpnapi.apikey')
    if apikey == nil then
        -- TODO: try a text file, so that we don't need to store it in the main
        -- config file, which might end up in a source code repo.
        minetest.log('error', '[anti_vpn] Failed to lookup vpnapi.io api key.')
    end

    vpnapi_url = minetest.settings:get('anti_vpn.provider.vpnapi.url') or DEFAULT_VPNAPI_URL
    ipapi_url = minetest.settings:get('anti_vpn.provider.ip_api.url') or DEFAULT_IPAPI_URL
end

local function async_player_kick()
    if operating_mode ~= 'enforce' then return end

    local count = 0
    for _, player in ipairs(minetest.get_connected_players()) do
        local pname = player:get_player_name()
        local ip = anti_vpn.get_player_ip(pname)

        local found, blocked, whitelisted = anti_vpn.lookup(pname, ip)

        if found and blocked and not whitelisted then
            kick_player(pname, ip)
            count = count + 1
        end
    end

    if count > 0 then
        minetest.log('action', '[anti_vpn] kicked ' .. count .. ' VPN users.')
    end
end

anti_vpn.async_worker = function()
    minetest.after(ASYNC_WORKER_DELAY, anti_vpn.async_worker)
    async_player_kick()
    process_ip_queue()
end

anti_vpn.enqueue_connected_players = function()
    for _, player in ipairs(minetest.get_connected_players()) do
        local pname = player:get_player_name()
        local ip = anti_vpn.get_player_ip(pname)
        anti_vpn.enqueue_lookup(ip, pname)
    end
end

-- Misc functions to "clean" the database.
anti_vpn.cleanup = function()
    --for ip, v in pairs(ip_data) do
        -- Do stuff here.
    --end

    -- All IPs will be refetched.
    ip_data = {}
    anti_vpn.flush_mod_storage()

    -- Re-enqueue all player IPs for lookup.
    anti_vpn.enqueue_connected_players()
end

-- Returns a string for use in a chat message.
anti_vpn.get_stats_string = function()
    local total = 0
    local blocked = 0

    for ip, v in pairs(ip_data) do
        total = total + 1
        if v.blocked then blocked = blocked + 1 end
    end

    local perc = (total and (100.0 * blocked / total)) or 0.0
    return 'Anti VPN stats: total: ' .. total .. ', blocked: ' .. blocked ..
               ' (' .. string.format('%.4f', perc) .. '%)'
end
