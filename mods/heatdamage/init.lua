
heatdamage = heatdamage or {}
heatdamage.modpath = minetest.get_modpath("heatdamage")

-- Localize for performance.
local math_floor = math.floor



heatdamage.immune_players = heatdamage.immune_players or {}
heatdamage.cache_range = 2
heatdamage.scan_range = 2
heatdamage.server_step = 1
heatdamage.environment_cache = heatdamage.environment_cache or {}
heatdamage.cache_hit = heatdamage.cache_hit or 0
heatdamage.cache_miss = heatdamage.cache_miss or 0
heatdamage.cache_clean = 20

heatdamage.immune_players["MustTest"] = {timer=-1}
heatdamage.immune_players["singleplayer"] = {timer=-1}

heatdamage.is_immune = function(pname)
  if heatdamage.immune_players[pname] then
    if heatdamage.immune_players[pname].timer > 0 then
      return true
    end
  end
  return false
end

heatdamage.immunize_player = function(pname, add_seconds)
  assert(add_seconds > 0)
  if heatdamage.immune_players[pname] then
    local timer = heatdamage.immune_players[pname].timer
    if timer >= 0 then
      timer = timer + add_seconds
      heatdamage.immune_players[pname].timer = timer
    end
  else
    heatdamage.immune_players[pname] = {timer=add_seconds}
  end
  
  local total = heatdamage.immune_players[pname].timer
  minetest.chat_send_player(pname, "# Server: You are protected from heat for " .. math_floor(total) .. " seconds.")
end



local is_exposed = function(pos)
    -- Table is ordered for performance.
    local points = {
        {x=pos.x, y=pos.y+1, z=pos.z}, -- Top first. Most common case.
        {x=pos.x-1, y=pos.y, z=pos.z},
        {x=pos.x+1, y=pos.y, z=pos.z},
        {x=pos.x, y=pos.y, z=pos.z-1},
        {x=pos.x, y=pos.y, z=pos.z+1},
        {x=pos.x, y=pos.y-1, z=pos.z},
    }
		local get_node = minetest.get_node
    for i=1, #points do
        local n = get_node(points[i]).name
        if n == "air" then return true end
    end
    return false
end



local vector_round = vector.round
heatdamage.environment_scan = function(pos)
    local cache = heatdamage.environment_cache
    local range = heatdamage.cache_range
    local distance = vector.distance

    -- If this position was scanned already, just return our cached information.
    for k, v in ipairs(cache) do
        if distance(pos, v.pos) < range then
            heatdamage.cache_hit = heatdamage.cache_hit + 1
            return v.counts, v.lava
        end
    end

    local rad = heatdamage.scan_range
    local loc = vector_round(pos)
    
    local ps, counts = minetest.find_nodes_in_area(
        {x=loc.x-rad, y=loc.y-rad, z=loc.z-rad},
        {x=loc.x+rad, y=loc.y+rad, z=loc.z+rad},
        {"group:lava", "group:flame"})
        
    local total = 0
		local lava = 0
    
		local get_node = minetest.get_node
    for k, v in ipairs(ps) do
        local n = get_node(v).name
        if is_exposed(v) then
            if n == "default:lava_source" then
                total = total + 0.2
								lava = lava + 1
            elseif n == "default:lava_flowing" then
                total = total + 0.2
								lava = lava + 1
            elseif n == "lbrim:lava_source" then
                total = total + 0.15
								lava = lava + 1
            elseif n == "lbrim:lava_flowing" then
                total = total + 0.15
								lava = lava + 1
            elseif n == "fire:basic_flame" then
                total = total + 0.06
            elseif n == "fire:nether_flame" then
                total = total + 0.08
            elseif n == "fire:permanent_flame" then
                total = total + 0.06
            end
        end
    end
    
    -- Cache results for next time.
    local idx = #cache + 1
    cache[idx] = {pos=loc, counts=total, lava=lava}
    
    heatdamage.cache_miss = heatdamage.cache_miss + 1
    return total, lava
end



local steptimer = 0
local cachetimer = 0
local serverstep = heatdamage.server_step
local cacheclean = heatdamage.cache_clean



heatdamage.globalstep = function(dtime)
    steptimer = steptimer + dtime
    if steptimer < serverstep then return end
    steptimer = 0
    
    cachetimer = cachetimer + serverstep
    if cachetimer >= cacheclean then
        heatdamage.environment_cache = {}
        heatdamage.cache_hit = 0
        heatdamage.cache_miss = 0
        cachetimer = 0
    end
    
    local floor = math_floor
    local scan = heatdamage.environment_scan
    local players = minetest.get_connected_players()
    
    for k, v in ipairs(players) do
        local name = v:get_player_name()
        if heatdamage.immune_players[name] == nil then
          if v:get_hp() > 0 then -- Don't bother if player already dead.
            -- Scan environment for nearby heat sources capable of causing damage to players.
            local total, lava = scan(v:get_pos())
						total = floor(total + 0.5)
            
            if total > 0 then
							sprint.set_stamina(v, 0)
							v:set_hp(v:get_hp() - total * serverstep)

							if lava and lava > 2 then
								local p = minetest.find_node_near(v:get_pos(), 1, "air", true)
								if p then
									minetest.set_node(p, {name="fire:basic_flame"})
								end
							end

							if v:get_hp() <= 0 then
								-- Player died.
								if player_labels.query_nametag_onoff(name) == true and not cloaking.is_cloaked(name) then
									minetest.chat_send_all("# Server: <" .. rename.gpn(name) .. "> caught fire.")
								else
									minetest.chat_send_all("# Server: Someone caught fire.")
								end
							end
            end
          end
        end
    end
    
    local removenames = {}
    for k, v in pairs(heatdamage.immune_players) do
      if v.timer > 0 then
        v.timer = v.timer - serverstep
        if v.timer <= 0 then
          removenames[k] = true
          minetest.chat_send_player(k, "# Server: Your protection from heat fades away.")
        end
      end
    end
    
    for k, v in pairs(removenames) do
      heatdamage.immune_players[k] = nil
    end
end



if not heatdamage.run_once then
	minetest.register_globalstep(function(...) return heatdamage.globalstep(...) end)

	local c = "heatdamage:core"
	local f = heatdamage.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	heatdamage.run_once = true
end


