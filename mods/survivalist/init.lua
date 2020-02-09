
survivalist = survivalist or {}
survivalist.modpath = minetest.get_modpath("survivalist")
survivalist.players = survivalist.players or {}
survivalist.groups = survivalist.groups or {}

-- Positions of surface & nether cities.
local surfacecitypos = {x=0, y=-8, z=0}
local nethercitypos = {x=0, y=-30793, z=0}

-- Valid gamemodes are 'surface', 'cave', & 'nether'.



-- The game rules description. Shown in formspec.
survivalist.gamerules = 
  "===| Survival Challenge Description |===\n\n" ..
  "This page contains the rules for this mini-game, with options to begin a Challenge or claim victory on a Challenge currently in-progress.\n\n" ..
  "The Survival Challenge focuses on survival in the wild far from developed regions. You can play it solo or with other players.\n\n" ..
	"You will need to scroll this text in order to read all of it.\n\n" ..
	"When beginning a Challenge it is possible to end up in a starting situation where survival is impossible. You always have the option to cancel without affecting your score.\n\n" ..
	"On accepting a challenge you are transported into a small dungeon, which is at a distant location in the world very far from the Surface Colony and the Nether City. The minimum distance you’ll be teleported is 10,000 meters; the server will not choose a dungeon closer to either city than this. You’ll have the basic starting items that every player starts with when they first join the server, and the dungeon has a chest containing additional items to make getting a head-start a little easier, since otherwise some scenarios would be impossible to beat. The chest contents differ between challenge types and are somewhat random.\n\n" ..
  "Before you can begin a challenge all your inventories must be empty: your main inventory, your craft grid, the craft-preview and craft-output inventory slots (yes, those too, cheaters!), your Star-Fissure Box, your armor inventory, your bags, and the wielditem inventory (if you don’t know what this is, then don’t worry about it). Proof of Citizenship tokens are exempt.\n\n" ..
	"You can play this mini-game cooperatively. To do so one player should to start a Survival Challenge just as if they were going to play solo. Whenever a player starts a Challenge there is a 5 minute window in which other players can join the first player by being transported to the same dungeon. To join another player in their dungeon, you must stand within 5 meters of the place where they stood at the time they began their Challenge. You must also choose the same gamemode (Iceworld, Underearth, or Netherealm) as the first player. If you are too far away, or you choose a wrong gamemode, or the 5 minute window has passed, you won’t be transported to the same dungeon. If you are are unsuccessful and are not teleported to the same dungeon, you can simply cancel and try again if you wish. There is no limit on the number of players who may play cooperatively. Every player who joins extends the 5-minute window a bit. Do note that supplies are not increased with each player beyond the first, so you’ll need to share. Players win or lose the Challenge separately, so if one player has a fatal accident, the remaining players can keep playing.\n\n" ..
  "Finding a suitable location to build the starting dungeon can take the server some time, so you have a few seconds to interact with the world after accepting a challenge. Don’t rely on this, though.\n\n" ..
  "(Note to builders in distant lands: the server will not overwrite any of your builds when creating a player’s starting dungeon, as long as your builds are protected. Although the world is vast and the chance of randomly selecting a location inside someone else’s home is small, the server nonetheless performs checks to avoid accidents.)\n\n" ..
  "In order to win after starting a challenge, you must find your way back to the Surface Colony OR the Nether City and claim victory (press the ‘Claim Victory’ button below these rules) in the Central Square of either location. Finding civilization to claim victory is your goal; avoiding a fatal death during your travels in the wild is your challenge. Rules for death are below the Challenge descriptions.\n\n" ..
  "Note that you may to use your Proof of Citizenship to teleport you the rest of the way to the Surface Colony or Nether City once you are in range of the teleport beacons. Use of diamond teleporters is also allowed, as are flameportals which go to and from the Netherealm, or any other form of transportation. However, when starting a challenge your flameportal’s previous return position (if you had one set) is erased to prevent using a return portal as a ‘cheat’ to obtain an easy win. The same is true for beds.\n\n" ..
  "There are three challenge types: the Iceworld Challenge, the Underearth Challenge, and the Netherealm Challenge, with difficulty being in that order. Each challenge awards Skill Marks when victory is successfully claimed. The Skill Marks are Copper, Silver, and Gold. The amount of marks you’ll receive on successful completion of a challenge depends on the distance you travel to either the Surface Colony or the Nether City, starting from your initial dungeon. You receive 1 mark for every 1K meters of distance (rounded down), minus the first 10 kilometers. You always receive at least 1 Skill Mark.\n\n" ..
  "The following is a basic description of each challenge.\n\n" ..
  "In the Iceworld Challenge you start in an ice-and-brick dungeon at what is normally sea-level (if this server were to have a liquid sea). Chances are, you’ll be under a mountain or below a raised plain, so your first goal will be to dig up and find the surface. If you are very lucky you will be on an ice-lake instead. Avoid the icemen and don’t go out at night! This is the easiest challenge. The first time you complete it successfully, the skill learned causes your wield-hotbar (the 8 itemslots below your health and hunger stats) to expand to 16 slots for easier building. (Note: if you prefer the regular 8 slots anyway and don’t want the bigger version, you can let the server administrator know, to get it reset back to 8 slots!)\n\n" ..
  "In the Underearth Challenge you start in a cobble dungeon deep under the earth, between -24K and -3K. Since you are underground, your first priority is using the materials in the starting chest to build a small farm. Note that the server never locates a dungeon to be floating in the middle of a caverealm void, but it is remotely possible that you could have lava outside the dungeon walls. Once you have a food source, the main difficulty is digging your way to the surface or to the nether (if you choose to claim victory in the Nether City). Beware of mining instabilities! Note that this Challenge typically takes the longest to complete. Once you’ve established a base with a bed, consider using Obsidian Gateways to try and bring yourself closer to the surface. The first time you complete this Challenge, you unlock a hidden feature of the Key of Citizenship which allows you to jaunt (teleport) to other players who also possess a Key—provided their Key’s beacon signal can be successfully triangulated ….\n\n" ..
  "The Netherealm Challenge is mostly similar to the Underearth Challenge, except that your starting dungeon is located in the second-worst place in the world, some 60 meters under the brimstone ocean. (The worst place in the world is the islands directly above all that lava.) Your starting dungeon is made of black rackstone, but don’t imagine you’ll be able to use it for anything except stone picks. You need to be very, very careful in this challenge, because lava is everywhere, and netherack is nasty to dig. There are very few usable resources in the nether, so finding the few resources you can is very important. The first thing you need to do is dig up to the islands without letting the brimstone ocean flow into your dungeon. Once there you can explore the brimstone cavern for a few meager resources. In this Challenge, you are recommended to claim victory in the Nether City rather than attempt to dig to the surface. However, those who dig to the surface will receive more reward. If you choose to dig up out of the nether into normal rock you’ll be able to find a few more resources, and the caverealms of the Underearth Challenge will seem like a garden. :-)\n\n" ..
  "After starting a Challenge you may cancel it without affecting your death/success score. This option is available as long as a Challenge is running. The conditions for canceling a challenge are the same as the conditions for starting one: all your inventories must be empty except for passport tokens. (You cannot bring anything with you when you cancel.) You may choose this option if, for instance, you do not like your starting situation. When you cancel a Challenge you are returned to the same spot you were when you began the Challenge.\n\n" ..
	"Rules for death: you lose the Challenge if you die and have not slept in a bed. Lacking a bed is your initial state whenever you begin a Challenge, and you avoid losing the Challenge by crafting a bed and sleeping in it. Afterwards if you die you will respawn in your bed and the Challenge will continue as before. Note that a bed is only good for a limited number of respawns, so you should remember to sleep often to refresh it.\n\n" ..
	"Warning: since your bed is lost if you are killed by another player (but not by a mob or the environment), the effect of being murdered is that you will fail the Challenge. Your murderer does not get any special benefits other than hearing your screams of fury.\n\n" ..
	"Each player’s total number of victories, fatal deaths, and victory streaks are recorded permanently, as well as the number of victories in the three individual challenges, and the total number of marks earned. This information is never reset.\n\n" ..
  "===| Challenge Description End |==="



-- Add player to a list of players contained in the database.
-- This is because we can't iterate over the database entries directly,
-- so we need a way to find all players who have ranking entries.
function survivalist.add_player_to_rankings(pname)
  -- Obtain the database in string form.
  local data = survivalist.modstorage:get_string(":ranked_players:")
  -- If the string is empty, create a dummy table for deserialization.
  if data == "" then
    data = "return {}"
  end
  -- Deserialize the rankings database into a table.
  local tb = minetest.deserialize(data)
  -- Add player to table.
  tb[pname] = true
  -- Reserialize the database table.
  local serialized = minetest.serialize(tb)
  -- Don't overwrite the old database unless the table serialized successfully.
  if type(serialized) == "string" then
    survivalist.modstorage:set_string(":ranked_players:", serialized)
  end
end



function survivalist.get_ranking_entries()
  -- Obtain the database in string form.
  local data = survivalist.modstorage:get_string(":ranked_players:")
  -- If the string is empty, create a dummy table for deserialization.
  if data == "" then
    data = "return {}"
  end
  -- Deserialize the rankings database into a table.
  local tb = minetest.deserialize(data)
  -- Return the table.
  return tb or {}
end



function survivalist.inventory_empty(inv, name)
  local count = 0
  for i = 1, inv:get_size(name) do
    local stack = inv:get_stack(name, i)
    if not passport.is_passport(stack:get_name()) then
      if stack:get_count() > 0 then
        count = count + stack:get_count()
      end
    end
  end
  return (count == 0)
end



function survivalist.check_inventories_empty(pname)
  local player = minetest.get_player_by_name(pname)
  if not player then
    return
  end
  local inv = player:get_inventory()
  if survivalist.inventory_empty(inv, "main") and
     survivalist.inventory_empty(inv, "craft") and
     survivalist.inventory_empty(inv, "armor") and
     survivalist.inventory_empty(inv, "voidchest:voidchest") and
     survivalist.inventory_empty(inv, "craftresult") and
     survivalist.inventory_empty(inv, "craftpreview") and
     survivalist.inventory_empty(inv, "bag1contents") and
     survivalist.inventory_empty(inv, "bag2contents") and
     survivalist.inventory_empty(inv, "bag3contents") and
     survivalist.inventory_empty(inv, "bag4contents") and
		 survivalist.inventory_empty(inv, "xchest") and
     survivalist.inventory_empty(inv, "bag1") and
     survivalist.inventory_empty(inv, "bag2") and
     survivalist.inventory_empty(inv, "bag3") and
     survivalist.inventory_empty(inv, "bag4") then
    return true
  end
end



function survivalist.fill_loot_chest(inv, gamemode)
	if not inv then
		return
	end
  local loot = {}
  
  if gamemode == "surface" then
    -- The main problem with the `surface` challenge is keeping it from being too easy.
    -- This is especially due to travel being very swift, and too much food can go a long way.
    loot = {
      {item="default:stick", min=1, max=20},
      {item="farming:bread", min=1, max=10},
      {item="basictrees:tree_apple", min=1, max=20},
      {item="pumpkin:bread", min=1, max=10},
      {item="default:steel_ingot", min=3, max=15},
      {item="default:diamond", min=1, max=8},
      {item="bones:bones_type2", min=1, max=25},
      {item="torches:torch_floor", min=10, max=30},
    }
  elseif gamemode == "cave" then
    -- The challenge of `cave` mode is building a farm to make food and keep going.
    -- Finding sources of iron and coal are critical. Farm supplies have to be provided
    -- right away because otherwise the gamemode would probably be impossible.
    loot = {
      {item="default:stick", min=10, max=30},
      {item="farming:bread", min=10, max=20},
      {item="basictrees:tree_apple", min=10, max=20},
      {item="pumpkin:bread", min=10, max=20},
      {item="default:steel_ingot", min=30, max=64},
      {item="bones:bones_type2", min=10, max=40},
      {item="default:dirt", min=3, max=6},
      {item="torches:torch_floor", min=10, max=30},
      {item="bucket:bucket_water", min=1, max=4},
      {item="default:grass_dummy", min=1, max=10},
      {item="moreblocks:super_glow_glass", min=6, max=10},
      {item="rackstone:dauthsand", min=3, max=6},
      {item="firetree:sapling", min=1, max=2},
      {item="griefer:grieferstone", min=1, max=4},
      {item="titanium:crystal", min=3, max=8},
    }
  elseif gamemode == "nether" then
    -- Like `cave` mode, in this gamemode building a farm and finding sources of iron and coal are critical.
    loot = {
      {item="default:stick", min=1, max=30},
      {item="farming:bread", min=10, max=30},
      {item="basictrees:tree_apple", min=10, max=20},
      {item="default:steel_ingot", min=30, max=64},
      {item="default:coal_lump", min=30, max=64},
      {item="gems:ruby_gem", min=3, max=13},
      {item="torches:kalite_torch_floor", min=10, max=25},
      {item="moreblocks:super_glow_glass", min=3, max=10},
      {item="rackstone:dauthsand", min=3, max=6},
      {item="firetree:sapling", min=1, max=2},
      {item="default:flint", min=5, max=16},
      {item="bluegrass:seed", min=3, max=16},
      {item="griefer:grieferstone", min=1, max=4},
      {item="titanium:crystal", min=1, max=8},
      {item="default:cobble", min=1, max=64},
      {item="beds:fancy_bed_bottom", min=1, max=3},
    }
  end

	local loot_tries = #loot * 3
	for i=1, loot_tries, 1 do
		-- Randomize the order in which loot is applied.
		local v = loot[math.random(1, #loot)]

		-- Divide min/max by 3 (logic is applied 3 times). This splits stacks up.
    local min = math.floor(v.min / 3.0)
    local max = math.ceil(v.max / 3.0)
		if max > min then
			local count = math.floor(math.random(min, max))
			if count > 0 then
				inv:set_stack("main", math.random(1, 12*4), ItemStack(v.item .. " " .. count))
			end
		end
  end
end



-- Actually teleport the player to the start location and announce in chat.
-- Also, record that the game has begun.
function survivalist.teleport_and_announce(pname, pos, gamemode)
  local player = minetest.get_player_by_name(pname)
  if not player then
    return
  end
  
  -- Player's inventories must be empty.
  if not survivalist.check_inventories_empty(pname) then
    minetest.chat_send_player(pname, "# Server: All your inventories (including the Starfissure Box and armor) must be empty before you can begin a challenge (the Proof of Citizenship does not count). You will receive starting items when you begin.")
		easyvend.sound_error(pname)
    return
  end

	-- Abort if player is trying to cheat by sitting in a cart. >:)
	if default.player_attached[pname] then
		minetest.chat_send_player(pname, "# Server: Transport error. Player attached!")
		return
	end

	-- Record home position.
	local homepos = vector.round(player:get_pos())

  -- Teleport player.
	wield3d.on_teleport()
  player:set_pos(vector.add(pos, {x=math.random(-3, 3), y=0.5, z=math.random(-3, 3)}))
  
  -- Make sure player is healthy.
  heal.heal_health_and_hunger(pname)
  
  -- Remove posibility of cheating via netherportals.
  flameportal.clear_return_location(pname)

	-- Clear bed respawn position. Player must make new bed to survive.
	beds.clear_player_spawn(pname)
  
  -- Give the game name some interesting names.
  local gamestring = "Void"
  if gamemode == "surface" then
    gamestring = "Iceworld"
  elseif gamemode == "cave" then
    gamestring = "Underearth"
  elseif gamemode == "nether" then
    gamestring = "Netherealm"
  end
  
  -- Inform player the game has begun.
	if not gdac.player_is_admin(pname) then
		local dname = rename.gpn(pname)
		minetest.chat_send_all("# Server: Player <" .. dname .. "> has begun a test of skill in the " .. gamestring .. " at " .. rc.pos_to_namestr(vector.round(pos)) .. "!")
	else
		minetest.chat_send_player(pname, "# Server: You have begun a test of skill in the " .. gamestring .. " at " .. rc.pos_to_namestr(vector.round(pos)) .. "!")
	end
  survivalist.shout_player_stats(pname)
  minetest.chat_send_player(pname, "# Server: To win, you must find the city and claim victory in the Main Square. If you die without sleeping, you will fail the Challenge.")
  
  -- Give player the starting items.
  give_initial_stuff.give(player)
  
  -- Record the player's new gamemode.
  survivalist.modstorage:set_string(pname .. ":mode", gamemode)
  
  -- Record the player's starting position.
  survivalist.modstorage:set_string(pname .. ":pos", minetest.pos_to_string(vector.round(pos)))

	-- Record the player's home position. Used when canceling a Challenge.
	survivalist.modstorage:set_string(pname .. ":home", minetest.pos_to_string(homepos))

	-- Record that this player is accepting groups.
	survivalist.groups[pname] = survivalist.groups[pname] or {count=0}
	survivalist.groups[pname].count = survivalist.groups[pname].count + 1
	minetest.after(60*5, function()
		if survivalist.groups[pname] then
			survivalist.groups[pname].count = survivalist.groups[pname].count - 1
			if survivalist.groups[pname].count <= 0 then
				survivalist.groups[pname] = nil
			end
		end
	end)
end



-- This function must find a location for the player and teleport them there.
-- Also create a starting dungeon (must not destroy protected stuff) and a chest with extra resources.
function survivalist.prepare_dungeon(pname, pos, gamemode)
  -- Positions to load. Need a larger area in order to make sure any protections are discovered.
  local minp = vector.add(pos, vector.new(-64, -64, -64))
  local maxp = vector.add(pos, vector.new(64, 64, 64))
  
  -- Dungeon coordinates.
  local dminp = vector.add(pos, vector.new(-4, 0, -4))
  local dmaxp = vector.add(pos, vector.new(4, 4, 4))
  
  -- Copy the position table so it doesn't get modified.
  local pos2 = table.copy(pos)
  
  -- Build callback function. When the map is loaded, we need to check protections and create the dungeon.
  local tbparam = {}
  local cb = function(blockpos, action, calls_remaining, param)
		if action == core.EMERGE_CANCELLED or action == core.EMERGE_ERRORED then
			minetest.chat_send_player(pname, "# Server: Internal error, try again or report.")
			easyvend.sound_error(pname)
			return
		end

    -- We don't do anything until the last callback.
    if calls_remaining ~= 0 then
      return
    end
    
    -- Check for protections, and if there are none, create a dungeon.
    for x = dminp.x, dmaxp.x, 1 do
      for y = dminp.y, dmaxp.y, 1 do
        for z = dminp.z, dmaxp.z, 1 do
          if minetest.test_protection({x=x, y=y, z=z}, "") then
            -- Return failure if target is protected. This shouldn't happen often.
            minetest.chat_send_player(pname, "# Server: Error: did not succeed in finding a suitable start location! If this happens, just try again.")
						easyvend.sound_error(pname)
            return
          end
        end
      end
    end
    
    -- Check if spawning in air.
    if minetest.get_node(pos2).name == "air" then
      minetest.chat_send_player(pname, "# Server: Error: did not succeed in finding a suitable start location! If this happens, just try again.")
			easyvend.sound_error(pname)
      return
    end

    -- No protections? Create the dungeon.
    -- Generate dungeon for the player to spawn in.
    local path = survivalist.modpath .. "/schematics/survivalist_" .. gamemode .. "_dungeon.mts"
    minetest.place_schematic(vector.add(pos2, {x=-4, y=0, z=-4}), path, "random", nil, true)
    
    -- Choose a location for the chest.
    local chestpos = vector.add(pos2, vector.new(math.random(-3, 3), 1, math.random(-3, 3)))
		chestpos = vector.round(chestpos)
    
    -- Create chest with stuff.
    minetest.set_node(chestpos, {name="morechests:goldchest_public_closed"})
    local meta = minetest.get_meta(chestpos)
    local inv = meta:get_inventory()
		if inv then
			survivalist.fill_loot_chest(inv, gamemode)
		end
    
    -- Teleport player and announce.
    survivalist.teleport_and_announce(pname, pos2, gamemode)
  end
  
  -- Emerge the target area. Once emergence is complete the dungeon will spawn.
  minetest.chat_send_player(pname, "# Server: Checking reliability of target location ... please stand by, this can take several seconds.")
  minetest.emerge_area(minp, maxp, cb, tbparam)
end



function survivalist.shout_player_stats(pname)
  local ms = survivalist.modstorage
  local wins_total =    pname .. ":wins_total"
  local wins_streak =   pname .. ":wins_streak"
  local wins_surface =  pname .. ":wins_surface"
  local wins_cave =     pname .. ":wins_cave"
  local wins_nether =   pname .. ":wins_nether"
  local wins_fail =     pname .. ":wins_fail"
  local wins_bstreak =  pname .. ":wins_bstreak"
  local wins_tokens =   pname .. ":wins_tokens"
  
	if not gdac.player_is_admin(pname) then
		local dname = rename.gpn(pname)
		minetest.chat_send_all("# Server: Survivalist stats for <" ..
			dname .. ">: Victories: " .. ms:get_int(wins_total) ..
			". Deaths: " .. ms:get_int(wins_fail) ..
			". Iceworld: " .. ms:get_int(wins_surface) ..
			". Underearth: " .. ms:get_int(wins_cave) ..
			". Netherealm: " .. ms:get_int(wins_nether) ..
			". C-Streak: " .. ms:get_int(wins_streak) ..
			". B-Streak: " .. ms:get_int(wins_bstreak) ..
			". Marks: " .. ms:get_int(wins_tokens) ..
			".")
	end
end



function survivalist.game_in_progress(pname)
	local cg = survivalist.modstorage:get_string(pname .. ":mode")
  if cg == "surface" or cg == "cave" or cg == "nether" then
    return true
  end
end



-- This function is called when the player wants to begin the game.
-- It must handle all game validation.
function survivalist.start_game(pname, gamemode)
  -- Get player and make sure he exists.
  local player = minetest.get_player_by_name(pname)
  if not player then
    return
  end
  
  -- Is a game already running?
  local currentgame = survivalist.modstorage:get_string(pname .. ":mode")
  if currentgame == "surface" or currentgame == "cave" or currentgame == "nether" then
    minetest.chat_send_player(pname, "# Server: You are already engaged in a Survivalist Challenge, you cannot start a concurrent game.")
		easyvend.sound_error(pname)
    return
  end

	local pp = player:get_pos()
	if pp.y < -100 or pp.y > 1000 then
		minetest.chat_send_player(pname, "# Server: You need to be on the surface of the Overworld to start a challenge.")
		easyvend.sound_error(pname)
		return
	end

  -- Validate the gamemode.
  if type(gamemode) ~= "string" then
    minetest.chat_send_player(pname, "# Server: No starting option selected!")
		easyvend.sound_error(pname)
    return
  end
  if gamemode ~= "surface" and gamemode ~= "cave" and gamemode ~= "nether" then
    minetest.chat_send_player(pname, "# Server: You must choose a valid starting option!")
		easyvend.sound_error(pname)
    return
  end
  
  -- Player's inventories must be empty.
  if not survivalist.check_inventories_empty(pname) then
    minetest.chat_send_player(pname, "# Server: All your inventories (including the Starfissure Box and armor) must be empty before you can begin a challenge (the Proof of Citizenship does not count). You will receive starting items when you begin.")
		easyvend.sound_error(pname)
    return
  end

  local pos = {x=0, y=0, z=0}
	local group = false

	-- Group survival: check if the player should be grouped with someone else.
	local players = minetest.get_connected_players()
	for k, v in ipairs(players) do
		local oname = v:get_player_name()
		local omode = survivalist.modstorage:get_string(oname .. ":mode")
		-- Gamemodes must match.
		if omode == gamemode then
			local opos = minetest.string_to_pos(survivalist.modstorage:get_string(oname .. ":home"))
			-- Home position must have been recorded.
			if opos then
				-- We must be close enough to the other player's home pos, in order to be grouped with them.
				if vector.distance(opos, player:get_pos()) <= 5 then
					-- The other player must currently be accepting groups.
					-- Groups are not saved across restarts; this means that a player cannot
					-- team with another after the server restarts, even if less time than
					-- the time limit has gone by.
					if survivalist.groups[oname] then
						-- Get location of the other player's dungeon.
						local p2 = minetest.string_to_pos(survivalist.modstorage:get_string(oname .. ":pos"))
						if p2 then
							pos = p2
							group = true
							break
						end
					end
				end
			end
		end
	end

	if not group then
		-- Find a random position on the X,Z plane.
		while vector.distance(pos, surfacecitypos) < 10000 or vector.distance(pos, nethercitypos) < 10000 do
			for j, k in ipairs({"x", "z"}) do
				pos[k] = math.random(-30000, 30000)
			end

			-- Gamemode determines depth.
			if gamemode == "surface" then
				pos.y = -10
			elseif gamemode == "cave" then
				pos.y = math.random(-24000, -3000)
			elseif gamemode == "nether" then
				pos.y = math.random(-30860, -30810)
			end
		end
	end

  -- Prepare target location. The remaining logic is executed from a callback.
	if group then
		-- The dungeon has already been generated.
		survivalist.teleport_and_announce(pname, pos, gamemode)
	else
		-- Need to generate a dungeon, then teleport the player.
		survivalist.prepare_dungeon(pname, pos, gamemode)
	end
end



-- Checks if a player is in range to claim victory.
-- Performs no other validation; this is a simple distance check.
function survivalist.player_in_victory_range(pname)
  local player = minetest.get_player_by_name(pname)
  if not player then
    return
  end
	local pos = player:get_pos()
  if vector.distance(pos, surfacecitypos) <= 20 then
		return true
  elseif vector.distance(pos, nethercitypos) <= 20 then
		return true
  end
end



-- Called when the player wants to claim victory. Must validate.
function survivalist.attempt_claim(pname)
  local player = minetest.get_player_by_name(pname)
  if not player then
    return
  end
  
  -- Make sure a game is actually running.
  local currentgame = survivalist.modstorage:get_string(pname .. ":mode")
  if currentgame ~= "surface" and currentgame ~= "cave" and currentgame ~= "nether" then
    minetest.chat_send_player(pname, "# Server: You are not currently engaged in a Survivalist Challenge.")
		easyvend.sound_error(pname)
    return
  end
  
  -- Check if the player is in the city.
  local pos = player:get_pos()
  local cityname = ""
  
  -- The position and name of the city the player claims victory in.
  local finalcitypos
  if vector.distance(pos, surfacecitypos) <= 20 then
    finalcitypos = table.copy(surfacecitypos)
    cityname = "Surface Colony"
  elseif vector.distance(pos, nethercitypos) <= 20 then
    finalcitypos = table.copy(nethercitypos)
    cityname = "Nether City"
  end
  
  if not finalcitypos then
    minetest.chat_send_player(pname, "# Server: You must be within 20 meters of the main square of the Surface Colony or the Nether City in order to claim victory!")
		easyvend.sound_error(pname)
    return
  end
  
  -- What rank (copper, silver, gold) has the player earned?
  local ranks = {
    ["surface"] = {rank="copper", upper="Copper"},
    ["cave"] = {rank="silver", upper="Silver"},
    ["nether"] = {rank="gold", upper="Gold"},
  }
  local rank = ranks[currentgame].rank
  local upperank = ranks[currentgame].upper
  
  -- Reward the player.
  local tokencount = 1
  local startpos = minetest.string_to_pos(survivalist.modstorage:get_string(pname .. ":pos"))
  
  -- If the starting position couldn't be parsed we'll just give the player 1 token.
  if startpos then
    local dist = vector.distance(finalcitypos, startpos)
    -- Discount the minimum distance.
    dist = dist - 10000
    -- Get distance in kilometers.
    -- One skill mark per extra kilometer over 10k.
    dist = math.floor(dist / 1000)
    -- Clamp, just in case.
    if dist < 1 then
      dist = 1
    end
    tokencount = dist
  end
  
	local dname = rename.gpn(pname)
	if not gdac.player_is_admin(pname) then
		minetest.chat_send_all("# Server: Player <" .. dname .. "> has claimed victory in the " .. cityname .. "!")
		minetest.chat_send_all("# Server: Player <" .. dname .. ">'s skill has been tested in a Survival Challenge and proved worthy.")
		minetest.chat_send_all("# Server: Player <" .. dname .. "> has earned " .. tokencount .. " " .. upperank .. " Skill Mark(s).")
	else
		minetest.chat_send_player(pname, "# Server: You have won the Survival Challenge!")
	end
  local inv = player:get_inventory()
  local leftover = inv:add_item("main", ItemStack("survivalist:" .. rank .. "_skill_token " .. tokencount))
  
  -- No room in inventory? Drop 'em.
  if leftover:get_count() > 0 then
    minetest.item_drop(leftover, player, pos)
		if not gdac.player_is_admin(pname) then
			minetest.chat_send_all("# Server: Player <" .. dname .. ">'s Skill Mark was dropped on the ground!")
		end
  end
  minetest.chat_send_player(pname, "# Server: You should have received a skill mark in your inventory. If your inventory was full, check near your feet!")
  
  -- Record that the challenge is over.
  survivalist.modstorage:set_string(pname .. ":mode", nil)
  survivalist.modstorage:set_string(pname .. ":pos", nil)
	survivalist.modstorage:set_string(pname .. ":home", nil)
  survivalist.players[pname].choice = nil
  
  -- Record total wins, win streaks, and win types.
  local ms = survivalist.modstorage
  local wins_total = pname .. ":wins_total"
  local wins_streak = pname .. ":wins_streak"
  local wins_bstreak = pname .. ":wins_bstreak"
  local wins_type = pname .. ":wins_" .. currentgame
  local wins_tokens = pname .. ":wins_tokens"
  ms:set_int(wins_total, ms:get_int(wins_total) + 1)
  ms:set_int(wins_streak, ms:get_int(wins_streak) + 1)
  ms:set_int(wins_type, ms:get_int(wins_type) + 1)
  ms:set_int(wins_tokens, ms:get_int(wins_tokens) + tokencount)
  
  -- If current streak is better than best streak, update best streak.
  -- Best streak is never erased.
  if ms:get_int(wins_streak) > ms:get_int(wins_bstreak) then
    ms:set_int(wins_bstreak, ms:get_int(wins_streak))
  end
  
  -- Grant player the big_hotbar priv.
  -- Rewarded by the 'surface' gamemode only.
  if currentgame == "surface" then
    if not minetest.check_player_privs(player, {big_hotbar=true}) then
      local privs = minetest.get_player_privs(pname)
      privs.big_hotbar = true
      minetest.set_player_privs(pname, privs)
			minetest.notify_authentication_modified(pname)
      
      player:hud_set_hotbar_image("gui_hotbar2.png")
      player:hud_set_hotbar_itemcount(16)
    end
  end
  
  -- Let everyone know the player's win stats.
  survivalist.shout_player_stats(pname)
  
  -- Add player's name to the rankings.
  survivalist.add_player_to_rankings(pname)
end



function survivalist.player_beat_cave_challenge(pname)
	local ms = survivalist.modstorage
	local va = ms:get_int(pname .. ":wins_cave") or 0
	if va > 0 then
		return true
	end
	return false
end

function survivalist.player_beat_nether_challenge(pname)
	local ms = survivalist.modstorage
	local va = ms:get_int(pname .. ":wins_nether") or 0
	if va > 0 then
		return true
	end
	return false
end



-- If a player joins the server and a Survivalist Challenge is running, inform them.
function survivalist.on_joinplayer(player)
  local pname = player:get_player_name()
  survivalist.players[pname] = {}
  minetest.after(0.5, function()
    local player = minetest.get_player_by_name(pname)
    if not player then
      return
    end
    local gamemode = survivalist.modstorage:get_string(pname .. ":mode")
    if gamemode == "surface" or gamemode == "cave" or gamemode == "nether" then
			local dname = rename.gpn(pname)
			if not gdac.player_is_admin(pname) then
				minetest.chat_send_all("# Server: Player <" .. dname .. "> is engaged in a Survival Challenge.")
			end
      minetest.chat_send_player(pname, "# Server: You are in a Survival Challenge. Avoid death by sleeping!")
      minetest.chat_send_player(pname, "# Server: Find the Surface Colony or the Nether City and claim victory in the Central Square to beat the Challenge.")
    end
  end)
end



-- Dying cancels the challenge.
function survivalist.on_dieplayer(player)
  local pname = player:get_player_name()
	-- If player has a bed respawn set, then they don't fail the challenge.
	if beds.has_respawn_bed(pname) then
		if survivalist.game_in_progress(pname) then
			minetest.after(1, function()
				minetest.chat_send_player(pname, "# Server: You should respawn in your bed. Warning: if you die without a bed, you will fail the Challenge.")
			end)
		end
		return
	end
  local gamemode = survivalist.modstorage:get_string(pname .. ":mode")
  if gamemode == "surface" or gamemode == "cave" or gamemode == "nether" then
    -- Delay the chat messages slightly.
    minetest.after(1, function()
			if not gdac.player_is_admin(pname) then
				local dname = rename.gpn(pname)
				minetest.chat_send_all("# Server: Player <" .. dname .. ">'s survival skill was tested and found wanting!")
			end
      survivalist.shout_player_stats(pname)
      minetest.chat_send_player(pname, "# Server: You failed the Survivalist Challenge. No goodies for you!")
    end)
    -- No game in progress. Win streak is reset to 0.
    survivalist.modstorage:set_string(pname .. ":mode", nil)
    survivalist.modstorage:set_string(pname .. ":pos", nil)
		survivalist.modstorage:set_string(pname .. ":home", nil)
    survivalist.modstorage:set_int(pname .. ":wins_streak", 0)
    
    -- Count loss.
    local ms = survivalist.modstorage
    local ff = pname .. ":wins_fail"
    ms:set_int(ff, ms:get_int(ff) + 1)
    
    -- Add player's name to the rankings (deaths count too).
    survivalist.add_player_to_rankings(pname)
  end
end



-- Abort a running game without loss to player score.
function survivalist.abort_game(pname)
  local gamemode = survivalist.modstorage:get_string(pname .. ":mode")
  if gamemode == "surface" or gamemode == "cave" or gamemode == "nether" then
		if not survivalist.check_inventories_empty(pname) then
			minetest.chat_send_player(pname, "# Server: All your inventories (including the Starfissure Box and armor) must be empty before you may cancel a challenge (the Proof of Citizenship does not count).")
			easyvend.sound_error(pname)
			return
		end

		minetest.chat_send_player(pname, "# Server: Challenge termination confirmed.")
		local target = {x=0, y=-7, z=0}
		target = minetest.string_to_pos(survivalist.modstorage:get_string(pname .. ":home")) or target

		-- Pre-teleport callback function. We may need to abort to prevent cheating.
		local pcb = function()
			if not survivalist.check_inventories_empty(pname) then
				minetest.chat_send_player(pname, "# Server: All your inventories (including the Starfissure Box and armor) must be empty before you may cancel a challenge (the Proof of Citizenship does not count).")
				easyvend.sound_error(pname)
				-- Returning success means to abort the teleport.
				-- Only applicable to pre-teleport callbacks.
				return true
			end
			-- Abort if player is trying to cheat by sitting in a cart. >:)
			if default.player_attached[pname] then
				minetest.chat_send_player(pname, "# Server: Transport error. Player attached!")
				return true
			end
		end

		-- Don't clear the challenge gamestate unless teleport successful.
		local bcb = function()
			-- No game in progress.
			-- Do not touch scores.
			survivalist.modstorage:set_string(pname .. ":mode", nil)
			survivalist.modstorage:set_string(pname .. ":pos", nil)
			survivalist.modstorage:set_string(pname .. ":home", nil)

			flameportal.clear_return_location(pname)
			beds.clear_player_spawn(pname)

			if not gdac.player_is_admin(pname) then
				local dname = rename.gpn(pname)
				minetest.chat_send_all("# Server: Player <" .. dname .. "> canceled a Survival Challenge and went home.")
			else
				minetest.chat_send_player(pname, "# Server: You canceled a Survival Challenge and went home.")
			end
		end

		-- Teleport is forced.
		preload_tp.preload_and_teleport(pname, target, 32, pcb, bcb, nil, true)
	else
		minetest.chat_send_player(pname, "# Server: You are not in a Survival Challenge; cannot abort.")
		easyvend.sound_error(pname)
  end
end



-- Compost the GUI formspec.
function survivalist.compose_formspec(pname)
  local modestring = ""
	local inchallenge = false
  local gamemode = survivalist.modstorage:get_string(pname .. ":mode")
  if gamemode == "surface" then
    modestring = " (You are currently in an Iceworld Challenge)"
		inchallenge = true
  elseif gamemode == "cave" then
    modestring = " (You are currently in an Underearth Challenge)"
		inchallenge = true
  elseif gamemode == "nether" then
    modestring = " (You are currently in a Netherealm Challenge)"
		inchallenge = true
  end
  
  local type_surface = "false"
  local type_cave = "false"
  local type_nether = "false"
  
  -- Choose which checkbox will be shown as selected.
  if survivalist.players[pname] and survivalist.players[pname].choice then
    local choice = survivalist.players[pname].choice
    if choice == "surface" then
      type_surface = "true"
    elseif choice == "cave" then
      type_cave = "true"
    elseif choice == "nether" then
      type_nether = "true"
    end
  end
  
  local formspec = ""
  formspec = formspec .. "size[8,7]" ..
    default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots ..
    
    "label[0,0;Survivalist Challenge" .. modestring .. "]" ..
    
    "textarea[0.3,0.5;8,4;rules;;" .. minetest.formspec_escape(survivalist.gamerules) .. "]"
    
	-- Show challenge choices only if no challenge is in progress.
	if not inchallenge then
    formspec = formspec .. "label[0,4;Choose Your Challenge!]" ..
			"checkbox[0,4.3;type_surface;Surface Survival (Copper Mark);" .. type_surface .. "]" ..
			"checkbox[0,4.8;type_cave;Cave Survival (Silver Mark);" .. type_cave .. "]" ..
			"checkbox[0,5.3;type_nether;Nether Survival (Gold Mark);" .. type_nether .. "]"
	end
    
	-- Choose between start/abort buttons.
	if inchallenge then
		formspec = formspec .. "button[0,6.2;2,1;abort;Go Home]"
	else
		formspec = formspec .. "button[0,6.2;3,1;start;Begin Challenge]"
	end

	-- Show `Claim Victory` only if a challenge is in progress.
	if inchallenge then
		formspec = formspec .. "button[2,6.2;2,1;victory;Claim Victory]"
	end

	formspec = formspec .. "button[4,6.2;2,1;show_rankings;Rankings]" ..
    "button[6,6.2;2,1;close;Close]"
  
  return formspec
end



function survivalist.compose_rankings_formspec(pname)
  local players = survivalist.get_ranking_entries()
  local data = {}
  
  local ms = survivalist.modstorage
  for k, v in pairs(players) do
    data[#data+1] = {
      name = k,
      wins = ms:get_int(k .. ":wins_total"),
      deaths = ms:get_int(k .. ":wins_fail"),
      streak = ms:get_int(k .. ":wins_streak"),
      bstreak = ms:get_int(k .. ":wins_bstreak"),
      surface = ms:get_int(k .. ":wins_surface"),
      cave = ms:get_int(k .. ":wins_cave"),
      nether = ms:get_int(k .. ":wins_nether"),
      tokens = ms:get_int(k .. ":wins_tokens"),
    }
  end
  
  local form = ""
  form = form .. "size[13,7]" ..
    default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots ..
    "label[0,0;Survival Challenge Rankings]" ..
    "button[11,6.2;2,1;close_rankings;Close]"
  
  form = form .. "tablecolumns[color;text;text;text;text;text;text;text;text;text;text;text;text;text;text;text;text;text]"
  form = form .. "table[0,0.5;12.8,5;rankings_table;"
  form = form .. "#00ffff,Username,|,Victories,|,Deaths,|,C-Streak,|,B-Streak,|,Iceworld,|,Underearth,|,Netherealm,|,Marks,"
  
  for k, v in ipairs(data) do
    form = form .. ",<" .. rename.gpn(v.name) .. ">,|," .. v.wins .. ",|," .. v.deaths .. ",|," ..
      v.streak .. ",|," .. v.bstreak .. ",|," .. v.surface .. ",|," .. v.cave ..
      ",|," .. v.nether .. ",|," .. v.tokens .. ","
  end
  
  form = string.gsub(form, ",$", "")
  form = form .. ";1]"
  
  return form
end



function survivalist.show_rankings_formspec(pname)
  local formspec = survivalist.compose_rankings_formspec(pname)
  minetest.show_formspec(pname, "survivalist:rankings", formspec)
end



-- API function (called from passport mod, for instance).
function survivalist.show_formspec(pname)
  local formspec = survivalist.compose_formspec(pname)
  minetest.show_formspec(pname, "survivalist:survivalist", formspec)
end



-- GUI form input handler.
function survivalist.on_receive_fields(player, formname, fields)
  local pname = player:get_player_name()
  if formname ~= "survivalist:survivalist" and formname ~= "survivalist:rankings" then
    return
  end

	if fields.quit then
		return true
	end
  
  if fields.show_rankings then
    survivalist.show_rankings_formspec(pname)
    return true
  end

	if fields.rankings_table then
		survivalist.show_rankings_formspec(pname)
		return true
	end
  
  if fields.close_rankings or formname == "survivalist:rankings" then
    survivalist.show_formspec(pname)
    return true
  end
  
  -- Start game.
  if fields.start then
    minetest.close_formspec(pname, "survivalist:survivalist")
    survivalist.start_game(pname, survivalist.players[pname].choice)
    return true
  end
  
  -- Claim victory.
  if fields.victory then
    minetest.close_formspec(pname, "survivalist:survivalist")
    survivalist.attempt_claim(pname)
    return true
  end

	-- Abort challenge.
	if fields.abort then
		minetest.close_formspec(pname, "survivalist:survivalist")
		survivalist.abort_game(pname)
		return true
	end
  
  -- Handle gamemode checkboxes.
  for j, k in ipairs({"surface", "cave", "nether"}) do
    if fields["type_" .. k] then
      if fields["type_" .. k] == "true" then
        survivalist.players[pname].choice = k
      else
        survivalist.players[pname].choice = nil
      end
      survivalist.show_formspec(pname)
      return true
    end
  end
  
  if fields.close then
    --minetest.close_formspec(pname, "survivalist:survivalist")
    passport.show_formspec(pname)
    return true
  end
  
	survivalist.show_formspec(pname)
  return true
end



-- Here belongs code which must run only once.
if not survivalist.run_once then
  -- Obtain modstorage.
  survivalist.modstorage = minetest.get_mod_storage()
  
  minetest.register_privilege("big_hotbar", {
    description = "Player has double-wide hotbar for item wielding.", 
    give_to_singleplayer = false,
  })

  
  
  -- Define the victory tokens.
  local nodebox = {
    type = "fixed",
    fixed = {
      {-0.5, -0.5, -0.5, 0.5, -15/32, 0.5},
    },
  }

  for j, k in ipairs({
    {name="copper", upper="Copper"},
    {name="silver", upper="Silver"},
    {name="gold", upper="Gold"},
  }) do
    minetest.register_node("survivalist:" .. k.name .. "_skill_token", {
      description = k.upper .. " Skill Mark",
      tiles = {"survivalist_" .. k.name .. "_token.png"},
      inventory_image = "survivalist_" .. k.name .. "_token.png",
      wield_image = "survivalist_" .. k.name .. "_token.png",

			-- If stack_max is clamped, then players can lose marks they win due to
			-- stack clamping, when marks are placed in inventory or dropped on the ground.
      --stack_max = 1,

      paramtype = "light",
      paramtype2 = "facedir",
      sunlight_propagates = true,
      walkable = false,
      groups = utility.dig_groups("item"),
      sounds = default.node_sound_metal_defaults(),
      drawtype = "nodebox",
      node_box = nodebox,
      selection_box = nodebox,
      on_place = minetest.rotate_node,
    })
  end

  -- Compatibility alias.
  minetest.register_alias("survivalist:skill_token", "survivalist:silver_skill_token")

  
  
  -- GUI input handler.
  minetest.register_on_player_receive_fields(function(...)
    return survivalist.on_receive_fields(...)
  end)
  
  -- Update state for players that join.
  minetest.register_on_joinplayer(function(...)
    return survivalist.on_joinplayer(...)
  end)

  -- Dead players can't win anything.
  minetest.register_on_dieplayer(function(...)
    return survivalist.on_dieplayer(...)
  end)

  
  
  -- File is reloadable.
  local c = "survivalist:core"
  local f = survivalist.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
  -- Done.
  survivalist.run_once = true
end
