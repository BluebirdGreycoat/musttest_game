
randspawn = randspawn or {}
randspawn.modpath = minetest.get_modpath("randspawn")

local fallback_pos = {x=0, y=-7, z=0}

local ab = {
	{x=0, y=-7, z=0}, -- Central.
	{x=0, y=-7, z=198}, -- North.
	{x=198, y=-7, z=0}, -- East.
	{x=0, y=-7, z=-198}, -- South.
	{x=-198, y=-7, z=0}, -- West.
}

local positions = {
	[1]=ab[2],
	[2]=ab[3],
	[3]=ab[4],
	[4]=ab[5],
	[5]=ab[2],
	[6]=ab[3],
	[7]=ab[4],
	[8]=ab[5],
	[9]=ab[2],
	[10]=ab[3],
	[11]=ab[4],
	[12]=ab[5],
}

local function get_respawn_position(death_pos)
	local tb = os.date("*t")
	local m = tb.month
	if positions[m] and tb.wday ~= 7 and tb.wday ~= 1 then
		local pos = vector.new(positions[m])
		-- If player dies in the nether they respawn in the Nether City.
		if death_pos.y < -25000 then
			pos.y = -30793
		end
		--minetest.chat_send_all("respawn at " .. minetest.pos_to_string(pos))
		return pos
	else
		return fallback_pos
	end
end
randspawn.get_respawn_pos = get_respawn_position

-- Respawning is no longer random. Instead we chose position based on month.
-- Note: this is also called from the /spawn chatcommand.
randspawn.reposition_player = function(pname, death_pos)
  local player = minetest.get_player_by_name(pname)
  if player then
		-- Ensure teleport is forced, to prevent a cheat.
		local pos = get_respawn_position(death_pos)
		pos = vector.add(pos, {x=math.random(-2, 2), y=0, z=math.random(-2, 2)})
		preload_tp.preload_and_teleport(pname, pos, 32, nil,
			function()
				ambiance.sound_play("respawn", pos, 1.0, 10)
			end, nil, true)
  end
end

minetest.register_on_newplayer(function(player)
  local name = player:get_player_name()
  minetest.after(0.1, function() randspawn.reposition_player(name, {x=0, y=0, z=0}) end)
end)



if not randspawn.run_once then
    -- Reloadable.
    local file = randspawn.modpath .. "/init.lua"
    local name = "randspawn:core"
    reload.register_file(name, file, false)
    
    randspawn.run_once = true
end
