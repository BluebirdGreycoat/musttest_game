
function hud.read_conf()
	local mod_path = minetest.get_modpath("hud")
	local set = io.open(mod_path .. "/hud.conf", "r")
	if set then
		dofile(mod_path .. "/hud.conf")
		set:close()
	end
end

function hud.notify_hunger(delay, use)
	local txt_part = "enable"
	if use then
		txt_part = "use"
	end
	minetest.after(delay, function()
		minetest.chat_send_all("#Better HUD: You can't " .. txt_part .. " hunger without the \"hunger\" mod")
		minetest.chat_send_all("	Enable it or download it from \"https://github.com/BlockMen/hunger\"")
	end)
end

function hud.player_event(player, event)
  local pname = player:get_player_name() -- Track player by name. Avoid crash.
  
   --needed for first update called by on_join
   minetest.after(0.1, function()
    local plr = minetest.get_player_by_name(pname)
    if not plr then return end
   
    if event == "health_changed" then
      for _,v in pairs(hud.damage_events) do
        if v.func then
          v.func(plr)
        end
      end
    end

    if event == "breath_changed" then
      for _,v in pairs(hud.breath_events) do
        if v.func then
          v.func(plr)
        end
      end
    end

    if event == "hud_changed" then --called when flags changed
    end
  end)
end

core.register_playerevent(hud.player_event)
