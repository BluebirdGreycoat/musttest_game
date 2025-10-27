
local get_player_by_name = minetest.get_player_by_name
function minetest.get_player_by_name(name)
	return get_player_by_name(rename.grn(name))
end

local player_exists = minetest.player_exists
function minetest.player_exists(name)
	return player_exists(rename.grn(name))
end

local get_player_information = minetest.get_player_information
function minetest.get_player_information(name)
	return get_player_information(rename.grn(name))
end

local kick_player = minetest.kick_player
function minetest.kick_player(name, reason)
	return kick_player(rename.grn(name), reason)
end

local notify_authentication_modified = minetest.notify_authentication_modified
function minetest.notify_authentication_modified(name)
	if type(name) == "string" then
		return notify_authentication_modified(rename.grn(name))
	end
	-- Can be called with no name.
	return notify_authentication_modified()
end

local check_password_entry = minetest.check_password_entry
function minetest.check_password_entry(name, entry, password)
	return check_password_entry(rename.grn(name), entry, password)
end

local get_password_hash = minetest.get_password_hash
function minetest.get_password_hash(name, raw_password)
	return get_password_hash(rename.grn(name), raw_password)
end

local set_player_password = minetest.set_player_password
function minetest.set_player_password(name, password_hash)
	return set_player_password(rename.grn(name), password_hash)
end

local set_player_privs = minetest.set_player_privs
function minetest.set_player_privs(name, privs)
	return set_player_privs(rename.grn(name), privs)
end

local get_player_privs = minetest.get_player_privs
function minetest.get_player_privs(name)
	return get_player_privs(rename.grn(name))
end

local check_player_privs = minetest.check_player_privs
function minetest.check_player_privs(player, ...)
	if type(player) == "string" then
		return check_player_privs(rename.grn(player), ...)
	end
	return check_player_privs(player, ...)
end

local get_player_ip = minetest.get_player_ip
function minetest.get_player_ip(name)
	return get_player_ip(rename.grn(name))
end

local chat_send_player = minetest.chat_send_player
function minetest.chat_send_player(name, text)
	return chat_send_player(rename.grn(name), text)
end

local show_formspec = minetest.show_formspec
function minetest.show_formspec(playername, formname, formspec)
	return show_formspec(rename.grn(playername), formname, formspec)
end

local close_formspec = minetest.close_formspec
function minetest.close_formspec(playername, formname)
	return close_formspec(rename.grn(playername), formname)
end

local get_ban_description = minetest.get_ban_description
function minetest.get_ban_description(ip_or_name)
	return get_ban_description(rename.grn(ip_or_name))
end

local ban_player = minetest.ban_player
function minetest.ban_player(name)
	return ban_player(rename.grn(name))
end

local unban_player_or_ip = minetest.unban_player_or_ip
function minetest.unban_player_or_ip(name)
	return unban_player_or_ip(rename.grn(name))
end

local delete_particlespawner = minetest.delete_particlespawner
function minetest.delete_particlespawner(id, pnameorref)
	if type(pnameorref) == "string" then
		pnameorref = rename.grn(pnameorref)
	end
	return delete_particlespawner(id, pnameorref)
end

-- This function should never be called with an alias anyway.
--local is_protected = minetest.is_protected
--function minetest.is_protected(pos, name)
--	return is_protected(pos, rename.grn(name))
--end

local record_protection_violation = minetest.record_protection_violation
function minetest.record_protection_violation(pos, name)
	return record_protection_violation(pos, rename.grn(name))
end

