
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
	local encrypted, err = ossl.cipher:encrypt(THEKEY, iv):final(text)
	if encrypted then
		-- Stick the encrypted data into a JSON table. This lets us handle
		-- future versions (even key changes!), because we can check the
		-- (unencrypted) JSON data for needed metadata.
		local json = {
			-- The encrypted data. Note: must b64 encode this because otherwise the
			-- JSON encoder vomits on the raw binary.
			enc = minetest.encode_base64(encrypted),

			-- Version ID. Nil shall be treated the same as 1. 0 is the same as 1.
			ver = 1,
		}
		if json.enc then
			local serialized = minetest.write_json(json)
			if serialized then
				-- Stick a tag on it. Also, the final output string is base64 encoded
				-- for safety with whatever APIs the string gets sent to afterward.
				serialized = serialized .. ":JSON45"
				encrypted = minetest.encode_base64(serialized)
			else
				err = "JSON encode error"
				encrypted = nil
			end
		else
			err = "base64 encode error"
			encrypted = nil
		end
	end
	return encrypted, err
end

-- Input IV + encrypted binary, get plaintext; or nil + errormsg.
-- The IV does not need to be secret and should live next to the binary.
function ossl.decrypt(iv, data)
	local decoded, err

	iv = minetest.decode_base64(iv)
	assert(#iv == 16)

	local serialized = minetest.decode_base64(data)

	if serialized:find(":JSON45$") then
		serialized = string.gsub(serialized, ":JSON45$", "")
		local json = minetest.parse_json(serialized)
		if json then
			-- The encrypted data. This is always base64 encoded because the JSON
			-- parser vomits on raw binary.
			local enc = minetest.decode_base64(json.enc or "")

			-- Version ID. Nil shall be treated the same as 1. 0 is the same as 1.
			local ver = json.ver or 1

			-- Handle unknown versions.
			if not ver or ver == 0 then
				ver = 1
			end

			if enc then
				if ver == 1 then
					decoded, err = ossl.cipher:decrypt(THEKEY, iv):final(enc)
				else
					err = "invalid version"
					decoded = nil
				end
			else
				err = "base64 decode error"
				decoded = nil
			end
		else
			err = "JSON decode error"
			decoded = nil
		end
	else
		-- It's NOT JSON encoded, fall back to the first version of this code.
		decoded, err = ossl.cipher:decrypt(THEKEY, iv):final(serialized)
	end

	return decoded, err
end
