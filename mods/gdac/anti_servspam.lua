
if not minetest.global_exists("spam") then spam = {} end
spam.keys = spam.keys or {}
spam.ips = spam.ips or {}



local spamkeys = spam.keys

-- Return 'true' if key was recently marked. Otherwise, return 'false'.
function spam.test_key(key)
  local last = spamkeys[key] or 0
  if os.time() < last then
    return true
  end

  spamkeys[key] = nil
  return false
end

-- Mark 'key' as not to be used again for 'time' seconds (starting from now).
function spam.mark_key(key, time)
  time = time or 60
  spamkeys[key] = os.time() + time
end



local spamips = spam.ips

function spam.should_block_player(pname, ip)
  -- Don't slow dev testing down. I'm on the clock, here!
  --if ip == "127.0.0.1" or ip == "0.0.0.0" then
  --  return false
  --end

  -- Should block from joining too quick only if someone else logged in with same IP already.
  if spamips[ip] then
    return true
  end

  return false
end



function spam.on_prejoinplayer(name, ip)
  -- Needed for debugging/testing.
  --if name == "bobman" then
  --  return "Go away please."
  --end

  local last = spamips[ip] or 0

  if os.time() < last and spam.should_block_player(name, ip) then
    return "The path is narrow and crowded. Perhaps you should wait awhile ..."
  end
end

-- Block anyone from the same IP as player (by name) from joining for some time.
function spam.block_playerjoin(pname, time)
  local pref = minetest.get_player_by_name(pname)
  if not pref then
    return
  end

  local ip = minetest.get_player_ip(pname)
  if not ip then
    return
  end

  time = time or 60
  spamips[ip] = os.time() + time
end



-- Only block future logins from this IP only if they successfully logged in the first time.
function spam.on_joinplayer(pref, last_login)
  local ip = minetest.get_player_ip(pref:get_player_name())
  spamips[ip] = os.time() + 30
end



if not spam.run_once then
  spam.run_once = true

  minetest.register_on_prejoinplayer(function(...)
    return spam.on_prejoinplayer(...) end)

  minetest.register_on_joinplayer(function(...)
    return spam.on_joinplayer(...) end)
end
