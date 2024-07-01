
-- This is what they call a CYA.
-- Not that it matters, since anyone who gets into the live code can simply read
-- the server settings file.
local THEKEY = ossl.default_key
ossl.default_key = nil
assert(THEKEY and #THEKEY == 16)

-- Input IV + plaintext, get encrypted binary; or nil + errormsg.
-- The IV does not need to be secret and should be stored with the binary.
function ossl.encrypt(iv, text)
	assert(#iv == 16)
	local data, err = ossl.cipher:encrypt(THEKEY, iv):final(text)
	return data, err
end

-- Input IV + encrypted binary, get plaintext; or nil + errormsg.
-- The IV does not need to be secret and should live next to the binary.
function ossl.decrypt(iv, data)
	assert(#iv == 16)
	local data, err = ossl.cipher:decrypt(THEKEY, iv):final(data)
	return data, err
end
