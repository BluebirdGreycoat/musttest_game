
if not minetest.global_exists("starpearl") then starpearl = {} end
starpearl.modpath = minetest.get_modpath("starpearl")



function starpearl.on_place(itemstack, placer, pt)
  if not placer or not placer:is_player() then return end
  if pt.type ~= "node" then return end
  local pname = placer:get_player_name()

  -- What are we pointing at?
  local nn = minetest.get_node(pt.under).name

	-- Allow stairs, slabs, dark obsidian, etc. to be struck by firestriker.
	-- This comes before protection check so that players can use others' portals.
	if string.find(nn, "obsidian") then
		flameportal.try_teleport_on_flint_use(placer)
	end

	if string.find(nn, "obsidian") or string.find(nn, "grieferstone") then
		obsidian_gateway.attempt_activation(pt.under, placer)
	end

	if nn == "default:obsidian" then
		local result, pos = flameportal.find_gateway(pt.under)
		if result == true and pos then
			flameportal.activate_gateway(pos)
		end
	end
end



if not starpearl.run_once then
	minetest.register_craftitem("starpearl:pearl", {
		description = "Star Pearl",
		inventory_image = "starpearl_pearl.png",

		on_place = function(...) return starpearl.on_place(...) end,
	})

  local c = "starpearl:core"
  local f = starpearl.modpath .. "/init.lua"
  reload.register_file(c, f, false)

  starpearl.run_once = true
end

