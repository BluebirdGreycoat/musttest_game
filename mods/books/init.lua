
if not minetest.global_exists("books") then books = {} end
books.modpath = minetest.get_modpath("books")
dofile(books.modpath .. "/book.lua")



-- These items convert to these nodes when placed in the world.
-- Note: must use "open" book because closed book will be automatically removed.
local items_to_nodes = {
    ["books:book_written"] = "books:book_open",
    ["books:book_blank"] = "books:book_open",
}



-- Called from inventory-action on the bookshelf node.
function books.put_book_on_table(pos, stack, pname)
    local minp = vector.offset(pos, -8, -2, -8)
    local maxp = vector.offset(pos, 8, 2, 8)

    -- Make sure stack is just one item.
    if stack:get_count() ~= 1 then
        return false
    end

    -- Make sure stack is a node.
    local nodename = items_to_nodes[stack:get_name()]
    if not nodename then
        return false
    end

    -- "under air" shall skip tables which already have books on them.
    -- This simplifies the code.
    local positions = minetest.find_nodes_in_area_under_air(minp, maxp,
        {"xdecor:booktable", "xdecor:table"})

    if not positions or #positions == 0 then
        return false
    end

    local tablepos = positions[math.random(1, #positions)]
    local airpos = vector.offset(tablepos, 0, 1, 0)

    if minetest.get_node(airpos).name ~= "air" then
        return false
    end

    minetest.set_node(airpos, {name=nodename, param2=math.random(0, 3)})
    local bookmeta = minetest.get_meta(airpos)
    bookmeta:from_table(stack:get_meta():to_table())
    bookmeta:set_int("is_library_checkout", 1)
    bookmeta:set_string("checked_out_by", pname)

    books_placeable.set_closed_infotext(airpos)

    local tabletimer = minetest.get_node_timer(tablepos)
    tabletimer:start(10.0)

    return true
end



-- Called from the booktable node.
function books.book_table_on_timer(pos, elapsed)
    local above = vector.offset(pos, 0, 1, 0)
    local bnode = minetest.get_node(above)
    local bmeta = minetest.get_meta(above)

    if bnode.name == "books:book_closed" and bmeta:get_int("is_library_checkout") == 1 then
        local title = bmeta:get_string("title")
        local pname = bmeta:get_string("checked_out_by")

        if title == "" then
            title = "Untitled Book"
        end

        minetest.remove_node(above)

        local pref = minetest.get_player_by_name(pname)
        if pref and vector.distance(pos, pref:get_pos()) < 32 then
            minetest.chat_send_player(pname, "# Server: \"" .. title .. "\" has been returned to the shelf.")
        end

        return
    elseif bnode.name == "books:book_open" and bmeta:get_int("is_library_checkout") == 1 then
        -- Check again in some seconds.
        return true
    end
end



books.get_formspec = function(pos)
    local meta = minetest.get_meta(pos)

    local donate = "false"
    if meta:get_int("allow_donate") ~= 0 then
        donate = "true"
    end

    local formspec =
        "size[11,7;]" ..
        default.formspec.get_form_colors() ..
        default.formspec.get_form_image() ..
        default.formspec.get_slot_colors() ..
        "list[context;books;0,0.3;8,2;]" ..
        "checkbox[8.5,0.0;allow_donate;Accept Donations;" .. donate .. "]" ..
        "label[8.5,0.8;Checkout]" ..
        "image[8.5,1.3;1,1;books_slot.png]" ..
        "list[context;checkout;8.5,1.3;1,1;]" ..
        "list[current_player;main;0,2.85;8,1;]" ..
        "list[current_player;main;0,4.08;8,3;8]" ..
        "listring[context;books]" ..
        "listring[current_player;main]" ..
        default.get_hotbar_bg(0,2.85)
        
    -- Inventory slots overlay
    local bx, by = 0, 0.3
    for i = 1, 16 do
        if i == 9 then
            bx = 0
            by = by + 1
        end
        formspec = formspec .. "image["..bx..","..by..";1,1;books_slot.png]"
        bx = bx + 1
    end
    
    return formspec
end



function books.on_receive_fields(pos, formname, fields, sender)
    local pname = sender:get_player_name()
    if minetest.test_protection(pos, pname) then
        return
    end

    local meta = minetest.get_meta(pos)

    if fields.allow_donate == "true" then
        meta:set_int("allow_donate", 1)
    elseif fields.allow_donate == "false" then
        meta:set_string("allow_donate", "")
    end

    meta:set_string("formspec", books.get_formspec(pos))
end



books.on_construct = function(pos)
    local meta = minetest.get_meta(pos)
    meta:set_string("formspec", books.get_formspec(pos))
    local inv = meta:get_inventory()
    inv:set_size("books", 8 * 2)
    inv:set_size("checkout", 1)
end



function books.on_update_formspec(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size("checkout", 1)
    meta:set_string("formspec", books.get_formspec(pos))
end



books.can_dig = function(pos,player)
    local inv = minetest.get_meta(pos):get_inventory()
    return inv:is_empty("books")
end

function books.update_infotext(pos)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local list = inv:get_list("books")

  local titles = {}

  for k, v in ipairs(list) do
    if not v:is_empty() then
        local imeta = v:get_meta()
        local t = imeta:get_string("title")

        if t ~= "" then
            titles[#titles + 1] = t
        end

        if #titles >= 5 then
            break
        end
    end
  end

  local infotext = ""
  for k, v in ipairs(titles) do
    infotext = infotext .. k .. ": \"" .. v .. "\"\n"
  end
  meta:set_string("infotext", infotext)
end



books.allow_metadata_inventory_put = function(pos, listname, index, stack, player)
    if minetest.get_item_group(stack:get_name(), "book") == 0 then
        return 0
    end

    -- Cannot put something directly in checkout slot.
    -- Put something in main inv first, then move it.
    -- This lets us keep the code simple.
    if listname == "checkout" then
        return 0
    end

    -- Note: users not on protection are allowed to put books on shelf.
    -- But they cannot remove them!
    local pname = player:get_player_name()
    local meta = minetest.get_meta(pos)
    if meta:get_int("allow_donate") == 0 then
        if minetest.test_protection(pos, pname) then
            return 0
        end
    end

    return stack:get_count()
end



books.allow_metadata_inventory_take = function(pos, listname, index, stack, player)
    if minetest.get_item_group(stack:get_name(), "book") == 0 then
        return 0
    end

    -- Cannot take directly from checkout slot.
    -- That slot should always be empty anyway.
    if listname == "checkout" then
        return 0
    end

    local pname = player:get_player_name()

    -- Users not on protection cannot remove anything.
    if minetest.test_protection(pos, pname) then
        return 0
    end

    return stack:get_count()
end



books.allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
    if from_list == "checkout" then
        return 0
    end

    local pname = player:get_player_name()

    -- Users not on protection are not allowed to move books around, except to the checkout slot.
    if to_list ~= "checkout" then
        if minetest.test_protection(pos, pname) then
            return 0
        end
    end

    return count
end



function books.on_update_infotext(pos)
    books.update_infotext(pos)
end

-- Use this callback hook to update all book descriptions.
function books.on_update_entity(pos)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local list = inv:get_list("books")

  for k, v in ipairs(list) do
    if not v:is_empty() then
        local imeta = v:get_meta()
        if v:get_name() == "books:book_written" then
            local t = imeta:get_string("title")
            local a = imeta:get_string("owner")

            -- Don't bother triming the title if the trailing dots would make it longer
            if #t > books.SHORT_TITLE_SIZE + 3 then
            t = t:sub(1, books.SHORT_TITLE_SIZE) .. "..."
            end
            local desc = "\"" .. t .. "\" By <" .. rename.gpn(a) .. ">"

            imeta:set_string("description", desc)
        end
    end
  end

  inv:set_list("books", list)
end

books.on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
    local pname = player:get_player_name()
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()

    -- Not a storage slot. Put item back in main inv, and put temporary book on table!
    if to_list == "checkout" then
        local stack = inv:get_stack("checkout", 1)
        inv:set_stack(from_list, from_index, stack)
        inv:set_stack("checkout", 1, ItemStack(""))

        local imeta = stack:get_meta()
        local title = imeta:get_string("title")

        if title == "" then
            title = "Untitled Book"
        end

        if books.put_book_on_table(pos, stack, pname) then
            minetest.chat_send_player(pname, "# Server: You checked out \"" .. title .. "\". Look for it on a nearby table.")
        else
            minetest.chat_send_player(pname, "# Server: You were unable to checkout out \"" .. title .. "\".")
        end
    end

    minetest.log("action", pname .. " moves stuff in bookshelf at " .. minetest.pos_to_string(pos))
    books.update_infotext(pos)
end

books.on_metadata_inventory_put = function(pos, listname, index, stack, player)
    minetest.log("action", player:get_player_name() .. " moves stuff to bookshelf at " .. minetest.pos_to_string(pos))
    books.update_infotext(pos)
end

books.on_metadata_inventory_take = function(pos, listname, index, stack, player)
    minetest.log("action", player:get_player_name() .. " takes stuff from bookshelf at " .. minetest.pos_to_string(pos))
    books.update_infotext(pos)
end

books.on_blast = function(pos)
    local drops = {}
    default.get_inventory_drops(pos, "books", drops)
    drops[#drops+1] = "books:bookshelf"
    minetest.remove_node(pos)
    return drops
end



if not books.run_once then
    local bookshelf_groups = utility.dig_groups("furniture", {flammable = 3})
    local bookshelf_sounds = default.node_sound_wood_defaults()
    
    minetest.register_node("books:bookshelf", {
        description = "Bookshelf",
        tiles = {
            "default_wood.png", 
            "default_wood.png", 
            "default_wood.png",
            "default_wood.png", 
            "books_bookshelf.png", 
            "books_bookshelf.png"
        },
        paramtype2 = "facedir",
        groups = bookshelf_groups,
        sounds = bookshelf_sounds,

        on_construct = function(...)
            return books.on_construct(...) end,
            
        can_dig = function(...)
            return books.can_dig(...) end,

        on_receive_fields = function(...)
            return books.on_receive_fields(...) end,
            
        allow_metadata_inventory_put = function(...)
            return books.allow_metadata_inventory_put(...) end,
            
        allow_metadata_inventory_take = function(...)
            return books.allow_metadata_inventory_take(...) end,

        allow_metadata_inventory_move = function(...)
            return books.allow_metadata_inventory_move(...) end,

        on_metadata_inventory_move = function(...)
            return books.on_metadata_inventory_move(...) end,
            
        on_metadata_inventory_put = function(...)
            return books.on_metadata_inventory_put(...) end,
            
        on_metadata_inventory_take = function(...)
            return books.on_metadata_inventory_take(...) end,
            
        on_blast = function(...)
            return books.on_blast(...) end,

        _on_update_infotext = function(...)
            return books.on_update_infotext(...) end,

        _on_update_entity = function(...)
            return books.on_update_entity(...) end,

        _on_update_formspec = function(...)
            return books.on_update_formspec(...) end,
    })

    minetest.register_node("books:bookshelf_empty", {
        description = "Empty Bookshelf",
        tiles = {
            "default_wood.png", 
            "default_wood.png", 
            "default_wood.png",
            "default_wood.png", 
            "books_bookshelf_empty.png", 
            "books_bookshelf_empty.png"
        },
        paramtype2 = "facedir",
        groups = bookshelf_groups,
        sounds = bookshelf_sounds,
    })

    minetest.register_craft({
        type = "fuel",
        recipe = "books:bookshelf",
        burntime = 30,
    })

    minetest.register_craft({
        output = 'books:bookshelf_empty',
        recipe = {
            {'group:wood', 'group:wood', 'group:wood'},
            {'books:book_blank', 'books:book_blank', 'books:book_blank'},
            {'group:wood', 'group:wood', 'group:wood'},
        }
    })

    minetest.register_craft({
        type = "fuel",
        recipe = "books:bookshelf_empty",
        burntime = 26,
    })

    minetest.register_craft({
        output = "books:bookshelf",
        type = "shapeless",
        recipe = {"books:bookshelf_empty", "books:book_blank"},
    })

    minetest.register_alias("default:bookshelf",            "books:bookshelf")
    minetest.register_alias("bookshelf:bookshelf",          "books:bookshelf")
    minetest.register_alias("moreblocks:empty_bookshelf",   "books:bookshelf_empty")
		minetest.register_alias("default:book",									"books:book_blank")
		minetest.register_alias("default:book_written",         "books:book_written")

		minetest.register_on_player_receive_fields(function(...) books.on_player_receive_fields(...) end)
		minetest.register_on_craft(function(...) books.on_craft(...) end)
    
		minetest.register_craftitem("books:book_blank", {
			description = "Book (Blank)",
			inventory_image = "default_book.png",
			groups = {book = 1, flammable = 3},
			on_use = function(...) return books.book_on_use(...) end,
		})

		minetest.register_craftitem("books:book_written", {
			description = "Book (Written)",
			inventory_image = "default_book_written.png",
			groups = {book = 1, not_in_creative_inventory = 1, flammable = 3},
			stack_max = 1,
			on_use = function(...) return books.book_on_use(...) end,
		})

		minetest.register_craft({
			type = "shapeless",
			output = "books:book_written",
			recipe = {"books:book_blank", "books:book_written"}
		})

		minetest.register_craft({
			output = 'books:book_blank',
			recipe = {
				{'default:paper'},
				{'default:paper'},
				{'default:paper'},
			}
		})

    -- Reloadable.
    local name = "books:core"
    local file = books.modpath .. "/init.lua"
    reload.register_file(name, file, false)
    
    books.run_once = true
end



