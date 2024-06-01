
wield3d = {}
wield3d.modpath = minetest.get_modpath("wield3d")

dofile(wield3d.modpath .. "/location.lua")

local update_time_conf = minetest.settings:get("wield3d_update_time") or 1
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
	local pos = player:get_pos()
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
	pointable = false,
	static_save = false,

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
	-- Disabled, let's see if the devs finally fixed the entity attachment problems.
	-- 2024/6/1: re-enabled because sometimes wields disappear and don't reappear.
	---[[
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
	--]]
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
	minetest.after(2, function() wield3d.on_teleport() end)
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

