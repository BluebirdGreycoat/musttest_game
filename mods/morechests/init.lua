
if not minetest.global_exists("morechests") then morechests = {} end
morechests.modpath = minetest.get_modpath("morechests")

dofile(morechests.modpath .. "/nodes.lua")
dofile(morechests.modpath .. "/crafts.lua")

if minetest.get_modpath("easyvend") then
  easyvend.register_chest("morechests:woodchest_locked_open", "main", "owner")
  easyvend.register_chest("morechests:woodchest_locked_closed", "main", "owner")
  
  easyvend.register_chest("morechests:copperchest_locked_open", "main", "owner")
  easyvend.register_chest("morechests:copperchest_locked_closed", "main", "owner")
  
  easyvend.register_chest("morechests:diamondchest_locked_open", "main", "owner")
  easyvend.register_chest("morechests:diamondchest_locked_closed", "main", "owner")

  easyvend.register_chest("morechests:ironchest_locked_open", "main", "owner")
  easyvend.register_chest("morechests:ironchest_locked_closed", "main", "owner")
  
  easyvend.register_chest("morechests:goldchest_locked_open", "main", "owner")
  easyvend.register_chest("morechests:goldchest_locked_closed", "main", "owner")
  
  easyvend.register_chest("morechests:silverchest_locked_open", "main", "owner")
  easyvend.register_chest("morechests:silverchest_locked_closed", "main", "owner")
  
  easyvend.register_chest("morechests:mithrilchest_locked_open", "main", "owner")
  easyvend.register_chest("morechests:mithrilchest_locked_closed", "main", "owner")
end
