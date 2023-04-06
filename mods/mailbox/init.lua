
if not minetest.global_exists("mailbox") then mailbox = {} end
mailbox.modpath = minetest.get_modpath("mailbox")

-- Stores mailbox information.
mailbox.boxes = mailbox.boxes or {}

-- Items to reject (also rejects starter items).
mailbox.reject_items = {
	"default:ice",
	"bones:bones_type2",
	"default:cobble",
	"default:snow",
}

dofile(mailbox.modpath .. "/functions.lua")
dofile(mailbox.modpath .. "/storage.lua")



if not mailbox.run_once then
  mailbox.load()
  
  minetest.register_on_player_receive_fields(function(...)
    return mailbox.on_receive_fields(...)
  end)
  
  minetest.register_craft({
    output ="mailbox:mailbox",
    recipe = {
      {"",                    "default:steel_ingot", ""                   },
      {"default:steel_ingot", "",                    "default:steel_ingot"},
      {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
    },
  })
  
  local mb_cbox = {
    type = "fixed",
    fixed = { -5/16, -8/16, -8/16, 5/16, 2/16, 8/16 },
  }

  minetest.register_node("mailbox:mailbox", {
    paramtype = "light",
    drawtype = "mesh",
    mesh = "mailbox_mailbox.obj",
    description = "Mailbox\n\nUpgrade with a CLU to get email when items are deposited.",
      
    tiles = {
      "mailbox_red_metal.png",
      "mailbox_white_metal.png",
      "mailbox_grey_metal.png",
    },
      
    selection_box = mb_cbox,
    collision_box = mb_cbox,
      
    paramtype2 = "facedir",
    groups = utility.dig_groups("furniture", {
      immovable = 1,
    }),
    sounds = default.node_sound_wood_defaults(),
    on_rotate = screwdriver.rotate_simple,
    
    on_punch = function(...)
      return mailbox.on_punch(...)
    end,
      
    after_place_node = function(...)
      return mailbox.after_place_node(...)
    end,
    
    on_destruct = function(...)
      return mailbox.on_destruct(...)
    end,
    
    on_rightclick = function(...)
      return mailbox.on_rightclick(...)
    end,
    
    can_dig = function(...)
      return mailbox.can_dig(...)
    end,
    
    on_metadata_inventory_put = function(...)
      return mailbox.on_metadata_inventory_put(...)
    end,
    
    allow_metadata_inventory_put = function(...)
      return mailbox.allow_metadata_inventory_put(...)
    end,
    
    allow_metadata_inventory_move = function(...)
      return mailbox.allow_metadata_inventory_move(...)
    end,
    
    allow_metadata_inventory_take = function(...)
      return mailbox.allow_metadata_inventory_take(...)
    end,
    
    on_blast = function(...)
      return mailbox.on_blast(...)
    end,

		-- Called by rename LBM.
		_on_rename_check = function(pos)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("owner")
			-- Nobody placed this block.
			if owner == "" then
				return
			end
			local dname = rename.gpn(owner)

			meta:set_string("rename", dname)
			meta:set_string("infotext", "Mailbox (Owned by <" .. dname .. ">!)")
		end,
  })

  local c = "mailbox:core"
  local f = mailbox.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
  minetest.register_on_shutdown(function()
    mailbox.save()
  end)
  
  mailbox.run_once = true
end
