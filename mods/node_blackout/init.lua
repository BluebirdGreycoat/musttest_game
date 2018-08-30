
-- Don't blackout nodes in singleplayer mode to allow easier debugging.
if not minetest.is_singleplayer() then
  local really_register_node = minetest.register_node
  local new_register_node = function(name, def)
    if not def.drawtype then def.drawtype = "normal" end
    if def.drawtype == "normal" then
      if not def.post_effect_color then
        def.post_effect_color = {a=255, r=0, g=0, b=0}
      end
    end
    
    really_register_node(name, def)
  end
  minetest.register_node = new_register_node
end
