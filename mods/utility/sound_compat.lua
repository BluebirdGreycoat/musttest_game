
local old_node_register = minetest.register_node
local old_craftitem_register = minetest.register_craftitem
local old_tool_register = minetest.register_tool

function minetest.register_node(name, def)
	if def.sounds and not def.sound then
		def.sound = def.sounds
	end
	if def.sound and not def.sounds then
		def.sounds = def.sound
	end
	old_node_register(name, def)
end

function minetest.register_craftitem(name, def)
	if def.sounds and not def.sound then
		def.sound = def.sounds
	end
	if def.sound and not def.sounds then
		def.sounds = def.sound
	end
	old_craftitem_register(name, def)
end

function minetest.register_tool(name, def)
	if def.sounds and not def.sound then
		def.sound = def.sounds
	end
	if def.sound and not def.sounds then
		def.sounds = def.sound
	end
	old_tool_register(name, def)
end
