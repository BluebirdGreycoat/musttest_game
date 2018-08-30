
readexec = readexec or {}
readexec.modpath = minetest.get_modpath("readexec")
--readexec.infile = "/tmp/minetest-command-input.txt"



--local timer = 0
--local delay = 1
--readexec.run = function(dtime)
--  timer = timer + dtime
--  if timer < delay then return end
--  timer = 0
  
--  local file = io.open(readexec.infile, "r")
--  if file then
--    local data = file:read("*l")
--    if data and string.len(data) > 0 then
--      if string.sub(data, 1, 4) == "/me " then
--        local act = string.sub(data, 5)
--				local dname = rename.gpn("MustTest")
--        minetest.chat_send_all("* <" .. dname .. "> " .. act)
--        chat_logging.log_public_action("MustTest", act, "")
--      elseif string.sub(data, 1, 6) == "/echo " then
--        minetest.chat_send_all("# Server: " .. string.sub(data, 7))
--      else
--				local dname = rename.gpn("MustTest")
--        minetest.chat_send_all("<" .. dname .. "> " .. data)
--        chat_logging.log_public_chat("MustTest", data, "")
--      end
--    end
--    file:close()
--    file = nil
--    os.remove(readexec.infile)
--  end
--end



--if not readexec.registered then
--    minetest.register_globalstep(function(...) return readexec.run(...) end)
--    readexec.registered = true
--end



--if minetest.get_modpath("reload") then
--    local c = "readexec:core"
--    local f = readexec.modpath .. "/init.lua"
--    if not reload.file_registered(c) then
--        reload.register_file(c, f, false)
--    end
--end

