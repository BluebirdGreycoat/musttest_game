
configurator = configurator or {}
configurator.modpath = minetest.get_modpath("configurator")

local SHORT_DESCRIPTION = "WR Config Device (Unconfigured)\n\nPunch node to set primary target.\nShift-punch node to set secondary target.\nRightclick node to set tertiary target."



configurator.update_description =
function(stack)
	local meta = stack:get_meta()
	local p1 = minetest.string_to_pos(meta:get_string("p1"))
	local p2 = minetest.string_to_pos(meta:get_string("p2"))
	local p3 = minetest.string_to_pos(meta:get_string("p3"))
	local s1, s2, s3 = "N/A", "N/A", "N/A"
	if p1 then
		s1 = rc.pos_to_name(p1) .. " - " .. rc.pos_to_string(p1)
	end
	if p2 then
		s2 = rc.pos_to_name(p2) .. " - " .. rc.pos_to_string(p2)
	end
	if p3 then
		s3 = rc.pos_to_name(p3) .. " - " .. rc.pos_to_string(p3)
	end
	local desc = "WR Config Device\n\nPrimary: " .. s1 .. "\nSecondary: " .. s2 .. "\nTertiary: " .. s3 .. ""
	meta:set_string("description", desc)
end

configurator.on_use =
function(stack, user, pt)
  if not user or not user:is_player() then return end
	local meta = stack:get_meta()
	local pname = user:get_player_name()
	if pt.type == "node" then
		local ctrl = user:get_player_control()
		if ctrl.sneak then
			local p2 = pt.under
			local s2 = minetest.pos_to_string(p2)
			meta:set_string("p2", s2)
			minetest.chat_send_player(pname, "# Server: WR-Config set secondary target! " .. rc.pos_to_name(p2) .. ": " .. rc.pos_to_string(p2) .. ".")
		else
			local p1 = pt.under
			local s1 = minetest.pos_to_string(p1)
			meta:set_string("p1", s1)
			minetest.chat_send_player(pname, "# Server: WR-Config set primary target! " .. rc.pos_to_name(p1) .. ": " .. rc.pos_to_string(p1) .. ".")
		end
	else
		minetest.chat_send_player(pname, "# Server: Set device configuration by punching a node. Also try holding shift or right-clicking.")
	end
	configurator.update_description(stack)
  return stack
end

configurator.on_place =
function(stack, user, pt)
  if not user or not user:is_player() then return end
	local meta = stack:get_meta()
	local pname = user:get_player_name()
	if pt.type == "node" then
		local p3 = pt.under
		local s3 = minetest.pos_to_string(p3)
		meta:set_string("p3", s3)
		minetest.chat_send_player(pname, "# Server: WR-Config set tertiary target! " .. rc.pos_to_name(p3) .. ": " .. rc.pos_to_string(p3) .. ".")
	end
	configurator.update_description(stack)
  return stack
end

configurator.on_secondary_use =
function(stack, user, pt)
  if not user or not user:is_player() then return end
	local pname = user:get_player_name()
	minetest.chat_send_player(pname, "# Server: Set device configuration by punching a node. Also try holding shift or right-clicking.")
	return stack
end



if not configurator.run_once then
  minetest.register_craftitem(":cfg:dev", {
    description = SHORT_DESCRIPTION,
    inventory_image = "configurator_configurator.png",
    stack_max = 1, -- Stores meta, so stacks limited to 1. Also used as upgrade item.
    on_use = function(...) return configurator.on_use(...) end,
		on_place = function(...) return configurator.on_place(...) end,
		on_secondary_use = function(...) return configurator.on_secondary_use(...) end,
  })
	minetest.register_alias("configurator:configurator", "cfg:dev")
  
  minetest.register_craft({
    output = "cfg:dev",
    recipe = {
      {'', 'fine_wire:silver', ''},
      {'', 'techcrafts:control_logic_unit', ''},
      {'', 'techcrafts:copper_coil', ''},
    },
  })
  
  local c = "configurator:core"
  local f = configurator.modpath .. "/init.lua"
  reload.register_file(c, f, false)

  configurator.run_once = true
end
