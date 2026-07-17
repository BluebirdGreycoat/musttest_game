
local function FS(text)
	return minetest.formspec_escape(text)
end



--[[

	{
		type = "label",
		x = <number>,
		y = <number>,
		text = <string>,
	}

--]]
formspec.register_widget("label", {
	make = function(params)
		local E = {
			tostring(params.x),
			tostring(params.y),
			tostring(params.w or 0),
			tostring(params.h or 0),
			FS(params.text),
		}
		return "label["..E[1]..","..E[2]..";"..E[3]..","..E[4]..";"..E[5].."]"
	end,
})



--[[

	{
		type = "box",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		color = <colorstring>,
	}

--]]
formspec.register_widget("box", {
	make = function(params)
		local E = {
			tostring(params.x),
			tostring(params.y),
			tostring(params.w),
			tostring(params.h),
			params.color,
		}
		return "box["..E[1]..","..E[2]..";"..E[3]..","..E[4]..";"..E[5].."]"
	end,
})



--[[

	{
		type = "image",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		texture = <file>,
	}

--]]
formspec.register_widget("image", {
	make = function(params)
		local E = {
			tostring(params.x),
			tostring(params.y),
			tostring(params.w),
			tostring(params.h),
			params.texture,
		}
		return "image["..E[1]..","..E[2]..";"..E[3]..","..E[4]..";"..E[5].."]"
	end,
})



--[[

	{
		type = "textarea",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		name = <string>,
		text = <string>,
	}

--]]
formspec.register_widget("textarea", {
	make = function(params)
		local E = {
			tostring(params.x),
			tostring(params.y),
			tostring(params.w),
			tostring(params.h),
			params.name,
			FS(params.label or ""),
			FS(params.text),
		}
		return "textarea["..E[1]..","..E[2]..";"..E[3]..","..E[4]..";"..E[5]..";"..E[6]..";"..E[7].."]"
	end,
})



--[[

	{
		type = "button_url",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		name = <string>,
		label = <string>,
		url = <string>,
	}

--]]
formspec.register_widget("button_url", {
	make = function(params)
		local E = {
			tostring(params.x),
			tostring(params.y),
			tostring(params.w),
			tostring(params.h),
			params.name,
			FS(params.label),
			FS(params.url),
		}
		return "button_url["..E[1]..","..E[2]..";"..E[3]..","..E[4]..";"..E[5]..";"..E[6]..";"..E[7].."]"
	end,
})



--[[

	{
		type = "button",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		name = <string>,
		label = <string>,
	}

--]]
formspec.register_widget("button", {
	make = function(params)
		local E = {
			tostring(params.x),
			tostring(params.y),
			tostring(params.w),
			tostring(params.h),
			params.name,
			FS(params.label),
		}
		return "button["..E[1]..","..E[2]..";"..E[3]..","..E[4]..";"..E[5]..";"..E[6].."]"
	end,
})



--[[

	{
		type = "background9",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		texture = <file>,
		label = <string>,
	}

--]]
formspec.register_widget("background9", {
	make = function(params)
		local E = {
			tostring(params.x or 0),
			tostring(params.y or 0),
			tostring(params.w or 0),
			tostring(params.h or 0),
			params.texture,
			tostring(params.auto_clip),
		}
		return "background9["..E[1]..","..E[2]..";"..E[3]..","..E[4]..";"..E[5]..";"..E[6].."]"
	end,
})
