-- Minetest Anti-VPN mod chat commands.
-- license: Apache 2.0
--
-- Implements the chat commands for "/anti_vpn ...."
--
local ERROR_COLOR = minetest.get_color_escape_sequence '#FF8080'

local function chat_send_error(pname, message)
    minetest.chat_send_player(pname, ERROR_COLOR .. "# Server: " .. message)
end

local function chat_send_info(pname, message)
    minetest.chat_send_player(pname, "# Server: " .. message)
end

local function sanitize_ipv4(ip)
    if ip:find("::ffff:") then
        ip = ip:sub(8)
    end
    return ip
end

-- If input is a literal IP address, then return it.
-- If input matches a connected player, then return their IP.
-- Otherwise, return nil.
local function resolve_ip(txt)
    if anti_vpn.is_valid_ip(txt) then return txt end

    -- Maybe its a player's name.  If yes, use their IP.
    local player = minetest.get_player_information(txt)
    if player then
        local ip = sanitize_ipv4(player.address or '')
        if anti_vpn.is_valid_ip(ip) then return ip end
    end

    return nil
end

-- Handle commands of the form "/anti_vpn ip ......"
local function chat_cmd_ip(pname, parts)
    local verb = parts[2]

    -- Extract IP list.
    local ip_list = {}
    local idx = 3
    while parts[idx] do
        local ip = resolve_ip(parts[idx])
        if ip then
            table.insert(ip_list, ip)
        else
            chat_send_error(pname, 'Invalid IP address: ' .. parts[idx])
        end
        idx = idx + 1
    end

    if verb == 'add' then
        for _, ip in ipairs(ip_list) do anti_vpn.enqueue_lookup(ip) end
    elseif verb == 'allow' then
        for _, ip in ipairs(ip_list) do
            anti_vpn.add_override_ip(ip, false)
        end
    elseif verb == 'deny' then
        for _, ip in ipairs(ip_list) do
            anti_vpn.add_override_ip(ip, true)
        end
    elseif (verb == 'del') or (verb == 'delete') or (verb == 'rm') then
        for _, ip in ipairs(ip_list) do anti_vpn.delete_ip(ip) end
    else
        chat_send_error(pname, 'Invalid command.')
    end
end

-- Handle commands of the form "/anti_vpn mode ....."
local function chat_cmd_mode(pname, parts)
    if (type(parts[2]) == 'string') then
        local msg = anti_vpn.set_operating_mode(parts[2])
        chat_send_info(pname, msg)
    else
        chat_send_info(pname, 'Anti VPN operating mode: ' .. anti_vpn.get_operating_mode())
    end
end

local function chat_cmd_handler(pname, param)
    local parts = param:split(' ')

    if (parts[1] == 'flush') then
        anti_vpn.flush_mod_storage()
        chat_send_info(pname, 'Anti VPN data flushed to storage.')
    elseif (parts[1] == 'cleanup') then
        anti_vpn.cleanup()
        chat_send_info(pname, 'Anti VPN cleanup initiated.')
    elseif (parts[1] == 'mode') then
        chat_cmd_mode(pname, parts)
    elseif (parts[1] == 'ip') then
        chat_cmd_ip(pname, parts)
    elseif (parts[1] == 'stats') then
        chat_send_info(pname, anti_vpn.get_stats_string())
    else
        chat_send_error(pname, 'Unrecognized Anti VPN command: ' .. param)
    end
end

minetest.register_chatcommand('anti_vpn', {
    privs = {vpn_control = true},
    description = 'Issue commands to the Anti VPN system.',
    params = '<command> <args>',
    func = chat_cmd_handler,
})
