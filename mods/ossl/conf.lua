
if minetest.is_singleplayer() then
	ossl.default_key = "0123456789ABCDEF"
	return
end

-- You'd better have one set in the server configuration.
-- And once you set it you'd better NEVER change it.
ossl.default_key = "0123456789ABCDEF"
local KEY = minetest.settings:get("AES_CIPHER_KEY16")
if KEY and KEY ~= "" then
	local tokens = KEY:split(" ")
	assert(#tokens == 16)

	-- You need 16 integer tokens. Values between 0 .. 255
	-- I'd rather do it this way than mess around with file IO at this time.
	local s = ""
	for k = 1, 16 do
		local v = tonumber(tokens[k])
		assert(v >= 0 and v <= 255)
		s = s .. string.char(v) -- Convert number to literal char.
	end
	ossl.default_key = s
end
assert(#ossl.default_key == 16)
-- Don't use the default key! Set one in the server conf.
assert(ossl.default_key ~= "0123456789ABCDEF")
