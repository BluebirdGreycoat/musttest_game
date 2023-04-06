
if not minetest.global_exists("reboot") then reboot = {} end
reboot.modpath = minetest.get_modpath("reboot")



-- Support for 'reload', so the server operator can modify the reboot code
-- even while the server is running, if that becomes necessary.
dofile(reboot.modpath .. "/reboot.lua")



if not reboot.run_once then
  local c = "reboot:core"
  local f = reboot.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
  reboot.run_once = true
end
