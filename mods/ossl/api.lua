
-- This is what they call a CYA.
-- Not that it matters, since anyone who gets into the live code can simply read
-- the server settings file.
local THEKEY = ossl.default_key
ossl.default_key = nil
assert(THEKEY and #THEKEY == 16)

-- Generate a random IV. Returns base64 version for safer handling.
function ossl.geniv()
	local s = ossl.randlib.bytes(16)
	assert(#s == 16)
	return minetest.encode_base64(s)
end

-- Input IV + plaintext, get encrypted binary; or nil + errormsg.
-- The IV does not need to be secret and should be stored with the binary.
function ossl.encrypt(iv, text)
	iv = minetest.decode_base64(iv)
	assert(#iv == 16)
	local data, err = ossl.cipher:encrypt(THEKEY, iv):final(text)
	if data then
		data = minetest.encode_base64(data)
	end
	return data, err
end

-- Input IV + encrypted binary, get plaintext; or nil + errormsg.
-- The IV does not need to be secret and should live next to the binary.
function ossl.decrypt(iv, data)
	iv = minetest.decode_base64(iv)
	data = minetest.decode_base64(data)
	assert(#iv == 16)
	local data, err = ossl.cipher:decrypt(THEKEY, iv):final(data)
	return data, err
end
