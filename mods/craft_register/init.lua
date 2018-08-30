
-- Fuels. (Cooking fuels are handled by the engine.)
local registered_mesefuels = {}
local registered_coalfuels = {}
local registered_cutters = {} -- Depreciated?

-- Recipes. (Cooking recipes are handled by the engine.)
local registered_grindings = {}
local registered_grinding_groups = {}
local registered_crushings = {}
local registered_extracts = {}
local registered_extracting_groups = {}
local registered_cuttings = {}
local registered_compressions = {}
local registered_alloys = {}
local registered_separables = {}



-- Override Minetest's builtin craft registration function.
-- This allows me to add extra recipe/fuel types which Minetest would
-- otherwise reject. >:(

local minetest_register_craft = minetest.register_craft
minetest.register_craft = function(def)
  if type(def.type) == "string" then
    if def.type == "mesefuel" then
      registered_mesefuels[def.recipe] = {}
      registered_mesefuels[def.recipe].burntime = def.burntime
      return
    end

    if def.type == "coalfuel" then
      registered_coalfuels[def.recipe] = {}
      registered_coalfuels[def.recipe].burntime = def.burntime
      return
    end

    if def.type == "cutter" then
      registered_cutters[def.blade] = {}
      registered_cutters[def.blade].burntime = def.durability
      return
    end
    
    if def.type == "grinding" then
      local time = def.time
      if type(time) ~= "number" then time = 6 end
      
      if string.find(def.recipe, "^group:") then -- Support group recipes.
        registered_grinding_groups[def.recipe] = {}
        registered_grinding_groups[def.recipe].time = time
        registered_grinding_groups[def.recipe].output = def.output
      else
        registered_grindings[def.recipe] = {}
        registered_grindings[def.recipe].time = time
        registered_grindings[def.recipe].output = def.output
      end
      return
    end
    
    if def.type == "crushing" then
      local time = def.time
      if type(time) ~= "number" then time = 120 end

			registered_crushings[def.recipe] = {}
			registered_crushings[def.recipe].time = time
			registered_crushings[def.recipe].output = def.output
      return
    end

    if def.type == "cutting" then
      local hardness = def.hardness
      if type(hardness) ~= "number" then hardness = 10 end
      
      registered_cuttings[def.recipe] = {}
      registered_cuttings[def.recipe].time = hardness
      registered_cuttings[def.recipe].output = def.output
      return
    end
    
    if def.type == "extracting" then
      local time = def.time
      if type(time) ~= "number" then time = 6 end
      
      if string.find(def.recipe, "^group:") then
        registered_extracting_groups[def.recipe] = {}
        registered_extracting_groups[def.recipe].time = time
        registered_extracting_groups[def.recipe].output = def.output
      else
        registered_extracts[def.recipe] = {}
        registered_extracts[def.recipe].time = time
        registered_extracts[def.recipe].output = def.output
      end
      return
    end
    
    if def.type == "separating" then
      local stack = ItemStack(def.recipe)
      local name = stack:get_name()
      local count = stack:get_count()
      
      local time = def.time
      if type(time) ~= "number" then time = 10 end
      
      registered_separables[name] = {}
      registered_separables[name].time = time
      registered_separables[name].output = {}
      registered_separables[name].output[1] = def.output[1]
      registered_separables[name].output[2] = def.output[2]
      registered_separables[name].count = count
      return
    end
    
    if def.type == "compressing" then
      local stack = ItemStack(def.recipe)
      local name = stack:get_name()
      local count = stack:get_count()
      
      local time = def.time
      if type(time) ~= "number" then time = 6 end
      
      registered_compressions[name] = {}
      registered_compressions[name].time = time
      registered_compressions[name].output = def.output
      registered_compressions[name].count = count
      return
    end
    
    if def.type == "alloying" then
      local stack1 = ItemStack(def.recipe[1])
      local stack2 = ItemStack(def.recipe[2])
      local name1 = stack1:get_name()
      local name2 = stack2:get_name()
      local count1 = stack1:get_count()
      local count2 = stack2:get_count()
      
      local time = def.time
      if type(time) ~= "number" then time = 6 end
      
      -- Don't disturb other recipes which may share a component.
      registered_alloys[name1] = registered_alloys[name1] or {}
      registered_alloys[name1][name2] = {}
      registered_alloys[name1][name2].time = time
      registered_alloys[name1][name2].output = def.output
      registered_alloys[name1][name2].count1 = count1
      registered_alloys[name1][name2].count2 = count2
      
      -- Create swapped version of the same recipe.
      registered_alloys[name2] = registered_alloys[name2] or {}
      registered_alloys[name2][name1] = {}
      registered_alloys[name2][name1].time = time
      registered_alloys[name2][name1].output = def.output
      registered_alloys[name2][name1].count1 = count2 -- Swap.
      registered_alloys[name2][name1].count2 = count1 -- Swap.
      return
    end
  end

  -- Call the original craft registration function.
  minetest_register_craft(def)
end



local minetest_get_all_craft_recipes = minetest.get_all_craft_recipes
minetest.get_all_craft_recipes = function(item)
  -- First, get all recipes known to the Minetest engine.
  local recipes = minetest_get_all_craft_recipes(item)

  -- Append all grinding recipes for this item.
  for k, v in pairs(registered_grindings) do
    local name = ItemStack(v.output):get_name()
    if item == name then
      -- Make sure the table is ready for input.
      -- (In case no previous recipes existed for this item.)
      if not recipes then recipes = {} end

      recipes[#recipes+1] = {
        width = 1,
        type = "grinding",
        items = {k},
        output = v,
        method = "normal",
      }
    end
  end
  
  for k, v in pairs(registered_crushings) do
    local name = ItemStack(v.output):get_name()
    if item == name then
      -- Make sure the table is ready for input.
      -- (In case no previous recipes existed for this item.)
      if not recipes then recipes = {} end

      recipes[#recipes+1] = {
        width = 1,
        type = "crushing",
        items = {k},
        output = v,
        method = "normal",
      }
    end
  end

  for k, v in pairs(registered_grinding_groups) do
    local name = ItemStack(v.output):get_name()
    if item == name then
      -- Make sure the table is ready for input.
      -- (In case no previous recipes existed for this item.)
      if not recipes then recipes = {} end

      recipes[#recipes+1] = {
        width = 1,
        type = "grinding",
        items = {k},
        output = v,
        method = "normal",
      }
    end
  end

  -- Find all extracting recipes for this item.
  for k, v in pairs(registered_extracts) do
    local name = ItemStack(v.output):get_name()
    if item == name then
      -- Make sure the table is ready for input.
      -- (In case no previous recipes existed for this item.)
      if not recipes then recipes = {} end

      recipes[#recipes+1] = {
        width = 1,
        type = "extracting",
        items = {k},
        output = v,
        method = "normal",
      }
    end
  end
  
  for k, v in pairs(registered_extracting_groups) do
    local name = ItemStack(v.output):get_name()
    if item == name then
      -- Make sure the table is ready for input.
      -- (In case no previous recipes existed for this item.)
      if not recipes then recipes = {} end

      recipes[#recipes+1] = {
        width = 1,
        type = "extracting",
        items = {k},
        output = v,
        method = "normal",
      }
    end
  end

  -- Find all compression recipes for this item.
  for k, v in pairs(registered_compressions) do
    local name = ItemStack(v.output):get_name()
    if item == name then
      -- Make sure the table is ready for input.
      -- (In case no previous recipes existed for this item.)
      if not recipes then recipes = {} end

      recipes[#recipes+1] = {
        width = 1,
        type = "compressing",
        items = {k .. " " .. v.count},
        output = v,
        method = "normal",
      }
    end
  end

  -- Find all separating recipes for this item.
  for k, v in pairs(registered_separables) do
    local name1 = ItemStack(v.output[1]):get_name()
    local name2 = ItemStack(v.output[2]):get_name()
    if item == name1 or item == name2 then
      -- Make sure the table is ready for input.
      -- (In case no previous recipes existed for this item.)
      if not recipes then recipes = {} end

      recipes[#recipes+1] = {
        width = 1,
        type = "separating",
        items = {k .. " " .. v.count},
        output = v,
        method = "normal",
      }
    end
  end

  -- Find and add any alloying recipes for the requested item.
  for k, v in pairs(registered_alloys) do
    for i, j in pairs(v) do
      local name = ItemStack(j.output):get_name()
      if item == name then
        -- Make sure the table is ready for input.
        -- (In case no previous recipes existed for this item.)
        if not recipes then recipes = {} end

				local c1 = j.count1
				local c2 = j.count2

        recipes[#recipes+1] = {
          width = 2,
          type = "alloying",
          items = {k .. " " .. c1, i .. " " .. c2},
          output = j,
          method = "normal",
        }
      end
    end
  end

  -- Obtain all registered cutting recipes for this item.
  for k, v in pairs(registered_cuttings) do
    local name = ItemStack(v.output):get_name()
    if item == name then
      -- Make sure the table is ready for input.
      -- (In case no previous recipes existed for this item.)
      if not recipes then recipes = {} end

      recipes[#recipes+1] = {
        width = 1,
        type = "cutting",
        items = {k},
        output = v,
        method = "normal",
      }
    end
  end

  return recipes -- Nil is a valid return value.
end

  

local minetest_get_craft_result = minetest.get_craft_result
minetest.get_craft_result = function(def)
  local m = def.method
  local i = def.items
  local w = def.width

  if m == "grinding" then
    local name = i[1]:get_name()
    if registered_grindings[name] then
      local output = {}
      local decinput = {}

      output.item = registered_grindings[name].output
      output.time = registered_grindings[name].time
      output.replacements = {}

      decinput.items = {}
      decinput.items[1] = ItemStack(i[1]) -- Force copy.
      decinput.items[1]:take_item()

      return output, decinput
    else -- Determine if a group recipe matches.
      local def = minetest.registered_items[name]
      if def and def.groups then
        for k, v in pairs(def.groups) do
          local gkey = "group:" .. k
          if registered_grinding_groups[gkey] then
            local output = {}
            local decinput = {}

            output.item = registered_grinding_groups[gkey].output
            output.time = registered_grinding_groups[gkey].time
            output.replacements = {}

            decinput.items = {}
            decinput.items[1] = ItemStack(i[1]) -- Force copy.
            decinput.items[1]:take_item()
            
            return output, decinput
          end
        end
      end
    end
    ::ugh::
    return {item=ItemStack({}), time=0}, {items={}}
  end

  if m == "extracting" then
    local name = i[1]:get_name()
    if registered_extracts[name] then
      local output = {}
      local decinput = {}

      output.item = registered_extracts[name].output
      output.time = registered_extracts[name].time
      output.replacements = {}

      decinput.items = {}
      decinput.items[1] = ItemStack(i[1]) -- Force copy.
      decinput.items[1]:take_item()

      return output, decinput
    else -- Determine if a group recipe matches.
      local def = minetest.registered_items[name]
      if def and def.groups then
        for k, v in pairs(def.groups) do
          local gkey = "group:" .. k
          if registered_extracting_groups[gkey] then
            local output = {}
            local decinput = {}

            output.item = registered_extracting_groups[gkey].output
            output.time = registered_extracting_groups[gkey].time
            output.replacements = {}

            decinput.items = {}
            decinput.items[1] = ItemStack(i[1]) -- Force copy.
            decinput.items[1]:take_item()
            
            return output, decinput
          end
        end
      end
    end
    ::ugh::
    return {item=ItemStack({}), time=0}, {items={}}
  end

  if m == "compressing" then
    local name = i[1]:get_name()
    if registered_compressions[name] then
      local count = registered_compressions[name].count
      if i[1]:get_count() < count then goto ugh end
      
      local output = {}
      local decinput = {}

      output.item = registered_compressions[name].output
      output.time = registered_compressions[name].time
      output.replacements = {}

      decinput.items = {}
      decinput.items[1] = ItemStack(i[1]) -- Force copy.
      decinput.items[1]:take_item(count)

      return output, decinput
    end
    ::ugh::
    return {item=ItemStack({}), time=0}, {items={}}
  end

  if m == "crushing" then
    local name = i[1]:get_name()
    if registered_crushings[name] then
      local output = {}
      local decinput = {}

      output.item = registered_crushings[name].output
      output.time = registered_crushings[name].time
      output.replacements = {}

      decinput.items = {}
      decinput.items[1] = ItemStack(i[1]) -- Force copy.
      decinput.items[1]:take_item()

      return output, decinput
    end
    ::ugh::
    return {item=ItemStack({}), time=0}, {items={}}
  end

  if m == "separating" then
    local name = i[1]:get_name()
    if registered_separables[name] then
      local count = registered_separables[name].count
      if i[1]:get_count() < count then goto ugh end
      
      local output = {}
      local decinput = {}

      output.item = {}
      output.item[1] = registered_separables[name].output[1]
      output.item[2] = registered_separables[name].output[2]
      output.time = registered_separables[name].time
      output.replacements = {}

      decinput.items = {}
      decinput.items[1] = ItemStack(i[1]) -- Force copy.
      decinput.items[1]:take_item(count)

      return output, decinput
    end
    ::ugh::
    return {item=ItemStack({}), time=0}, {items={}}
  end

  if m == "alloying" then
    local name1 = i[1]:get_name()
    local name2 = i[2]:get_name()
    if registered_alloys[name1] then
      if registered_alloys[name1][name2] then
        local count1 = registered_alloys[name1][name2].count1
        local count2 = registered_alloys[name1][name2].count2
        if i[1]:get_count() < count1 then goto ugh end
        if i[2]:get_count() < count2 then goto ugh end
        
        local output = {}
        local decinput = {}

        output.item = registered_alloys[name1][name2].output
        output.time = registered_alloys[name1][name2].time
        output.replacements = {}

        decinput.items = {}
        decinput.items[1] = ItemStack(i[1]) -- Force copy.
        decinput.items[1]:take_item(count1)
        decinput.items[2] = ItemStack(i[2]) -- Force copy.
        decinput.items[2]:take_item(count2)

        return output, decinput
      end
    end
    ::ugh::
    return {item=ItemStack({}), time=0}, {items={}}
  end

  if m == "cutting" then
    local name = i[1]:get_name()
    if registered_cuttings[name] then
      local output = {}
      local decinput = {}

      output.item = registered_cuttings[name].output
      output.time = registered_cuttings[name].time
      output.replacements = {}

      decinput.items = {}
      decinput.items[1] = ItemStack(i[1]) -- Force copy.
      decinput.items[1]:take_item()

      return output, decinput
    else
      return {item=ItemStack({}), time=0}, {items={}}
    end
  end

  if m == "mesefuel" then
    local name = i[1]:get_name()
    if registered_mesefuels[name] then
      local output = {}
      local decinput = {}

      output.item = i[1]
      output.time = registered_mesefuels[name].burntime
      output.replacements = {}

      decinput.items = {}
      decinput.items[1] = ItemStack(i[1]) -- Force copy.
      decinput.items[1]:take_item()

      return output, decinput
    else
      return {item=ItemStack({}), time=0}, {items={}}
    end
  end

  if m == "coalfuel" then
    local name = i[1]:get_name()
    if registered_coalfuels[name] then
      local output = {}
      local decinput = {}

      output.item = i[1]
      output.time = registered_coalfuels[name].burntime
      output.replacements = {}

      decinput.items = {}
      decinput.items[1] = ItemStack(i[1]) -- Force copy.
      decinput.items[1]:take_item()

      return output, decinput
    else
      return {item=ItemStack({}), time=0}, {items={}}
    end
  end

  if m == "cutter" then
    local name = i[1]:get_name()
    if registered_cutters[name] then
      local output = {}
      local decinput = {}

      output.item = i[1]
      output.time = registered_cutters[name].burntime
      output.replacements = {}

      decinput.items = {}
      decinput.items[1] = ItemStack(i[1]) -- Force copy.
      decinput.items[1]:take_item()

      return output, decinput
    else
      return {item=ItemStack({}), time=0}, {items={}}
    end
  end

  -- Fallback to builtin if not a custom recipe.
  return minetest_get_craft_result(def)
end
