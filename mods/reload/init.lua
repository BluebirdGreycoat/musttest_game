------------------------------------------------------------------------------
-- This file is registered as reloadable.
------------------------------------------------------------------------------

-- Everything in the mod lives here.
--
-- Note this unusual syntax: if this file is reloaded, the previous contents of
-- the table are not erased. They may be overwritten. You can use this technique
-- in your own mods as part of making them reloadable.
-- reload = reload or {}

-- The above syntax triggers warnings on minetest, to avoid these warnings
-- check if the global variable exists first, if it not exists, initialize it.
-- Same functionality without the 'Undeclared global variable' warnings.
if not minetest.global_exists("reload") then
	reload = {}
end

reload.modpath = minetest.get_modpath("reload")
dofile(reload.modpath .. "/config.lua")
dofile(reload.modpath .. "/api.lua")
dofile(reload.modpath .. "/chatcommands.lua")



-- Allow chat messages sent by this mod to be customized.
-- Usefull if you want to add coloring to the messages, etc.
-- Prefer overriding this function in your own mod, instead of changing this one.
-- Chat is only sent when a player uses a chatcommand.
reload.chat_send_player = function(name, message)
	minetest.chat_send_player(name, message)
end

-- Allow log messages from this mod to be customized.
-- Prefer overriding this function in your own mod, instead of changing this one.
-- Note that log messages are only emitted when chatcommands are used.
reload.log = function(level, message)
	minetest.log(level, message)
end



-- Register this mod itself as reloadable.
-- This is the prototype for all registrations using this mod.
-- Registrations should look something like this.
if not reload.file_registered('reload:init') then
	reload.register_file('reload:init',    reload.modpath .. '/init.lua',          false)
	reload.register_file('reload:api',     reload.modpath .. '/api.lua',           false)
	reload.register_file('reload:chat',    reload.modpath .. '/chatcommands.lua',  false)
	reload.register_file('reload:config',  reload.modpath .. '/config.lua',        false)
end

