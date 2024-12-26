
if not minetest.global_exists("ossl") then ossl = {} end
ossl.modpath = minetest.get_modpath("ossl")
ossl.CIPHER_NAME = "AES-128-CBC"

dofile(ossl.modpath .. "/conf.lua")
dofile(ossl.modpath .. "/api.lua")

if not ossl.registered then
	local c = "ossl:core"
	local f = ossl.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	--[[
		We launched an assault on the facility 6 hours ago. It failed.
		We'll have reinforcements for our support craft in 6 hours.

		Six hours? They're torturing civies, we can't wait six hours. Lets ROLL!

		Six hours, captain! Until then you'll stand down. I won't have you risking
		multimillion dollar equipment on any of your impulsive, gung-ho tactics.
		Are we clear? Are. We. Clear?

		Crystal. Sir.

		-----

		Sir, we have a situation. It's Captain Parker, sir.

		Havok?

		He's ... liberated ... a hovercraft, sir.

		*sigh*

		Launch our remaining support craft.

		Sir?

		You have your orders, lieutenant. If he survies, we'll pin a medal on him.
		Then, we'll have him shot.
	--]]

	local env = minetest.request_insecure_environment()
	if not env then
		minetest.log("error", "[ossl] Failed to get an insecure environment. " ..
			"Please add this mod to the trusted mods list in the server settings.")
		error("Failed to get an insecure environment.")
	end

	-- We have to hack Lua here. This is needed because some openssl seems to
	-- inernally use require. Use rawget/rawset to bypass ... everything.
	local _require = rawget(_G, "require")
	rawset(_G, "require", env.require)

	-- Require what's needed.
	-- https://luarocks.org/modules/daurnimator/luaossl
	local b1, lib = pcall(require, "openssl.cipher")
	local b2, randlib = pcall(require, "openssl.rand")

	if b1 and b2 then
		assert(lib and randlib)
		assert(lib.new)

		ossl.lib = lib
		ossl.randlib = randlib

		assert(ossl.lib)
		assert(ossl.randlib)

		ossl.cipher = ossl.lib.new(ossl.CIPHER_NAME)
		assert(ossl.cipher)

		ossl.have_openssl = true
	else
		minetest.log("error", "failed to find openssl, openssl functionality will not be available.")
		if type(lib) == "string" then minetest.log("error", lib) end
		if type(randlib) == "string" then minetest.log("error", randlib) end
	end

	-- Restore the order of the Universe.
	rawset(_G, "require", _require)

	ossl.registered = true
end
