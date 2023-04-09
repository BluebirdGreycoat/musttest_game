
hunger.diet = hunger.diet or {}
hunger.diet.players = hunger.diet.players or {}

local players = hunger.diet.players

function hunger.adjust_from_diet(pname, item, def)
  local ndef = table.copy(def)
  local ctime = os.time()

  -- Create and localize player table if not exists.
  players[pname] = players[pname] or {}
  local info = players[pname]

  local ltime = info[item] or 0
  info[item] = ctime

  -- Barf. You ate too quickly.
  if (ctime - ltime) <= 1 then
    ndef.healing = -1
  end

  return ndef
end

if not hunger.diet.run_once then
  hunger.diet.run_once = true
end
