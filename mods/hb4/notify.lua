
if not minetest.global_exists("notify") then notify = {} end

local sub = vector.subtract
local add = vector.add
local find = minetest.find_nodes_in_area
local getn = minetest.get_node
local items = minetest.registered_items
local after = minetest.after

function notify.do_notify(pos)
	--minetest.chat_send_player("MustTest", "# Server: Executing notify @ " .. minetest.pos_to_string(pos) .. "!")

	local minp = sub(pos, 1)
	local maxp = add(pos, 1)
	local nodes = find(minp, maxp, "group:want_notify")
	if nodes and #nodes > 0 then
		--minetest.chat_send_player("MustTest", "# Server: Notifying " .. #nodes .. " node(s)!")

		for i=1, #nodes do
			local p = nodes[i]
			-- Don't call `on_notify' for the node that triggered the action.
			if p.x ~= pos.x or p.y ~= pos.y or p.z ~= pos.z then
				local nn = getn(p).name
				local def = items[nn]
				if def and def.on_notify then
					--minetest.chat_send_player("MustTest", "# Server: Notifying node @ " .. minetest.pos_to_string(p) .. "!")

					-- Pos of node to be notified, pos of node that caused the notification.
					def.on_notify(p, pos)
				end
			end
		end
	end
end

local do_notify = notify.do_notify

-- Call this function from `on_construct' or `on_destruct'.
-- Adjacent nodes will not be notified until AFTER the operation completes.
-- Put `notify_construct = 1' in node groups.
-- Put `notify_destruct = 1' in node groups.
-- If either are present, appropriate callbacks will be set up automatically.
function notify.notify_adjacent(pos)
	after(0, do_notify, {x=pos.x, y=pos.y, z=pos.z})
end

