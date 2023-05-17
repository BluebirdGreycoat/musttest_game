-- Adds health bars above players.
-- Code by 4aiman, textures by Calinou. Licensed under CC0.
-- Note: code is called from wield3d to update, etc.
gauges = {}
local player_wielding = {}

-- Localize for performance.
local math_floor = math.floor
local math_max = math.max
local math_min = math.min



local function update_textures(gauge, player)
	local props = player:get_properties()
	local hp = math_floor((player:get_hp() / props.hp_max) * 20)
	local breath = math_floor((player:get_breath() / props.breath_max) * 11)

	-- Clamp values to ensure they're in range.
	hp = math_max(math_min(hp, 20), 0)
	breath = math_max(math_min(breath, 11), 0)

	gauge.object:set_properties({
		textures = {
			"health_" .. tostring(hp) .. ".png^breath_" .. tostring(breath) .. ".png"
		},
	})
end

local function add_gauge(player)
	rc.check_position(player) -- Check position before calling `add_entity'.
	local pname = player:get_player_name()

	local pos = player:get_pos()
	local ent = minetest.add_entity(pos, "gauges:hp_bar")

	if ent then
		ent:set_attach(player, "", {x = 0, y = 20, z = 0}, {x = 0, y = 0, z = 0})

		-- Set initial gauge values.
		local data = ent:get_luaentity()
		data.wielder = player
		data.chp = player:get_hp()
		data.cbreath = player:get_breath()

		update_textures(data, player)

		player_wielding[pname] = {}
		player_wielding[pname].object = ent
	end
end

--------------------------------------------------------------------------------
-- Note: this is only to be called inside wield3d.on_teleport().
function gauges.on_teleport()
	local plyrs = minetest.get_connected_players()
	-- Just clear all the wield entities. They will be restored shortly.
	for k, v in ipairs(plyrs) do
		local name = v:get_player_name()
		local wield = player_wielding[name]
		if wield and wield.object then
			wield.object:set_detach()
			wield.object:remove()
		end
		player_wielding[name] = nil
	end
end
--------------------------------------------------------------------------------

function gauges.on_global_step()
	local active_players = {}
	-- Add gauges to players without them.
	for _, player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		if not gdac_invis.is_invisible(name) and not cloaking.is_cloaked(name) then
			local wield = player_wielding[name]
			if not wield then
				add_gauge(player)
			end
			active_players[name] = true
		end
	end

	-- Remove expired player entries.
	for name, wield in pairs(player_wielding) do
		if not active_players[name] or gdac_invis.is_invisible(name) or cloaking.is_cloaked(name) then
			if wield.object then
				wield.object:remove()
			end
			player_wielding[name] = nil
		end
	end
end

function gauges.on_leaveplayer(player)
	local name = player:get_player_name()
	local wield = player_wielding[name] or {}
	if wield.object then
		wield.object:remove()
	end
	player_wielding[name] = nil
end



local bar_scalar = 0.8
local hp_bar = {
	physical = false,
	collisionbox = {x = 0, y = 0, z = 0},
	visual = "sprite",
	textures = {"health_20.png"}, -- The texture is changed later in the code.
	visual_size = {
		x = 1.5*bar_scalar,
		y = 0.09375*bar_scalar,
		z = 1.5*bar_scalar,
	}, -- Y value is (1 / 16) * 1.5.
	wielder = nil,
	glow = -1,

	-- Cached values.
	chp = 0,
	cbreath = 0,

	-- Timer.
	timer = 0,

	on_activate = function(self, staticdata)
		if staticdata == "expired" then
			self.object:remove()
		end
	end,

	get_staticdata = function(self)
		return "expired"
	end,

	on_step = function(self, dtime)
		self.timer = self.timer + dtime
		if self.timer < 1 then
			return
		end
		self.timer = 0

		local wielder = self.wielder
		if wielder == nil then
			self.object:remove()
			return
		elseif minetest.get_player_by_name(wielder:get_player_name()) == nil then
			self.object:remove()
			return
		end

		local hp = wielder:get_hp()
		local breath = wielder:get_breath()

		if hp ~= self.chp or breath ~= self.cbreath then
			update_textures(self, wielder)

			self.chp = hp
			self.cbreath = breath
		end
	end,

	on_blast = function(self, damage)
		-- No damage (punching), no knockback, no drops.
		return false, false, {}
	end,
}

minetest.register_entity("gauges:hp_bar", hp_bar)
