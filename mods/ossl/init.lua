
if not minetest.global_exists("ossl") then ossl = {} end
ossl.modpath = minetest.get_modpath("ossl")
ossl.CIPHER_NAME = "AES-128-CBC"

-- You'd better have one set in the server configuration.
-- And once you set it you'd better NEVER change it.
ossl.default_key = "0123456789ABCDEF"
local KEY = minetest.settings:get("AES_CIPHER_KEY16")
if KEY and KEY ~= "" and #KEY == 16 then
	ossl.default_key = KEY
end
assert(#ossl.default_key == 16)
-- Don't use the default key! Set one in the server conf.
assert(ossl.default_key ~= "0123456789ABCDEF")

-- Input IV + plaintext, get encrypted binary; or nil + errormsg.
-- The IV does not need to be secret and should be stored with the binary.
function ossl.encrypt(iv, text)
	assert(#iv == 16)
	local data, err = ossl.cipher:encrypt(ossl.default_key, iv):final(text)
	return data, err
end

-- Input IV + encrypted binary, get plaintext; or nil + errormsg.
-- The IV does not need to be secret and should live next to the binary.
function ossl.decrypt(iv, data)
	assert(#iv == 16)
	local data, err = ossl.cipher:decrypt(ossl.default_key, iv):final(data)
	return data, err
end

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

	-- https://luarocks.org/modules/daurnimator/luaossl
	ossl.lib = require("openssl.cipher")
	assert(ossl.lib)
	ossl.cipher = ossl.lib.new(ossl.CIPHER_NAME)
	assert(ossl.cipher)

	ossl.registered = true
end
