
signs.register_callback("update_sign_text", "signs", function(params)
	core.log('action', ('[signs] <%s> writes text to sign at %s (message len: %d)')
		:format(params.pname, core.pos_to_string(params.pos), params.message:len())
	)
end)
