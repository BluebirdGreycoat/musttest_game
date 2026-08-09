
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
  minetest.safe_file_write(path, str)
end



-- Returns true if box was added to list, nil if nothing to be done.
function mailbox.add_to_list(pos, owner, time)
  pos = vector.round(pos)
  local aboxes = mailbox.boxes
  local vequals = vector.equals

  for k = 1, #aboxes do
    local b = aboxes[k]
    local p = b.pos
    if vequals(pos, p) then
      return -- Box already exists at this position.
    end
  end

  aboxes[#aboxes + 1] = {
    pos = pos,
    owner = owner,
    time = time,
  }

  return true -- Added to list.
end



-- Returns true if box was removed from list, nil if nothing to be done.
function mailbox.remove_from_list(pos)
  pos = vector.round(pos)
  local aboxes = mailbox.boxes
  local vequals = vector.equals

  for k = 1, #aboxes do
    local b = aboxes[k]
    local p = b.pos
    if vequals(pos, p) then
      table.remove(aboxes, k)
      return true -- Done.
    end
  end
end
