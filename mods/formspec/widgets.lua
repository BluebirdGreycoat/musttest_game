
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
		w = <number>,
		h = <number>,
		text = <string>,
	}

--]]
formspec.register_widget("label", {
	make = function(params)
		local E = {
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			FS(type(params.text) == "string" and params.text or ""),
		}
		return "label[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="label", x=0, y=0, w=2, h=0.9, text="Label Text"}
	end,
})



--[[

	{
		type = "vertlabel",
		x = <number>,
		y = <number>,
		text = <string>,
	}

--]]
formspec.register_widget("vertlabel", {
	make = function(params)
		local E = {
			NUMPACK(params, {"x", "y"}),
			FS(type(params.text) == "string" and params.text or ""),
		}
		return "vertlabel[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="vertlabel", x=0, y=0, text="Label Text"}
	end,
})



--[[

	{
		type = "item_image",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		item_name = <string>,
	}

--]]
formspec.register_widget("item_image", {
	make = function(params)
		local E = {
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			tostring(params.item_name),
		}
		return "item_image[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="item_image", x=0, y=0, w=1, h=1, item_name="default:cobble"}
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
			NUMPACK(params, {"x1", "y1", "x2", "y2"}),
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
		label = <string>,
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
		type = "hypertext",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		name = <string>,
		text = <string>,
	}

--]]
formspec.register_widget("hypertext", {
	make = function(params)
		local E = {
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			params.name,
			FS(params.text),
		}
		return "hypertext[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="hypertext", x=0, y=0, w=2, h=2, name="", text="<b>Testing:</b> Lorem Ipsom"}
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
		return {type="button_url", x=0, y=0, w=2, h=0.9, name="", label="URL Button", url=""}
	end,
})



--[[

	{
		type = "button_url_exit",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		name = <string>,
		label = <string>,
		url = <string>,
	}

--]]
formspec.register_widget("button_url_exit", {
	make = function(params)
		local E = {
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			params.name,
			FS(params.label),
			FS(params.url),
		}
		return "button_url_exit[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="button_url_exit", x=0, y=0, w=2.5, h=0.9, name="", label="URL Button Exit", url=""}
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
		default = <string>,
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
		type = "pwdfield",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		name = <string>,
		label = <string>,
	}

--]]
formspec.register_widget("pwdfield", {
	make = function(params)
		local E = {
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			params.name,
			FS(params.label or ""),
		}
		local close_on_enter = ""
		if params.close_on_enter ~= nil then
			close_on_enter = "field_close_on_enter[" .. params.name .. ";" .. tostring(params.close_on_enter) .. "]"
		end
		return "pwdfield[" .. CAT(E) .. "]" .. close_on_enter
	end,

	make_params = function()
		return {type="pwdfield", x=0, y=0, w=3, h=0.5, name="", label="", close_on_enter=false}
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
		type = "button_exit",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		name = <string>,
		label = <string>,
	}

--]]
formspec.register_widget("button_exit", {
	make = function(params)
		local E = {
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			params.name,
			FS(params.label or ""),
		}
		return "button_exit[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="button_exit", x=0, y=0, w=2, h=0.9, name="", label="Button Exit"}
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
		type = "background",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		texture = <file>,
		auto_clip = true|false (opt),
	}

--]]
formspec.register_widget("background", {
	make = function(params)
		local E = {
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			params.texture,
			(params.auto_clip ~= nil and tostring(params.auto_clip) or ""),
		}
		return "background[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="background", x=0, y=0, w=2, h=2, texture="default_cobble.png"}
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

	end_tag = "container_end",
})



--[[

	{
		type = "container_end",
	}

--]]
formspec.register_widget("container_end", {
	make = function(params)
		return "container_end[]"
	end,

	make_params = function()
		return {type="container_end"}
	end,

	allow_editor_creation = false,
	allow_editor_deletion = false,
	show_in_editor = false,

	begin_tag = "container",
})



--[[

	{
		type = "textlist",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		name = <string>,
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



--[[

	{
		type = "tabheader",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		name = <string>,
		current_tab = <number>,
		transparent = <boolean>,
		draw_border = <boolean>,
	}

--]]
formspec.register_widget("tabheader", {
	make = function(params)
		local E = {
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			params.name,
		}

		local E2 = {
			(params.current_tab ~= nil and tostring(params.current_tab) or ""),
			(params.transparent ~= nil and tostring(params.transparent) or ""),
			(params.draw_border ~= nil and tostring(params.draw_border) or ""),
		}

		-- Formspec escape all items.
		local items = params.itemlist or {}
		for i=1, #items, 1 do
			items[i] = FS(items[i])
		end

		return "tabheader[" .. CAT(E) .. ";" .. table.concat(items, ",") .. ";" .. CAT(E2) .. "]"
	end,

	make_params = function()
		return {type="tabheader", x=0, y=0, w=6, h=0.5, name="", itemlist={"Tab1", "Tab2", "Tab3"}}
	end,
})



--[[

	{
		type = "scroll_container",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		scrollbar_name = <string>,
		orientation = <string>,
		scroll_factor = <number>,
		content_padding = <number>,
	}

--]]
formspec.register_widget("scroll_container", {
	make = function(params)
		local E = {
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			params.scrollbar_name,
			params.orientation,
			(type(params.scroll_factor) == "number" and params.scroll_factor > 0.1 and params.scroll_factor) or "",
			(type(params.content_padding) == "number" and params.content_padding) or "",
		}
		return "scroll_container[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="scroll_container", x=0, y=0, w=5, h=5, scrollbar_name="", orientation=""}
	end,

	end_tag = "scroll_container_end",
})



--[[

	{
		type = "scroll_container_end",
	}

--]]
formspec.register_widget("scroll_container_end", {
	make = function(params)
		return "scroll_container_end[]"
	end,

	make_params = function()
		return {type="scroll_container_end"}
	end,

	allow_editor_creation = false,
	allow_editor_deletion = false,
	show_in_editor = false,

	begin_tag = "scroll_container",
})



--[[

	{
		type = "list",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		inventory_location = <string>,
		list_name = <string>,
		start_index = <number>,
	}

--]]
formspec.register_widget("list", {
	make = function(params)
		local E = {
			params.inventory_location or "current_player",
			params.list_name or "main",
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			(type(params.start_index) == "number" and params.start_index >= 0 and params.start_index) or "",
		}
		return "list[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="list", x=0, y=0, w=5, h=2, list_name="main", inventory_location="current_player"}
	end,
})



--[[

	{
		type = "listring",
		inventory_location = <string>,
		list_name = <string>,
	}

--]]
formspec.register_widget("listring", {
	make = function(params)
		local E = {
			params.inventory_location or "current_player",
			params.list_name or "main",
		}
		return "listring[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="listring", list_name="main", inventory_location="current_player"}
	end,
})



--[[

	{
		type = "listcolors",
		slot_bg_normal = <string>,
		slot_bg_hover = <string>,
		slot_border = <string>,
		tooltip_bgcolor = <string>,
		tooltip_fontcolor = <string>,
	}

--]]
formspec.register_widget("listcolors", {
	make = function(params)
		local E = {
			params.slot_bg_normal or "",
			params.slot_bg_hover or "",
			params.slot_border or "",
			params.tooltip_bgcolor or "",
			params.tooltip_fontcolor or "",
		}
		return "listcolors[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="listcolors", slot_bg_normal="#00000069", slot_bg_hover="#5A5A5A", slot_border="#141318", tooltip_bgcolor="#30434C", tooltip_fontcolor="#FFF"}
	end,
})



--[[

	{
		type = "tooltip",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		text = <string>,
		bgcolor = <string>,
		fontcolor = <number>,
	}

--]]
formspec.register_widget("tooltip", {
	make = function(params)
		local E = {
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			FS(params.text or ""),
			params.bgcolor or "",
			params.fontcolor or "",
		}
		return "tooltip[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="tooltip", x=0, y=0, w=2, h=2, text="", bgcolor="", fontcolor=""}
	end,
})



--[[

	{
		type = "hypertip",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		text = <string>,
		width = <number>,
		name = <string>,
	}

--]]
formspec.register_widget("hypertip", {
	make = function(params)
		local E = {
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			NUMPACK(params, {"static_x", "static_y"}),
			tostring(params.width or 20),
			params.name or "",
			FS(params.text or ""),
		}
		return "hypertip[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="hypertip", x=0, y=0, w=2, h=2, text="", width=20, name=""}
	end,
})



--[[

	{
		type = "animated_image",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		texture = <string>,
		name = <string>,
		frame_count = <number>,
		frame_duration = <number>,
		frame_start = <number>,
		x1 = <number>,
		y1 = <number>,
		x2 = <number>,
		y2 = <number>,
	}

--]]
formspec.register_widget("animated_image", {
	make = function(params)
		local E = {
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			params.name,
			(type(params.texture) == "string" and params.texture:len() > 0 and params.texture) or "default_ice.png",
			params.frame_count,
			params.frame_duration,
			(type(params.frame_start) == "number" and params.frame_start >= 1 and tostring(params.frame_start)) or "",
			NUMPACK(params, {"x1", "y1", "x2", "y2"}),
		}
		return "animated_image[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="animated_image", x=0, y=0, w=2, h=2, texture="default_lava_source_animated.png", name="", frame_count=8, frame_duration=100}
	end,
})



--[[

	{
		type = "bgcolor",
		bgcolor = <string>,
		fullscreen = <string>,
		fbgcolor = <string>,
	}

--]]
formspec.register_widget("bgcolor", {
	make = function(params)
		local E = {
			params.bgcolor,
			params.fullscreen,
			params.fbgcolor,
		}
		return "bgcolor[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="bgcolor", bgcolor="", fullscreen="", fbgcolor=""}
	end,
})



--[[

	{
		type = "model",
		x = <number>,
		y = <number>,
		w = <number>,
		h = <number>,
		name = <string>,
		mesh = <string>,
		textures = <string>,
		rx = <number>,
		ry = <number>,
		continuous = <boolean>,
		mouse_control = <boolean>,
		frame_loop_range = <number,number>,
		animation_speed = <number>,
	}

--]]
formspec.register_widget("model", {
	make = function(params)
		local E = {
			NUMPACK(params, {"x", "y"}),
			NUMPACK(params, {"w", "h"}),
			params.name,
			params.mesh,
			params.textures,
			NUMPACK(params, {"rx", "ry"}),
			(params.continuous ~= nil and tostring(params.continuous) or ""),
			(params.mouse_control ~= nil and tostring(params.mouse_control) or ""),
			tostring(params.frame_loop_range or ""),
			tostring(params.animation_speed or ""),
		}
		return "model[" .. CAT(E) .. "]"
	end,

	make_params = function()
		return {type="model", x=0, y=0, w=3, h=3, rx=0, ry=200, name="", mesh="3d_armor_character.b3d", textures="character_11.png,3d_armor_trans.png,default_tool_steelsword.png"}
	end,
})
