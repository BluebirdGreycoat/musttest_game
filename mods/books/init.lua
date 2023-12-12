
if not minetest.global_exists("books") then books = {} end
books.modpath = minetest.get_modpath("books")
dofile(books.modpath .. "/book.lua")


books.get_formspec = function()
    local formspec =
        "size[8,7;]" ..
        default.formspec.get_form_colors() ..
        default.formspec.get_form_image() ..
        default.formspec.get_slot_colors() ..
        "list[context;books;0,0.3;8,2;]" ..
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



books.on_construct = function(pos)
    local meta = minetest.get_meta(pos)
    meta:set_string("formspec", books.get_formspec())
    local inv = meta:get_inventory()
    inv:set_size("books", 8 * 2)
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

        titles[#titles + 1] = t

        if k >= 5 then
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


books.allow_metadata_inventory_put = function(pos, listname, index, stack)
    if minetest.get_item_group(stack:get_name(), "book") ~= 0 then
        return stack:get_count()
    end
    return 0
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

  inv:set_list("books", list)
end

books.on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
    minetest.log("action", player:get_player_name() .. " moves stuff in bookshelf at " .. minetest.pos_to_string(pos))
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
            
        allow_metadata_inventory_put = function(...)
            return books.allow_metadata_inventory_put(...) end,
            
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



