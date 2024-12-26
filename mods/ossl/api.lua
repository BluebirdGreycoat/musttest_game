
-- This is what they call a CYA.
-- Not that it matters, since anyone who gets into the live code can simply read
-- the server settings file.
local THEKEY = ossl.default_key
ossl.default_key = nil
assert(THEKEY and #THEKEY == 16)

-- Input plaintext, get encrypted binary; or nil + errormsg.
function ossl.encrypt(params)
	if not ossl.have_openssl then
		return nil, "missing openssl"
	end

	-- Get cryptographically secure random IV.
	local iv = ossl.randlib.bytes(16)
	assert(#iv == 16)

	local text
	local mykey = THEKEY

	if type(params) == "table" then
		if type(params.password) == "string" and type(params.data) == "string" then
			-- Really simple way to make sure the key is 16 bytes.
			local c = params.password .. "1234567890abcdef"
			mykey = c:sub(1, 16)
			assert(#mykey == 16)
			text = params.data
		else
			-- Unsuported parameter set.
			assert(false)
		end
	elseif type(params) == "string" then
		text = params
	else
		-- Unsuported argument types.
		assert(false)
	end

	local version = 2
	local encrypted, err = ossl.cipher:encrypt(mykey, iv):final(text)

	if encrypted then
		-- Stick the encrypted data into a JSON table. This lets us handle
		-- future versions (even key changes!), because we can check the
		-- (unencrypted) JSON data for needed metadata.
		local json = {
			-- The encrypted data. Note: must b64 encode this because otherwise the
			-- JSON encoder vomits on the raw binary.
			enc = minetest.encode_base64(encrypted),

			-- Include IV with the encrypted string. Base64 encoded for same reason.
			iv = minetest.encode_base64(iv),

			-- Version ID. Nil shall be treated the same as 1. 0 is the same as 1.
			ver = version,
		}

		if json.enc and json.iv then
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

-- OLD API: Input IV + encrypted binary, get plaintext; or nil + errormsg.
-- The IV does not need to be secret and should live next to the binary.
-- This is depreciated; for backwards compatibility only.
--
-- NEW API: Input encrypted binary, get plaintext; or nil + errormsg.
function ossl.decrypt(oldiv, params)
	if not ossl.have_openssl then
		return nil, "missing openssl"
	end

	-- Handle new API detection.
	if oldiv and not params then
		-- Only 1 argument. IV should be packed with the data.
		params = oldiv
		oldiv = nil
	elseif oldiv and params then
		-- 2 arguments: IV and encrypted data.
		oldiv = minetest.decode_base64(oldiv)
		assert(#oldiv == 16)
	else
		return nil, "invalid parameters"
	end

	local text
	local mykey = THEKEY

	if type(params) == "table" then
		assert(not oldiv)
		if type(params.password) == "string" and type(params.data) == "string" then
			-- Really simple way to make sure the key is 16 bytes.
			local c = params.password .. "1234567890abcdef"
			mykey = c:sub(1, 16)
			assert(#mykey == 16)
			text = params.data
		else
			-- Unsuported parameter set.
			assert(false)
		end
	elseif type(params) == "string" then
		text = params
	else
		-- Unsupported argument types.
		assert(false)
	end

	local decoded, err
	local serialized = minetest.decode_base64(text)

	if serialized and serialized:find(":JSON45$") then
		serialized = string.gsub(serialized, ":JSON45$", "")
		local json = minetest.parse_json(serialized)
		if json then
			-- The encrypted data. This is always base64 encoded because the JSON
			-- parser vomits on raw binary.
			local enc = minetest.decode_base64(json.enc or "")

			-- IV, included with the encrypted data. Base64 encoded for same reason.
			local iv = minetest.decode_base64(json.iv or "")

			-- Version ID. Nil shall be treated the same as 1. 0 is the same as 1.
			local ver = json.ver or 1

			-- Handle versions: nil and 0, which must be treated as 1.
			if not ver or ver == 0 then
				ver = 1
			end

			if enc and (iv or oldiv) then
				if ver == 1 and oldiv then
					-- Version 1 required the IV to be given to us by our caller.
					decoded, err = ossl.cipher:decrypt(mykey, oldiv):final(enc)
				elseif ver == 2 then
					decoded, err = ossl.cipher:decrypt(mykey, iv):final(enc)
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
	elseif serialized and oldiv then
		-- It's NOT JSON encoded, fall back to the first version of this code.
		-- The very first version required our caller to give us the correct IV.
		assert(#oldiv == 16)
		decoded, err = ossl.cipher:decrypt(mykey, oldiv):final(serialized)
	else
		decoded = nil
		err = "base64 decode error"
	end

	return decoded, err
end
