

if not minetest.global_exists("portal_cb") then portal_cb = {} end
portal_cb.modpath = minetest.get_modpath("portal_cb")

portal_cb.after_use_callbacks = portal_cb.after_use_callbacks or {}
portal_cb.before_use_callbacks = portal_cb.before_use_callbacks or {}



function portal_cb.call_after_use(params)
  for k, v in ipairs(portal_cb.after_use_callbacks) do
    v(params)
  end
end

function portal_cb.call_before_use(params)
  for k, v in ipairs(portal_cb.before_use_callbacks) do
    v(params)
  end
end



function portal_cb.register_after_use(func)
  portal_cb.after_use_callbacks[#portal_cb.after_use_callbacks+1] = func
end

function portal_cb.register_before_use(func)
  portal_cb.before_use_callbacks[#portal_cb.before_use_callbacks+1] = func
end



if not portal_cb.run_once then
	local c = "portal_cb:core"
	local f = portal_cb.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	portal_cb.run_once = true
end
