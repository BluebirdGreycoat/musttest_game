-- ZCG mod for minetest
-- See README for more information
-- Released by Zeg9 under WTFPL

zcg = zcg or {}
zcg.modpath = minetest.get_modpath("zcg")

zcg.users = zcg.users or {}
zcg.crafts = zcg.crafts or {}
zcg.itemlist = zcg.itemlist or {}



zcg.items_in_group = function(group)
  local items = {}
  local ok = true
  for name, item in pairs(minetest.registered_items) do
    -- the node should be in all groups
    ok = true
    for _, g in ipairs(group:split(',')) do
      if not item.groups[g] then
        ok = false
      end
    end
    if ok then table.insert(items,name) end
  end
  return items
end



local table_copy = function(table)
  local out = {}
  for k,v in pairs(table) do
    out[k] = v
  end
  return out
end

zcg.add_craft = function(input, realout, output, groups)
  if minetest.get_item_group(output, "not_in_craft_guide") > 0 then
    return
  end
  if not groups then groups = {} end
  local c = {}
  c.width = input.width
  c.type = input.type
  c.items = input.items

	if type(realout) == "string" then
		c.result = realout
	elseif type(realout) == "table" then
		--minetest.log(dump(realout))
		if type(realout.output) == "string" then
			c.result = realout.output
		elseif type(realout.output) == "table" then
			-- Recipe output should be two items (separating recipe).
			assert(type(realout.output[1]) == "string")
			assert(type(realout.output[2]) == "string")
			c.result = table.copy(realout.output)
		end
	end
	assert(type(c.result) == "string" or type(c.result) == "table")

  if c.items == nil then return end
  for i, item in pairs(c.items) do
    if item:sub(0,6) == "group:" then
      local groupname = item:sub(7)
      if groups[groupname] ~= nil then
        c.items[i] = groups[groupname]
      else
        for _, gi in ipairs(zcg.items_in_group(groupname)) do
          local g2 = groups
          g2[groupname] = gi
          zcg.add_craft({
            width = c.width,
            type = c.type,
            items = table_copy(c.items)
          }, realout, output, g2) -- it is needed to copy the table, else groups won't work right
        end
        return
      end
    end
  end
  if c.width == 0 then c.width = 3 end
  table.insert(zcg.crafts[output],c)
end



zcg.load_crafts = function(name)
  zcg.crafts[name] = {}
  local _recipes = minetest.get_all_craft_recipes(name)
  if _recipes then
    for i, recipe in ipairs(_recipes) do
      if (recipe and recipe.items and recipe.type) then
				assert(type(recipe.output) ~= "nil")
        zcg.add_craft(recipe, recipe.output, name)
      end
    end
  end
  if zcg.crafts[name] == nil or #zcg.crafts[name] == 0 then
    zcg.crafts[name] = nil
  else
    table.insert(zcg.itemlist,name)
  end
end



zcg.formspec = function(pn)
  local page = zcg.users[pn].page
  local alt = zcg.users[pn].alt
  local current_item = zcg.users[pn].current_item
  local formspec = "size[8,8.5]" ..
    default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots ..
	"button[0,0.5;2,.5;main;Back]"

  if zcg.users[pn].history.index > 1 then
    formspec = formspec .. "image_button[0,1.5;1,1;zcg_previous.png;zcg_previous;;false;false;zcg_previous_press.png]"
  else
    formspec = formspec .. "image[0,1.5;1,1;zcg_previous_inactive.png]"
  end
  if zcg.users[pn].history.index < #zcg.users[pn].history.list then
    formspec = formspec .. "image_button[1,1.5;1,1;zcg_next.png;zcg_next;;false;false;zcg_next_press.png]"
  else
    formspec = formspec .. "image[1,1.5;1,1;zcg_next_inactive.png]"
  end
  -- Show craft recipe
  if current_item ~= "" then
    if zcg.crafts[current_item] then
      if alt > #zcg.crafts[current_item] then
        alt = #zcg.crafts[current_item]
      end
      if alt > 1 then
        formspec = formspec .. "button[7,0.5;1,1;zcg_alt:"..(alt-1)..";^]"
      end
      if alt < #zcg.crafts[current_item] then
        formspec = formspec .. "button[7,2.5;1,1;zcg_alt:"..(alt+1)..";v]"
      end
      local c = zcg.crafts[current_item][alt]
      if c then
        local x = 3
        local y = 0
				-- Crafting recipe generated here.
        for i, item in pairs(c.items) do
					local stack = ItemStack(item)
					local itemname = stack:get_name()
          formspec = formspec .. "item_image_button["..((i-1)%c.width+x)..","..(math.floor((i-1)/c.width+y)+0.5)..";1,1;"..item..";zcg:"..itemname..";]"
        end
        if c.type == "normal" or
          c.type == "cooking" or
          c.type == "grinding" or
          c.type == "cutting" or
          c.type == "extracting" or
          c.type == "alloying" or
          c.type == "separating" or
          c.type == "compressing" or
					c.type == "crushing" then
          formspec = formspec .. "image[6,2.5;1,1;zcg_method_"..c.type..".png]"
        else -- we don't have an image for other types of crafting
          formspec = formspec .. "label[0,2.5;Method: "..c.type.."]"
        end

        if c.type == "normal" then
          formspec = formspec .. "label[0,2.5;Method: Crafting]"
        elseif c.type == "cooking" then
          formspec = formspec .. "label[0,2.5;Method: Cooking/Smelting]"
        elseif c.type == "grinding" then
          formspec = formspec .. "label[0,2.5;Method: Grinding]"
        elseif c.type == "crushing" then
          formspec = formspec .. "label[0,2.5;Method: Crushing]"
        elseif c.type == "cutting" then
          formspec = formspec .. "label[0,2.5;Method: Cutting]"
        elseif c.type == "extracting" then
          formspec = formspec .. "label[0,2.5;Method: Extracting]"
        elseif c.type == "compressing" then
          formspec = formspec .. "label[0,2.5;Method: Compressing]"
        elseif c.type == "alloying" then
          formspec = formspec .. "label[0,2.5;Method: Alloying]"
        elseif c.type == "separating" then
          formspec = formspec .. "label[0,2.5;Method: Separating]"
        end

				if type(c.result) == "string" then
					formspec = formspec .. "image[6,1.5;1,1;zcg_craft_arrow.png]"
					formspec = formspec .. "item_image_button[7,1.5;1,1;".. c.result ..";;]"
				elseif type(c.result) == "table" then
					-- Separating recipes have two outputs.
					formspec = formspec .. "item_image_button[6,1.5;1,1;".. c.result[1] ..";;]"
					formspec = formspec .. "item_image_button[7,1.5;1,1;".. c.result[2] ..";;]"
				end

				--minetest.chat_send_all(dump(c))
      end
    end
  end

  -- Node list
  local npp = 8*3 -- nodes per page
  local i = 0 -- for positionning buttons
  local s = 0 -- for skipping pages

	local whichlist = zcg.itemlist
	local listname = " total items."

	if zcg.users[pn].searchtext ~= "" then
		whichlist = zcg.users[pn].searchlist
		page = zcg.users[pn].spage
		listname = " result(s)."
	end

	if #whichlist > 0 then
		formspec = formspec ..
			"label[0,4.0;" .. #whichlist .. " " .. listname .. "]"
		for _, name in ipairs(whichlist) do
			if s < page*npp then s = s+1 else
				if i >= npp then break end
				formspec = formspec .. "item_image_button["..(i%8)..","..(math.floor(i/8)+4.5)..";1,1;"..name..";zcg:"..name..";]"
				i = i+1
			end
		end
	else
		formspec = formspec ..
			"label[0,4.0;No results.]"
	end

	-- Page buttons.
	local maxpage = (math.ceil(#whichlist/npp))
	if maxpage < 1 then maxpage = 1 end -- In case no results, must have 1 page.
	local curpage = page+1

  if page > 0 then
    formspec = formspec .. "button[0,8;1,.5;zcg_page:"..(page-1)..";<<]"
	else
		formspec = formspec .. "button[0,8;1,.5;zcg_page:"..(maxpage-1)..";<<]"
  end

  if curpage < maxpage then
    formspec = formspec .. "button[1,8;1,.5;zcg_page:"..(page+1)..";>>]"
	elseif curpage >= maxpage then
		formspec = formspec .. "button[1,8;1,.5;zcg_page:".. 0 ..";>>]"
  end
	-- The Y is approximatively the good one to have it centered vertically...
  formspec = formspec .. "label[2,7.85;Page " .. curpage .."/".. maxpage .."]"

	-- Search field.
	formspec = formspec ..
		"button[6,8;1,0.5;zcg_search;?]" ..
		"button[7,8;1,0.5;zcg_clear;X]"

	local text = zcg.users[pn].searchtext or ""

	formspec = formspec ..
		"field[4,8.1;2.3,1;zcg_sbox;;" .. minetest.formspec_escape(text) .. "]" ..
		"field_close_on_enter[zcg_sbox;false]"
  return formspec
end



function zcg.update_search(pn, tsearch)
	minetest.log("action", "<" .. rename.gpn(pn) .. "> executes craftguide search for \"" .. tsearch .. "\".")

	zcg.users[pn].searchlist = {}

	if tsearch == "" or tsearch == "<INVAL>" then
		return
	end

	-- Let user search multiple tokens at once.
	local texts = string.split(tsearch)
	if not texts or #texts == 0 then
		return
	end

	local list = {}

	local find = string.find
	local ipairs = ipairs
	local pairs = pairs
	local type = type
	local items = minetest.registered_items

	-- Returns true only if all tokens in list are found in the search string.
	local function find_all(search, combined)
		local count = 0
		for i=1, #combined do
			if find(search, combined[i], 1, true) then
				count = count + 1
			else
				-- Early finish.
				return false
			end
		end
		return (count == #combined)
	end

	for i=1, #texts, 1 do
		local text = string.trim(texts[i]):lower()
		local combined = string.split(text, " ")
		for k=1, #combined do
			combined[k] = string.trim(combined[k]):lower()
		end

		for _, name in ipairs(zcg.itemlist) do
			if find_all(name:lower(), combined) then
				list[name] = true
			else
				local ndef = items[name]
				if ndef then
					-- Search description for a match.
					if ndef.description then
						if find_all(ndef.description:lower(), combined) then
							list[name] = true
						end
					end
				end -- if ndef.
			end
		end
	end -- for all texts.

	-- Duplicate results are removed.
	local flat = {}
	for k, v in pairs(list) do
		flat[#flat + 1] = k
	end

	zcg.users[pn].searchlist = flat
end



-- It seems the player's main inventory formspec does not have a formname.
local singleplayer = minetest.is_singleplayer()
zcg.on_receive_fields = function(player, formname, fields)
  local pn = player:get_player_name();
  if zcg.users[pn] == nil then
		zcg.users[pn] = {
			current_item = "",
			alt = 1,
			page = 0,
			history = {index=0, list={}},
			searchlist = {},
			searchtext = "",
			spage = 0, -- Keep search page # seperate from main page #.
		}
	end
  if fields.zcg then
    inventory_plus.set_inventory_formspec(player, zcg.formspec(pn))
    return
  elseif fields.zcg_previous then
    if zcg.users[pn].history.index > 1 then
      zcg.users[pn].history.index = zcg.users[pn].history.index - 1
      zcg.users[pn].current_item = zcg.users[pn].history.list[zcg.users[pn].history.index]
			zcg.users[pn].searchtext = fields.zcg_sbox or "<INVAL>"
      inventory_plus.set_inventory_formspec(player,zcg.formspec(pn))
    end
  elseif fields.zcg_next then
    if zcg.users[pn].history.index < #zcg.users[pn].history.list then
      zcg.users[pn].history.index = zcg.users[pn].history.index + 1
      zcg.users[pn].current_item = zcg.users[pn].history.list[zcg.users[pn].history.index]
			zcg.users[pn].searchtext = fields.zcg_sbox or "<INVAL>"
      inventory_plus.set_inventory_formspec(player,zcg.formspec(pn))
    end
  end
  for k, v in pairs(fields) do
    if (k:sub(0,4)=="zcg:") then
      local ni = k:sub(5)
			zcg.users[pn].searchtext = fields.zcg_sbox or "<INVAL>"
      if zcg.crafts[ni] then
				local previtem = zcg.users[pn].current_item
        zcg.users[pn].current_item = ni
        table.insert(zcg.users[pn].history.list, ni)
        zcg.users[pn].history.index = #zcg.users[pn].history.list
        inventory_plus.set_inventory_formspec(player,zcg.formspec(pn))

				-- Add item to inventory if creative access is enabled.
				if gdac.player_is_admin(pn) or singleplayer then
					-- If player clicked twice.
					if previtem == ni then
						local inv = player:get_inventory()
						local stack = ItemStack(ni)
						stack:set_count(stack:get_stack_max())
						local leftover = inv:add_item("main", stack)
						if not leftover or leftover:get_count() == 0 then
							local desc = utility.get_short_desc(stack:get_definition().description or "Undescribed Item")
							minetest.chat_send_player(pn, "# Server: Added '" .. desc .. "' to inventory!")
						else
							minetest.chat_send_player(pn, "# Server: Not enough room in inventory!")
						end
					end
				end
      end
    elseif (k:sub(0,9)=="zcg_page:") then
			if zcg.users[pn].searchtext == "" then
				zcg.users[pn].page = tonumber(k:sub(10))
			else
				zcg.users[pn].spage = tonumber(k:sub(10))
			end
			zcg.users[pn].searchtext = fields.zcg_sbox or "<INVAL>"
      inventory_plus.set_inventory_formspec(player,zcg.formspec(pn))
    elseif (k:sub(0,8)=="zcg_alt:") then
      zcg.users[pn].alt = tonumber(k:sub(9))
			zcg.users[pn].searchtext = fields.zcg_sbox or "<INVAL>"
      inventory_plus.set_inventory_formspec(player,zcg.formspec(pn))
    elseif (k == "zcg_clear") then
      zcg.users[pn].searchlist = {}
			zcg.users[pn].searchtext = ""
      inventory_plus.set_inventory_formspec(player,zcg.formspec(pn))
    elseif (k == "zcg_search") then
			local newtext = fields.zcg_sbox or "<INVAL>"
			if newtext ~= zcg.users[pn].searchtext then -- Don't update if same.
				zcg.users[pn].searchlist = {}
				zcg.users[pn].searchtext = newtext
				if string.len(zcg.users[pn].searchtext) > 128 then
					zcg.users[pn].searchtext = "<INVAL>"
				else
					local res, err = pcall(function() zcg.update_search(pn, zcg.users[pn].searchtext) end)
					if not res and type(err) == "string" then
						minetest.log("error", err)
					end
					zcg.users[pn].spage = 0 -- Reset user's search page.
				end
				inventory_plus.set_inventory_formspec(player,zcg.formspec(pn))
			end
    end
  end
end



if not zcg.registered then
	-- Load all crafts directly after server-init time.
	-- We can't do this at craft-register time because the logic needs access to
	-- the groups of the recipe output items, which may not be known by the engine
	-- until after recipes for the items are registered.
	minetest.after(0, function()
		for name, item in pairs(minetest.registered_items) do
			if name and name ~= "" then
				zcg.load_crafts(name)
			end
		end
		table.sort(zcg.itemlist)
	end)

	minetest.register_on_joinplayer(function(player)
		inventory_plus.register_button(player,"zcg","Craft guide")
	end)

	minetest.register_on_player_receive_fields(function(...)
		return zcg.on_receive_fields(...)
	end)

	local c = "zcg:core"
	local f = zcg.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	zcg.registered = true
end
