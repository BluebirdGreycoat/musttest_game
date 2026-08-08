
if not minetest.global_exists("readexec") then readexec = {} end
readexec.modpath = minetest.get_modpath("readexec")
reload.install_simple_signals(readexec)
