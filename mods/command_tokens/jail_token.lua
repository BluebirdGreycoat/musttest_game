
command_tokens = command_tokens or {}
command_tokens.jail = command_tokens.jail or {}



minetest.register_privilege("ignore_jail_token", {description="Player cannot be sent to jail.", give_to_singleplayer=false})



local formspec = "size[4.1,2.0]" ..
	default.gui_bg ..
	default.gui_bg_img ..
	default.gui_slots ..
	"label[0,0;Type name of trespasser:]" ..
	"field[0.30,0.75;4,1;PLAYERNAME;;]" ..
	"button_exit[0,1.30;2,1;OK;Confirm]" ..
	"button_exit[2,1.30;2,1;CANCEL;Cancel]" ..
	"field_close_on_enter[PLAYERNAME;false]"



-- Called when the player uses a jail token.
command_tokens.jail.jail_player = function(itemstack, user, pointed)
	if user and user:is_player() then
        if pointed.type == "object" then
            local object = pointed.ref
            if object and object:is_player() then
                command_tokens.jail.execute(user:get_player_name(), object:get_player_name())
            else
                minetest.chat_send_player(user:get_player_name(), "# Server: Target is not a player!")
            end
        else
            local name = user:get_player_name()
            minetest.show_formspec(name, "command_tokens:jail", formspec)
        end
	end
end



local function is_valid_target(name, target)
  if minetest.get_player_by_name(target) then
    if not minetest.check_player_privs(target, {ignore_jail_token=true}) then
      return true
    end
  end
  return false
end



command_tokens.jail.execute = function(player, target)
	player = rename.grn(player)
	target = rename.grn(target)

  if not minetest.get_player_by_name(target) then
    minetest.chat_send_player(player, "# Server: Law-enforcement couldn't find player <" .. rename.gpn(target) .. ">.")
    return
  end
  
	local self_arrest = false
  if player == target then
    --minetest.chat_send_player(player, "# Server: Law-enforcement does not arrest self-trespassers.")
    --return
		self_arrest = true
  end
  
	-- Allow self-arrest.
	if player ~= target then
		if not is_valid_target(player, target) then
			minetest.chat_send_player(player, "# Server: Player <" .. rename.gpn(target) .. "> is immune to accusations of trespassing.")
			return
		end
	end
  
  local ent = minetest.get_player_by_name(target)
  -- 'ent' should always be valid.
  local pos = ent:getpos()
  local owner = nil
  if minetest.get_modpath("protector") then
    owner = protector.get_node_owner(pos)
  end
  
  if not city_block:in_city(pos) then
    minetest.chat_send_player(player, "# Server: Trespasser is not within city boundaries.")
    return
  end
 
	if not owner or owner ~= player or owner == "" then
		minetest.chat_send_player(player, "# Server: Player <" .. rename.gpn(target) .. "> is not in territory owned by you.")
		return
	end
  
	-- Get player out of cart.
	local kicktype = default.detach_player_if_attached(ent)
	if kicktype == "cart" then
		minetest.chat_send_all("# Server: Someone threw <" .. rename.gpn(target) .. "> out of a minecart.")
	elseif kicktype == "boat" then
		minetest.chat_send_all("# Server: Boater <" .. rename.gpn(target) .. "> was tossed overboard.")
	elseif kicktype == "sled" then
		minetest.chat_send_all("# Server: Someone kicked <" .. rename.gpn(target) .. "> off a sled.")
	elseif kicktype == "bed" then
		local formspec = "size[8,15;true]" ..
			"bgcolor[#080808BB; true]" ..
			"button_exit[2,12;4,0.75;leave;Ok]" ..
			"label[2.7,11;You were kicked out of bed!]"

		minetest.show_formspec(target, "command_tokens:bedkicked", formspec)
		minetest.chat_send_all("# Server: <" .. rename.gpn(target) .. "> was rudely kicked out of bed.")
	end

	local jaildelay = 0
	if kicktype ~= "" then
		jaildelay = 1
	end
	-- Not sure why the delay is necessary, but it may have to do with lag.
	minetest.after(jaildelay, function()
		if not default.player_attached[target] then
			local bcb = function()
				if self_arrest then
					minetest.chat_send_all("# Server: Player <" .. rename.gpn(target) .. "> committed self-arrest.")
				else
					minetest.chat_send_all("# Server: Player <" .. rename.gpn(target) .. "> sent to jail for trespassing on <" .. rename.gpn(player) .. ">'s land.")
				end
			end
			--ent:set_pos({x=0, y=-50, z=0})
			--local jpos = {x=0, y=-50, z=0}
			--preload_tp.preload_and_teleport(target, jpos, 32, nil, bcb, nil, true)
			jail.go_to_jail(minetest.get_player_by_name(target), bcb)
		else
			minetest.chat_send_player(player, "# Server: Player <" .. rename.gpn(target) .. "> could not be detached!")
		end
	end)
  
  -- Consume token.
  -- Necessary because this code will not operate during the on_use callback.
  minetest.after(0, function()
    local ref = minetest.get_player_by_name(player)
    if ref and ref:is_player() then
      local inv = ref:get_inventory()
      inv:remove_item("main", "command_tokens:jail_player")
    end
  end)
end




command_tokens.jail_on_receive_fields = function(player, formname, fields)
	if formname == "command_tokens:jail" then
		if fields.OK then
			command_tokens.jail.execute(player:get_player_name(), fields.PLAYERNAME)
		end
	end
end



-- Register once only.
if not command_tokens.jail.registered then
	minetest.register_on_player_receive_fields(function(...)
		return command_tokens.jail_on_receive_fields(...)
	end)
	command_tokens.jail.registered = true
end




