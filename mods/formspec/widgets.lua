
local function FS(text)
	return minetest.formspec_escape(text)
end



-- Turn x=6, y=10, etc. into "6,10,..." (note the commas)
local function NUMPACK(params, list)
	local s = ""
	local present = {}

	for _, key in ipairs(list) do
		if params[key] then
			table.insert(present, key)
		end
	end

	for index, key in ipairs(present) do
		s = s .. tostring(params[key])
		if index < #present then
			s = s .. ","
		end
	end

	return s
end



local function CAT(e)
	return table.concat(e, ";")
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
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			FS(params.text),
		}
		return "label[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="label", x=0, y=0, w=2, h=0.9, text="Label Text"}
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
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			params.color,
		}
		return "box[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="box", x=0, y=0, w=1, h=1, color="#00ffffaa"}
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
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			params.texture,
		}
		return "image[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="image", x=0, y=0, w=1, h=1, texture="default_cobble.png"}
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
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			params.name,
			FS(params.label or ""),
			FS(params.text),
		}
		return "textarea[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="textarea", x=0, y=0, w=2, h=2, name="", label="", text="Lorum Ipsum"}
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
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			params.name,
			FS(params.label),
			FS(params.url),
		}
		return "button_url[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="button_url", x=0, y=0, w=2, h=1, name="", label="URL Button", url=""}
	end,
})



--[[

	{
		type = "field",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		name = <string>,
		label = <string>,
		url = <string>,
	}

--]]
formspec.register_widget("field", {
	make = function(params)
		local E = {
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			params.name,
			FS(params.label or ""),
			FS(params.default or ""),
		}
		local close_on_enter = ""
		if params.close_on_enter ~= nil then
			close_on_enter = "field_close_on_enter[" .. params.name .. ";" .. tostring(params.close_on_enter) .. "]"
		end
		return "field[" .. CAT(E) .. "]" .. close_on_enter
	end,

	make_params = function()
		return {type="field", x=0, y=0, w=3, h=0.5, name="", label="", default="", close_on_enter=false}
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
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			params.name,
			FS(params.label or ""),
		}
		return "button[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="button", x=0, y=0, w=2, h=0.9, name="", label="Button"}
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
		auto_clip = true|false (opt),
		x1 = <number>,
		y1 = <number> (opt),
		x2 = <number> (opt),
		y2 = <number> (opt),
	}

--]]
formspec.register_widget("background9", {
	make = function(params)
		local E = {
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			params.texture,
			(params.auto_clip ~= nil and tostring(params.auto_clip) or ""),
			NUMPACK(params, {"x1", "y1", "x2", "y2"}),
		}
		return "background9[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="background9", x=0, y=0, w=2, h=2, texture="default_cobble.png", x1=10}
	end,
})



--[[

	{
		type = "container",
		x = <number>,
		y = <number>,
	}

--]]
formspec.register_widget("container", {
	make = function(params)
		local E = {
			NUMPACK(params, {"x", "y"}),
		}
		return "container[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="container", x=0, y=0}
	end,

	requires_pair = function()
		return "container_end"
	end,
})



--[[

	{
		type = "container_end",
		x = <number>,
		y = <number>,
	}

--]]
formspec.register_widget("container_end", {
	make = function(params)
		return "container_end[]"
	end,

	-- No param constructor.
})



--[[

	{
		type = "textlist",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		name = <string>,
		label = <string>,
	}

--]]
formspec.register_widget("textlist", {
	make = function(params)
		local E = {
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			params.name,
		}

		local E2 = {
			(params.selected ~= nil and tostring(params.selected) or "")
		}

		-- Formspec escape all items.
		local items = params.itemlist or {}
		for i=1, #items, 1 do
			items[i] = FS(items[i])
		end

		return "textlist[" .. CAT(E) .. ";" .. table.concat(items, ",") .. ";" .. CAT(E2) .. "]"
	end,

	make_params = function()
		return {type="textlist", x=0, y=0, w=2, h=2, name=""}
	end,
})



--[[

	{
		type = "checkbox",
		x = <number>,
		y = <number>,
	}

--]]
formspec.register_widget("checkbox", {
	make = function(params)
		local E = {
			NUMPACK(params, {"x", "y"}),
			params.name,
			FS(params.label or ""),
			(params.selected ~= nil and tostring(params.selected) or "")
		}
		return "checkbox[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="checkbox", x=0, y=0, name="", label="", selected=false}
	end,
})
