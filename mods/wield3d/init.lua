
wield3d = {}
wield3d.modpath = minetest.get_modpath("wield3d")

dofile(wield3d.modpath .. "/location.lua")

local update_time_conf = minetest.setting_get("wield3d_update_time") or 1
local update_time = tonumber(update_time_conf) or 1
local timer = 0
local periodic_reset = 0
local player_wielding = {}
local location = {
	"Arm_Right",          -- default bone
	{x=0, y=5.5, z=3},    -- default position
	{x=-90, y=225, z=90}, -- default rotation
	{x=0.25, y=0.25},     -- default scale
}

local function add_wield_entity(player)
	local name = player:get_player_name()
	local pos = player:getpos()
	if name and pos then
		pos.y = pos.y + 0.5
		local object = minetest.add_entity(pos, "wield3d:wield_entity")
		if object then
			object:set_attach(player, location[1], location[2], location[3])
			object:set_properties({
				textures = {"wield3d:hand"},
				visual_size = location[4],
			})
			player_wielding[name] = {}
			player_wielding[name].item = ""
			player_wielding[name].object = object
			player_wielding[name].location = location
		end
	end
end

minetest.register_item("wield3d:hand", {
	type = "none",
	wield_image = "blank.png",
})

minetest.register_entity("wield3d:wield_entity", {
	physical = false,
	collisionbox = {-0.125,-0.125,-0.125, 0.125,0.125,0.125},
	visual = "wielditem",
	on_activate = function(self, staticdata)
		if staticdata == "expired" then
			self.object:remove()
		end
	end,
	on_punch = function(self)
		self.object:remove()
	end,
	get_staticdata = function(self)
		return "expired"
	end,
})

-- Shall be called whenever someone teleports.
-- This mod requires to be able to reset the wield entities.
function wield3d.on_teleport()
	local players = minetest.get_connected_players()
	-- Just clear all the wield entities. They will be restored shortly.
	for k, v in ipairs(players) do
		local name = v:get_player_name()
		local wield = player_wielding[name]
		if wield and wield.object then
			wield.object:set_detach()
			wield.object:remove()
		end
		player_wielding[name] = nil
	end
	gauges.on_teleport()
end


local function do_teleport(name, param)
	-- Returns (pos, true) if found, otherwise (pos, false)
	local function find_free_position_near(pos)
		local tries = {
			{x=1,y=0,z=0},
			{x=-1,y=0,z=0},
			{x=0,y=0,z=1},
			{x=0,y=0,z=-1},
		}
		for _, d in ipairs(tries) do
			local p = {x = pos.x+d.x, y = pos.y+d.y, z = pos.z+d.z}
			local n = core.get_node_or_nil(p)
			if n and n.name then
				local def = core.registered_nodes[n.name]
				if def and not def.walkable then
					if rc.is_valid_realm_pos(p) then
						return p, true
					end
				end
			end
		end
		return pos, false
	end

	local teleportee = nil
	local p = {}
	p.x, p.y, p.z = string.match(param, "^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
	p.x = tonumber(p.x)
	p.y = tonumber(p.y)
	p.z = tonumber(p.z)
	if p.x and p.y and p.z then
		local lm = 31000
		if p.x < -lm or p.x > lm or p.y < -lm or p.y > lm or p.z < -lm or p.z > lm then
			return false, "Cannot teleport out of map bounds"
		end
		if not rc.is_valid_realm_pos(p) then
			return false, "Cannot teleport outside of any realm"
		end
		teleportee = core.get_player_by_name(name)
		if teleportee then
			teleportee:set_pos(p)
			rc.notify_realm_update(teleportee:get_player_name(), p)
			return true, "Teleporting to "..core.pos_to_string(p)
		end
	end

	local teleportee = nil
	local p = nil
	local target_name = nil
	target_name = param:match("^([^ ]+)$")
	teleportee = core.get_player_by_name(name)
	if target_name then
		local target = core.get_player_by_name(target_name)
		if target then
			p = target:get_pos()
		end
	end
	if teleportee and p then
		p = find_free_position_near(p)
		if not rc.is_valid_realm_pos(p) then
			return false, "Cannot teleport outside of any realm"
		end
		teleportee:set_pos(p)
		rc.notify_realm_update(teleportee:get_player_name(), p)
		return true, "Teleporting to " .. target_name
				.. " at "..core.pos_to_string(p)
	end

	if not core.check_player_privs(name, {bring=true}) then
		return false, "You don't have permission to teleport other players (missing bring privilege)"
	end

	local teleportee = nil
	local p = {}
	local teleportee_name = nil
	teleportee_name, p.x, p.y, p.z = param:match(
			"^([^ ]+) +([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
	p.x, p.y, p.z = tonumber(p.x), tonumber(p.y), tonumber(p.z)
	if teleportee_name then
		teleportee = core.get_player_by_name(teleportee_name)
	end
	if teleportee and p.x and p.y and p.z then
		if not rc.is_valid_realm_pos(p) then
			return false, "Cannot teleport players outside realm boundaries"
		end
		teleportee:set_pos(p)
		rc.notify_realm_update(teleportee:get_player_name(), p)
		return true, "Teleporting " .. teleportee_name
				.. " to " .. core.pos_to_string(p)
	end

	local teleportee = nil
	local p = nil
	local teleportee_name = nil
	local target_name = nil
	teleportee_name, target_name = string.match(param, "^([^ ]+) +([^ ]+)$")
	if teleportee_name then
		teleportee = core.get_player_by_name(teleportee_name)
	end
	if target_name then
		local target = core.get_player_by_name(target_name)
		if target then
			p = target:get_pos()
		end
	end
	if teleportee and p then
		if not rc.is_valid_realm_pos(p) then
			return false, "Cannot teleport players outside realm boundaries"
		end
		p = find_free_position_near(p)
		teleportee:set_pos(p)
		rc.notify_realm_update(teleportee:get_player_name(), p)
		return true, "Teleporting " .. teleportee_name
				.. " to " .. target_name
				.. " at " .. core.pos_to_string(p)
	end

	return false, 'Invalid parameters ("' .. param
			.. '") or player not found (see /help teleport)'
end



-- Override /teleport command so that wield3d can reset the wieldentities.
local cmdteleport = minetest.registered_chatcommands["teleport"]
if cmdteleport then
	local func = do_teleport
	if func and type(func) == "function" then
		local newfunc = function(name, param)
			wield3d.on_teleport()
			local result, str = func(name, param)
			if str and type(str) == "string" then
				-- If we got a string, check for a position vector. If we got one, then round it. Makes for prettier messages.
				local match = "%([,%d%.%-]+%)"
				local pos = minetest.string_to_pos(string.match(str, match))
				if pos then
					pos = vector.round(pos)
					pos = minetest.pos_to_string(pos)
					str = string.gsub(str, match, pos)
				end
				minetest.chat_send_player(name, "# Server: " .. str .. ".")
			end

			-- If teleport was successful then update realm paramters.
			--if result then
			--	rc.notify_realm_update(name, minetest.get_player_by_name(name):get_pos())
			--end
		end
		minetest.override_chatcommand("teleport", {
			func = newfunc,
		})
	end
end



minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < update_time then
		return
	end
	periodic_reset = periodic_reset + update_time
	if periodic_reset > 20 then
		wield3d.on_teleport()
		periodic_reset = 0
	end
	gauges.on_global_step()
	local active_players = {}
	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local wield = player_wielding[name]
		if wield and wield.object then
			local stack = player:get_wielded_item()
			local item = stack:get_name() or ""
			if item ~= wield.item then
				wield.item = item
				if item == "" then
					item = "wield3d:hand"
				end
				local loc = wield3d.location[item] or location
				if loc[1] ~= wield.location[1] or
						not vector.equals(loc[2], wield.location[2]) or
						not vector.equals(loc[3], wield.location[3]) then
					--wield.object:set_detach()
					wield.object:set_attach(player, loc[1], loc[2], loc[3])
					wield.location = {loc[1], loc[2], loc[3]}
				end
				wield.object:set_properties({
					textures = {item},
					visual_size = loc[4],
				})
			end
		else
			add_wield_entity(player)
		end
		active_players[name] = true
	end
	for name, wield in pairs(player_wielding) do
		if not active_players[name] then
			if wield.object then
				wield.object:remove()
			end
			player_wielding[name] = nil
		end
	end
	timer = 0
end)

minetest.register_on_joinplayer(function(player)
	minetest.after(0.5, function() wield3d.on_teleport() end)
end)

minetest.register_on_leaveplayer(function(player)
	gauges.on_leaveplayer(player)
	local name = player:get_player_name()
	if name then
		local wield = player_wielding[name] or {}
		if wield.object then
			wield.object:remove()
		end
		player_wielding[name] = nil
	end
end)

