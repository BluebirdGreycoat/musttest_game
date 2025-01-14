
if not minetest.global_exists("player_labels") then player_labels = {} end
player_labels.modpath = minetest.get_modpath("player_labels")

-- Timeout settings.
player_labels.mark_timeout = 60
player_labels.chat_timeout = 10
player_labels.anim_timeout = 1

-- State tables.
player_labels.mark = player_labels.mark or {} -- Nametag display `reference` counts.
player_labels.cast = player_labels.cast or {} -- Whether the player has deliberately turned off their nametag.



-- Called by the rename mod to update a player's nametag when they rename themselves.
-- If the player's nametag is currently displayed, this should rewrite it.
-- Otherwise, we don't need to do anything, since it will be rewritten automatically
-- when it is next displayed.
function player_labels.update_nametag_text(pname)
	if player_labels.query_nametag_onoff(pname) then
		-- Player's nametag is currently on.
		return
	end

	-- Get player.
	local player = minetest.get_player_by_name(pname)
	if not player then
		return
	end

	-- Update nametag.
	pova.update_modifier(player, "nametag", {text=rename.gpn(pname)}, "id_mark")
end



-- Increment nametag refcount, return new value.
local refcount_increment = function(name)
  local count = player_labels.mark[name]
  count = count + 1
  player_labels.mark[name] = count
  return count
end

-- Decrement nametag refcount, return new value.
local refcount_decrement = function(name)
  local count = player_labels.mark[name]
  count = count - 1
  player_labels.mark[name] = count
  return count
end



local refcount_get = function(name)
  return player_labels.mark[name]
end

local refcount_set = function(name, count)
  player_labels.mark[name] = count
end



-- Unconditionally show/hide player's nametag.
local nametag_show = function(name)
  local obj = minetest.get_player_by_name(name)
  if obj and obj:is_player() then
    --local col = {a=255, r=0, g=255, b=255}
    --local txt = rename.gpn(obj:get_player_name())
		pova.remove_modifier(obj, "nametag", "id_mark")
		pova.remove_modifier(obj, "properties", "id_mark")
  end
end

local nametag_hide = function(name)
  local obj = minetest.get_player_by_name(name)
  if obj and obj:is_player() then
    local col = {a=0, r=0, g=0, b=0}
    local txt = ""

    pova.set_modifier(obj, "nametag", {color=col, text=txt}, "id_mark")
    pova.set_modifier(obj, "properties", {show_on_minimap = false}, "id_mark")
  end
end



-- Persist player_labels.cast state into player's metadata. The inverted state
-- is stored, so that absence of the key in player's metadata makes the nametag
-- visible by default.
local function persist_cast(pname)
  local player = minetest.get_player_by_name(pname)
  local plmeta = player:get_meta()

  if player_labels.cast[pname] then
    plmeta:set_string("hides_nametag", "") -- Removes the key.
  else
    plmeta:set_int("hides_nametag", 1)
  end
end



-- Public API function.
-- Returns 'true' if the player's nametag is ON.
-- Returns 'false' if the player's nametag is OFF.
-- Returns 'nil' if the player's nametag state cannot be determined (player doesn't exist, or other error).
-- This is called from the `bones` mod for instance, to decide whether to tell everyone about the bones.
player_labels.query_nametag_onoff = function(name)
  assert(type(name) == "string")
  local res = nil
  if player_labels.cast[name] ~= nil then -- Stupid booleans don't mix with nil, so need explicit check.
    res = player_labels.cast[name]
    if refcount_get(name) > 0 then
      res = true
    end
  end
  return res
end



-- Set up default state for new players.
player_labels.on_joinplayer = function(player)
  local pname = player:get_player_name()

  -- Start fresh.
  player_labels.cast[pname] = true
  player_labels.mark[pname] = 0

  -- Restore previous state.
  if player:get_meta():get_int("hides_nametag") ~= 0 then
    player_labels.cast[pname] = false
  end

  -- Player labels are shown according to restored state.
  if player_labels.cast[pname] then
    nametag_show(pname)
  else
    -- After welcome msg, before joinspec and email.
    minetest.after(5, function(pn)
      minetest.chat_send_player(pn, "# Server: Avatar name broadcast is OFF.")
    end, pname)
    nametag_hide(pname)
  end
end



-- Called when the player uses a `player labels token`.
player_labels.toggle_nametag_broadcast = function(name)
  if player_labels.cast[name] then
    minetest.chat_send_player(name, "# Server: Avatar name broadcast is OFF.")
    player_labels.cast[name] = false
    player_labels.disable_nametag_broadcast(name)
  else
    minetest.chat_send_player(name, "# Server: Avatar name broadcast is ON.")
    player_labels.cast[name] = true
    player_labels.enable_nametag_broadcast(name)
  end
  persist_cast(name)
end

function player_labels.enable_nametag(pname)
	player_labels.cast[pname] = true
	player_labels.enable_nametag_broadcast(pname)
  persist_cast(pname)
end

function player_labels.disable_nametag(pname)
	player_labels.cast[pname] = false
	player_labels.disable_nametag_broadcast(pname)
  persist_cast(pname)
end



player_labels.enable_nametag_broadcast = function(name)
  if player_labels.cast[name] == true then
    nametag_show(name)
  end
end



player_labels.disable_nametag_broadcast = function(name)
  if player_labels.cast[name] == false then
    if refcount_get(name) <= 0 then
      nametag_hide(name)
    end
  end
end



-- A delayed action function, for hiding a players name (if needed) after some delay.
-- Called from `minetest.after`.
player_labels.on_tag_timeout = function(name)
  local count = refcount_decrement(name)
  if count <= 0 then
    refcount_set(name, 0)
    
    if not player_labels.cast[name] then
      nametag_hide(name)
    end
  end
end



--[[
player_labels.on_anim_timeout = function(name)
    local object = minetest.get_player_by_name(name)
    if object and object:is_player() then
        local fr = object:get_animation()
        if fr.x == 221 and fr.y == 251 then -- If still bobbing head.
            object:set_animation({x=0, y=79}, 30, 0, true)
        end
    end
end
--]]



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


-- This function is called whenever the player uses the ID token.
player_labels.on_token_use = function(itemstack, user, pointed_thing)
  if not user then return end
  if not user:is_player() then return end
  local pname = user:get_player_name()

  if pointed_thing.type == "object" then
    local object = pointed_thing.ref
    if object:is_player() and not gdac.player_is_admin(object) then
      local uname = user:get_player_name()
      local oname = object:get_player_name()

      -- Protection for cloaked users.
      if gdac_invis.is_invisible(oname) == true then return end
      if cloaking.is_cloaked(oname) then return end

      -- Protection against random noob acounts using this ...
      if not passport.player_has_key(uname, user) then return end

      local xp_amount = xp.get_xp(oname, "digxp")
      local info = minetest.get_player_information(oname)

      if not info then
        minetest.chat_send_player(uname, "# Server: error getting target information.")
        return
      end

      local vpn = anti_vpn.get_vpn_data_for(info.address) or {}

      -- No info that could lead to doxing, please.
      -- RTT is potentially hazardous for a non-VPN user.
      -- No TZ, that narrows location too much.
      -- Unify VPN/proxy/tor/relay/hosting into one line.
      local tb = {
        "Mineral XP:        " .. string.format("%.3f", xp_amount),
        "Connection Uptime: " .. info.connection_uptime,
        "Protocol Version:  " .. info.protocol_version,
        "Formspec Version:  " .. info.formspec_version,
        "Language Code:     " .. get_stringna(info.lang_code),
        "Login Name:        " .. rename.grn(oname),
        "VPN Last Updated:  " .. ((vpn.created and os.date("!%Y-%m-%d", vpn.created)) or "Never"),
        "Country:           " .. get_stringna(vpn.country),
        "Continent:         " .. get_stringna(vpn.continent),
        "EU Vassal Slave:   " .. get_truefalse(vpn.is_in_eu), -- Have to put some humor in this. >:[
        "Stealth Mode:      " .. get_truefalse(vpn.is_vpn or vpn.is_tor or vpn.is_proxy or vpn.is_relay or vpn.is_hosting),
        "Mobile Connection: " .. get_truefalse(vpn.is_mobile),
      }

      minetest.chat_send_player(uname, "# Server: INFO for account <" .. rename.gpn(oname) .. ">:")
      for k, v in ipairs(tb) do
        minetest.chat_send_player(uname, "# Server:     " .. v)
      end

      -- Inform victim.
      minetest.chat_send_player(oname, "# Server: Entity <" .. rename.gpn(uname) .. "> identified you.")

      refcount_increment(oname)
      nametag_show(oname)
      minetest.after(player_labels.mark_timeout, player_labels.on_tag_timeout, oname)

      return
    end
  end

  if gdac_invis.is_invisible(pname) == true then
    minetest.chat_send_player(pname, "# Server: You are currently invisible! Being invisible already hides your nametag.")
    minetest.chat_send_player(pname, "# Server: If you want to show your nametag again, stop being invisible.")
    easyvend.sound_error(pname)
    return
  end

  if cloaking.is_cloaked(pname) then
    minetest.chat_send_player(pname, "# Server: You are currently cloaked! Being cloaked already hides your nametag.")
    minetest.chat_send_player(pname, "# Server: If you want to show your nametag again, turn of your cloak.")
    easyvend.sound_error(pname)
    return
  end

  player_labels.toggle_nametag_broadcast(pname)
  return
end



-- This function gets called from another mod whenever the player sends a chat message.
player_labels.on_chat_message = function(name, message)
  if gdac_invis.is_invisible(name) then return end
  
  local object = minetest.get_player_by_name(name)
  if object and object:is_player() then
    --object:set_animation({x=189, y=198}, 30, 0, true)
    --object:set_animation({x=221, y=251}, 30, 0, true)
    --minetest.after(player_labels.anim_timeout, player_labels.on_anim_timeout, name)
    
    refcount_increment(name)
    nametag_show(name)
    minetest.after(player_labels.chat_timeout, player_labels.on_tag_timeout, name)
  end
end



-- First-time execution only.
if not player_labels.registered then
  minetest.register_on_joinplayer(function(...) return player_labels.on_joinplayer(...) end)
  
  minetest.register_craftitem("player_labels:show", {
    description = "ID Marker\n\nUse this to see someone's name, if suspicious of impersonation.\nThis can also show or hide your own name.",
    inventory_image = "default_copper_block.png",
    --range = 10, -- Disabled because this allows players to access formspecs from long range.
    on_use = function(...) return player_labels.on_token_use(...) end,
    
    -- Disabled because these attempts to disable right-click functionality do not appear to work.
    --on_rightclick = function(...) end,
    --on_secondary_use = function(...) end,
    --on_place = function(...) end,
  })

  minetest.register_craft({
    output = 'player_labels:show',
    recipe = {
      {"", "default:copper_ingot", ""},
      {"default:copper_ingot", "", "default:copper_ingot"},
      {"", "default:copper_ingot", ""},
    },
  })

  player_labels.registered = true
end



-- Support for reloading.
if minetest.get_modpath("reload") then
  local c = "player_labels:core"
  local f = player_labels.modpath .. "/init.lua"
  if not reload.file_registered(c) then
    reload.register_file(c, f, false)
  end
end
