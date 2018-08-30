
mailbox.load = function()
  local path = minetest.get_worldpath() .. "/mailboxes.txt"
  local file = io.open(path, "r")
  if file then
    local data = file:read("*all")
    local db = minetest.deserialize(data)
    file:close()
    if type(db) == "table" then
      mailbox.boxes = db
    end
  end
end



mailbox.save = function()
  local str = minetest.serialize(mailbox.boxes)
  if type(str) ~= "string" then return end -- Failsafe.
  local path = minetest.get_worldpath() .. "/mailboxes.txt"
  local file = io.open(path, "w")
  if file then
    file:write(str)
    file:close()
  end
end
