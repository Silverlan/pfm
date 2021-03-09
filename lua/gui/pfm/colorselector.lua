--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("colorwheel.lua")
include("brightnessslider.lua")
include("slider.lua")
include("/gui/editableentry.lua")
include("/gui/vbox.lua")

util.register_class("gui.PFMColorSelector",gui.Base)

locale.load("colors.txt")

gui.PFMColorSelector.COLOR_MODE_RGB = 0
gui.PFMColorSelector.COLOR_MODE_HSV = 1
gui.PFMColorSelector.COLOR_MODE_HEX = 2

function gui.PFMColorSelector:__init()
	gui.Base.__init(self)
end
function gui.PFMColorSelector:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(192,270)

	local bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	bg:SetColor(Color(32,32,32))

	self.m_contents = gui.create("WIHBox",self)
	gui.create("WIBase",self.m_contents,0,0,10,1) -- Gap

	self.m_coreContents = gui.create("WIVBox",self.m_contents)
	self.m_coreContents:SetAutoFillContentsToWidth(true)
	gui.create("WIBase",self.m_coreContents,0,0,1,10) -- Gap

	local selectorContents = gui.create("WIHBox",self.m_coreContents)
	self.m_colorWheel = gui.create("WIPFMColorWheel",selectorContents)
	self.m_colorWheel:AddCallback("OnColorChanged",function(el,col)
		if(self.m_skipCallbacks == true) then return end
		self.m_skipCallbacks = true

		self:UpdateColor(col)
		self:UpdateSliders()

		self.m_skipCallbacks = nil
	end)
	self.m_colorWheel:SetSize(256,256)
	local brightnessSlider = gui.create("WIPFMBrightnessSlider",selectorContents)
	brightnessSlider:AddCallback("OnBrightnessChanged",function(el,brightness)
		if(self.m_skipCallbacks == true) then return end
		self.m_skipCallbacks = true

		local col = self.m_colorHSV
		col.v = brightness
		self:UpdateColor(col)
		self:UpdateSliders()
		self:UpdateWheel()

		self.m_skipCallbacks = nil
	end)
	selectorContents:Update()
	brightnessSlider:SetHeight(selectorContents:GetHeight())
	brightnessSlider:SetAnchor(1,0,1,1)
	self.m_brightnessSlider = brightnessSlider
	self.m_coreContents:SetWidth(selectorContents:GetWidth())

	gui.create("WIBase",self.m_coreContents,0,0,1,10) -- Gap

	self.m_colorRect = gui.create("WIRect",self.m_coreContents)
	self.m_colorRect:SetHeight(24)

	-- ColorMode
	local colorMode = gui.create("WIDropDownMenu",self.m_coreContents)
	colorMode:AddOption(locale.get_text("rgb"),tostring(gui.PFMColorSelector.COLOR_MODE_RGB))
	colorMode:AddOption(locale.get_text("hsv"),tostring(gui.PFMColorSelector.COLOR_MODE_HSV))
	colorMode:AddOption(locale.get_text("hex"),tostring(gui.PFMColorSelector.COLOR_MODE_HEX))
	colorMode:Wrap("WIEditableEntry"):SetText(locale.get_text("color_mode"))
	colorMode:AddCallback("OnOptionSelected",function(el,option)
		local mode = tonumber(colorMode:GetOptionValue(colorMode:GetSelectedOption()))
		self:SetColorMode(mode)
	end)

	-- Preset
	local presetColorTable = {
		-- Pink Colors
		{Color.Pink,locale.get_text("color_preset_pink")},
		{Color.LightPink,locale.get_text("color_preset_light_pink")},
		{Color.HotPink,locale.get_text("color_preset_hot_pink")},
		{Color.DeepPink,locale.get_text("color_preset_deep_pink")},
		{Color.PaleVioletRed,locale.get_text("color_preset_pale_violet_red")},
		{Color.MediumVioletRed,locale.get_text("color_preset_medium_violet_red")},

		-- Red Colors
		{Color.LightSalmon,locale.get_text("color_preset_light_salmon")},
		{Color.Salmon,locale.get_text("color_preset_salmon")},
		{Color.DarkSalmon,locale.get_text("color_preset_dark_salmon")},
		{Color.LightCoral,locale.get_text("color_preset_light_coral")},
		{Color.IndianRed,locale.get_text("color_preset_indian_red")},
		{Color.Crimson,locale.get_text("color_preset_crimson")},
		{Color.FireBrick,locale.get_text("color_preset_fire_brick")},
		{Color.DarkRed,locale.get_text("color_preset_dark_red")},
		{Color.Red,locale.get_text("color_preset_red")},

		-- Orange Colors
		{Color.OrangeRed,locale.get_text("color_preset_orange_red")},
		{Color.Tomato,locale.get_text("color_preset_tomato")},
		{Color.Coral,locale.get_text("color_preset_coral")},
		{Color.DarkOrange,locale.get_text("color_preset_dark_orange")},
		{Color.Orange,locale.get_text("color_preset_orange")},

		-- Yellow Colors
		{Color.Yellow,locale.get_text("color_preset_yellow")},
		{Color.LightYellow,locale.get_text("color_preset_light_yellow")},
		{Color.LemonChiffon,locale.get_text("color_preset_lemon_chiffon")},
		{Color.LightGoldenrodYellow,locale.get_text("color_preset_light_goldenrod_yellow")},
		{Color.PapayaWhip,locale.get_text("color_preset_papaya_whip")},
		{Color.Moccasin,locale.get_text("color_preset_moccasin")},
		{Color.PeachPuff,locale.get_text("color_preset_peach_puff")},
		{Color.PaleGoldenrod,locale.get_text("color_preset_pale_goldenrod")},
		{Color.Khaki,locale.get_text("color_preset_khaki")},
		{Color.DarkKhaki,locale.get_text("color_preset_dark_khaki")},
		{Color.Gold,locale.get_text("color_preset_gold")},

		-- Brown Colors
		{Color.Cornsilk,locale.get_text("color_preset_cornsilk")},
		{Color.BlanchedAlmond,locale.get_text("color_preset_blanched_almond")},
		{Color.Bisque,locale.get_text("color_preset_bisque")},
		{Color.NavajoWhite,locale.get_text("color_preset_navajo_white")},
		{Color.Wheat,locale.get_text("color_preset_wheat")},
		{Color.BurlyWood,locale.get_text("color_preset_burly_wood")},
		{Color.Tan,locale.get_text("color_preset_tan")},
		{Color.RosyBrown,locale.get_text("color_preset_rosy_brown")},
		{Color.SandyBrown,locale.get_text("color_preset_sandy_brown")},
		{Color.Goldenrod,locale.get_text("color_preset_goldenrod")},
		{Color.DarkGoldenrod,locale.get_text("color_preset_dark_goldenrod")},
		{Color.Peru,locale.get_text("color_preset_peru")},
		{Color.Chocolate,locale.get_text("color_preset_chocolate")},
		{Color.SaddleBrown,locale.get_text("color_preset_saddle_brown")},
		{Color.Sienna,locale.get_text("color_preset_sienna")},
		{Color.Brown,locale.get_text("color_preset_brown")},
		{Color.Maroon,locale.get_text("color_preset_maroon")},

		-- Green Colors
		{Color.DarkOliveGreen,locale.get_text("color_preset_dark_olive_green")},
		{Color.Olive,locale.get_text("color_preset_olive")},
		{Color.OliveDrab,locale.get_text("color_preset_olive_drab")},
		{Color.YellowGreen,locale.get_text("color_preset_yellow_green")},
		{Color.LimeGreen,locale.get_text("color_preset_lime_green")},
		{Color.Lime,locale.get_text("color_preset_lime")},
		{Color.LawnGreen,locale.get_text("color_preset_lawn_green")},
		{Color.Chartreuse,locale.get_text("color_preset_chartreuse")},
		{Color.GreenYellow,locale.get_text("color_preset_green_yellow")},
		{Color.SpringGreen,locale.get_text("color_preset_spring_green")},
		{Color.MediumSpringGreen,locale.get_text("color_preset_medium_spring_green")},
		{Color.LightGreen,locale.get_text("color_preset_light_green")},
		{Color.PaleGreen,locale.get_text("color_preset_pale_green")},
		{Color.DarkSeaGreen,locale.get_text("color_preset_dark_sea_green")},
		{Color.MediumAquamarine,locale.get_text("color_preset_medium_aquamarine")},
		{Color.MediumSeaGreen,locale.get_text("color_preset_medium_sea_green")},
		{Color.SeaGreen,locale.get_text("color_preset_sea_green")},
		{Color.ForestGreen,locale.get_text("color_preset_forest_green")},
		{Color.Green,locale.get_text("color_preset_green")},
		{Color.DarkGreen,locale.get_text("color_preset_dark_green")},

		-- Cyan Colors
		{Color.Aqua,locale.get_text("color_preset_aqua")},
		{Color.Cyan,locale.get_text("color_preset_cyan")},
		{Color.LightCyan,locale.get_text("color_preset_light_cyan")},
		{Color.PaleTurquoise,locale.get_text("color_preset_pale_turquoise")},
		{Color.Aquamarine,locale.get_text("color_preset_aquamarine")},
		{Color.Turquoise,locale.get_text("color_preset_turquoise")},
		{Color.MediumTurquoise,locale.get_text("color_preset_medium_turquoise")},
		{Color.DarkTurquoise,locale.get_text("color_preset_dark_turquoise")},
		{Color.LightSeaGreen,locale.get_text("color_preset_light_sea_green")},
		{Color.CadetBlue,locale.get_text("color_preset_cadet_blue")},
		{Color.DarkCyan,locale.get_text("color_preset_dark_cyan")},
		{Color.Teal,locale.get_text("color_preset_teal")},

		-- Blue Colors
		{Color.LightSteelBlue,locale.get_text("color_preset_light_steel_blue")},
		{Color.PowderBlue,locale.get_text("color_preset_powder_blue")},
		{Color.LightBlue,locale.get_text("color_preset_light_blue")},
		{Color.SkyBlue,locale.get_text("color_preset_sky_blue")},
		{Color.LightSkyBlue,locale.get_text("color_preset_light_sky_blue")},
		{Color.DeepSkyBlue,locale.get_text("color_preset_deep_sky_blue")},
		{Color.DodgerBlue,locale.get_text("color_preset_dodger_blue")},
		{Color.CornflowerBlue,locale.get_text("color_preset_cornflower_blue")},
		{Color.SteelBlue,locale.get_text("color_preset_steel_blue")},
		{Color.RoyalBlue,locale.get_text("color_preset_royal_blue")},
		{Color.Blue,locale.get_text("color_preset_blue")},
		{Color.MediumBlue,locale.get_text("color_preset_medium_blue")},
		{Color.DarkBlue,locale.get_text("color_preset_dark_blue")},
		{Color.Navy,locale.get_text("color_preset_navy")},
		{Color.MidnightBlue,locale.get_text("color_preset_midnight_blue")},

		-- Purple, Violet and Magenta Colors
		{Color.Lavender,locale.get_text("color_preset_lavender")},
		{Color.Thistle,locale.get_text("color_preset_thistle")},
		{Color.Plum,locale.get_text("color_preset_plum")},
		{Color.Violet,locale.get_text("color_preset_violet")},
		{Color.Orchid,locale.get_text("color_preset_orchid")},
		{Color.Fuchsia,locale.get_text("color_preset_fuchsia")},
		{Color.Magenta,locale.get_text("color_preset_magenta")},
		{Color.MediumOrchid,locale.get_text("color_preset_medium_orchid")},
		{Color.MediumPurple,locale.get_text("color_preset_medium_purple")},
		{Color.BlueViolet,locale.get_text("color_preset_blue_violet")},
		{Color.DarkViolet,locale.get_text("color_preset_dark_violet")},
		{Color.DarkOrchid,locale.get_text("color_preset_dark_orchid")},
		{Color.DarkMagenta,locale.get_text("color_preset_dark_magenta")},
		{Color.Purple,locale.get_text("color_preset_purple")},
		{Color.Indigo,locale.get_text("color_preset_indigo")},
		{Color.DarkSlateBlue,locale.get_text("color_preset_dark_slate_blue")},
		{Color.SlateBlue,locale.get_text("color_preset_slate_blue")},
		{Color.MediumSlateBlue,locale.get_text("color_preset_medium_slate_blue")},

		-- White Colors
		{Color.White,locale.get_text("color_preset_white")},
		{Color.Snow,locale.get_text("color_preset_snow")},
		{Color.Honeydew,locale.get_text("color_preset_honeydew")},
		{Color.MintCream,locale.get_text("color_preset_mint_cream")},
		{Color.Azure,locale.get_text("color_preset_azure")},
		{Color.AliceBlue,locale.get_text("color_preset_alice_blue")},
		{Color.GhostWhite,locale.get_text("color_preset_ghost_white")},
		{Color.WhiteSmoke,locale.get_text("color_preset_white_smoke")},
		{Color.Seashell,locale.get_text("color_preset_seashell")},
		{Color.Beige,locale.get_text("color_preset_beige")},
		{Color.OldLace,locale.get_text("color_preset_old_lace")},
		{Color.FloralWhite,locale.get_text("color_preset_floral_white")},
		{Color.Ivory,locale.get_text("color_preset_ivory")},
		{Color.AntiqueWhite,locale.get_text("color_preset_antique_white")},
		{Color.Linen,locale.get_text("color_preset_linen")},
		{Color.LavenderBlush,locale.get_text("color_preset_lavender_blush")},
		{Color.MistyRose,locale.get_text("color_preset_misty_rose")},

		-- Grey and Black Colors
		{Color.Gainsboro,locale.get_text("color_preset_gainsboro")},
		{Color.LightGrey,locale.get_text("color_preset_light_grey")},
		{Color.Silver,locale.get_text("color_preset_silver")},
		{Color.DarkGray,locale.get_text("color_preset_dark_gray")},
		{Color.Gray,locale.get_text("color_preset_gray")},
		{Color.DimGray,locale.get_text("color_preset_dim_gray")},
		{Color.LightSlateGray,locale.get_text("color_preset_light_slate_gray")},
		{Color.SlateGray,locale.get_text("color_preset_slate_gray")},
		{Color.DarkSlateGray,locale.get_text("color_preset_dark_slate_gray")},
		{Color.Black,locale.get_text("color_preset_black")}
	}
	local preset = gui.create("WIDropDownMenu",self.m_coreContents)
	local function reset_color()
		if(self.m_origColor == nil) then return end
		self:SelectColor(self.m_origColor)
		self.m_origColor = nil
	end
	for _,colData in ipairs(presetColorTable) do
		local el = preset:AddOption(colData[2],tostring(colData[1]))
		if(el ~= nil) then
			local elCol = gui.create("WIRect",el)
			local border = 2
			local sz = el:GetHeight() -border *2
			elCol:SetSize(sz,sz)
			elCol:SetPos(el:GetWidth() -sz -border,border)
			elCol:SetAnchor(1,0,1,0)
			elCol:SetColor(colData[1])

			gui.create("WIOutlinedRect",elCol,0,0,elCol:GetWidth(),elCol:GetHeight(),0,0,1,1):SetColor(Color.Black)

			el:AddCallback("OnCursorEntered",function()
				self.m_origColor = self.m_origColor or self:GetSelectedColorRGB()
				self:SelectColor(colData[1])
			end)
			-- el:AddCallback("OnCursorExited",reset_color)
		end
	end
	preset:AddCallback("OnMenuClosed",reset_color)
	preset:AddCallback("OnOptionSelected",function(el,option)
		self.m_origColor = nil
		local col = Color(preset:GetOptionValue(preset:GetSelectedOption()))
		self:SelectColor(col)
	end)
	--preset:Wrap("WIEditableEntry"):SetText(locale.get_text("preset"))

	local function create_slider(text,min,max,fApply)
		local slider = gui.create("WIPFMSlider",self.m_coreContents)
		slider:SetText(locale.get_text(text))
		slider:SetRange(min,max,0)
		slider:AddCallback("OnLeftValueChanged",function(el,value)
			if(self.m_skipCallbacks) then return end
			self.m_skipCallbacks = true
			fApply(value)
			self.m_skipCallbacks = nil
		end)
		slider:SetVisible(false)
		return slider
	end
	self.m_redSlider = create_slider("red",0,255,function(value)
		local col = self:GetSelectedColorRGB()
		col.r = value
		self:UpdateColor(col)
		self:UpdateWheel()
		self:UpdateBrightnessSlider()
	end)
	self.m_greenSlider = create_slider("green",0,255,function(value)
		local col = self:GetSelectedColorRGB()
		col.g = value
		self:UpdateColor(col)
		self:UpdateWheel()
		self:UpdateBrightnessSlider()
	end)
	self.m_blueSlider = create_slider("blue",0,255,function(value)
		local col = self:GetSelectedColorRGB()
		col.b = value
		self:UpdateColor(col)
		self:UpdateWheel()
		self:UpdateBrightnessSlider()
	end)

	self.m_hueSlider = create_slider("hue",0,360,function(value)
		local col = self:GetSelectedColorHSV()
		col.h = value
		self:UpdateColor(col)
		self:UpdateWheel()
		self:UpdateBrightnessSlider()
	end)
	self.m_saturationSlider = create_slider("saturation",0,1,function(value)
		local col = self:GetSelectedColorHSV()
		col.s = value
		self:UpdateColor(col)
		self:UpdateWheel()
		self:UpdateBrightnessSlider()
	end)
	self.m_valueSlider = create_slider("hsv_value",0,1,function(value)
		local col = self:GetSelectedColorHSV()
		col.v = value
		self:UpdateColor(col)
		self:UpdateWheel()
		self:UpdateBrightnessSlider()
	end)

	local teHex = gui.create("WITextEntry",self.m_coreContents)
	teHex:AddCallback("OnTextEntered",function(pEntry)
		self.m_skipCallbacks = true

		self:UpdateColor(pEntry:GetText())
		self:UpdateWheel()
		self:UpdateBrightnessSlider()
		self:UpdateSliders()

		self.m_skipCallbacks = nil
	end)
	local teHexWrapper = teHex:Wrap("WIEditableEntry")
	teHexWrapper:SetVisible(false)
	teHexWrapper:SetText(locale.get_text("hex"))
	self.m_teHex = teHex
	self.m_teHexWrapper = teHexWrapper

	self:SelectColor(Color.White)
	self:SetColorMode(gui.PFMColorSelector.COLOR_MODE_RGB)
	colorMode:SelectOption(0)

	gui.create("WIBase",self.m_contents,0,0,10,1) -- Gap
	gui.create("WIBase",self.m_coreContents,0,0,1,10) -- Gap

	self.m_coreContents:Update()
	self.m_contents:Update()
	self:SizeToContents()
end
function gui.PFMColorSelector:SetColorMode(colorMode)
	self.m_colorMode = colorMode
	self:UpdateSliders()
end
function gui.PFMColorSelector:UpdateSliders()
	self.m_redSlider:SetVisible(self.m_colorMode == gui.PFMColorSelector.COLOR_MODE_RGB)
	self.m_greenSlider:SetVisible(self.m_colorMode == gui.PFMColorSelector.COLOR_MODE_RGB)
	self.m_blueSlider:SetVisible(self.m_colorMode == gui.PFMColorSelector.COLOR_MODE_RGB)

	self.m_hueSlider:SetVisible(self.m_colorMode == gui.PFMColorSelector.COLOR_MODE_HSV)
	self.m_saturationSlider:SetVisible(self.m_colorMode == gui.PFMColorSelector.COLOR_MODE_HSV)
	self.m_valueSlider:SetVisible(self.m_colorMode == gui.PFMColorSelector.COLOR_MODE_HSV)

	self.m_teHexWrapper:SetVisible(self.m_colorMode == gui.PFMColorSelector.COLOR_MODE_HEX)

	self.m_redSlider:SetValue(self.m_colorRGB.r)
	self.m_greenSlider:SetValue(self.m_colorRGB.g)
	self.m_blueSlider:SetValue(self.m_colorRGB.b)

	self.m_hueSlider:SetValue(self.m_colorHSV.h)
	self.m_saturationSlider:SetValue(self.m_colorHSV.s)
	self.m_valueSlider:SetValue(self.m_colorHSV.v)

	self.m_teHex:SetText(self.m_colorRGB:ToHexColorRGB())
end
function gui.PFMColorSelector:UpdateWheel()
	self.m_colorWheel:SelectColor(self.m_colorHSV)
end
function gui.PFMColorSelector:UpdateBrightnessSlider()
	self.m_brightnessSlider:SetBrightness(self:GetBrightness())
end
function gui.PFMColorSelector:GetColorWheel() return self.m_colorWheel end
function gui.PFMColorSelector:GetSelectedColorRGB() return self.m_colorRGB end
function gui.PFMColorSelector:GetSelectedColorHSV() return self.m_colorHSV end
function gui.PFMColorSelector:GetSelectedColorHex() return self.m_colorRGB:ToHexColorRGB() end
function gui.PFMColorSelector:SelectColor(color)
	self.m_skipCallbacks = true
	self:UpdateColor(color)
	self:UpdateWheel()
	self:UpdateBrightnessSlider()
	self:UpdateSliders()
	self.m_skipCallbacks = nil
end
function gui.PFMColorSelector:SetBrightness(brightness)
	local col = self.m_colorHSV
	col.v = brightness
	self:SetColor(col)
end
function gui.PFMColorSelector:GetBrightness() return self.m_colorHSV.v end
function gui.PFMColorSelector:UpdateColor(color)
	local type = util.get_type_name(color)
	if(type == "Color") then
		self.m_colorRGB = color
		self.m_colorHSV = color:ToHSVColor()
	elseif(type == "string") then
		self.m_colorRGB = Color.CreateFromHexColor(color)
		self.m_colorHSV = self.m_colorRGB:ToHSVColor()
	else
		self.m_colorRGB = color:ToRGBColor()
		self.m_colorHSV = color
	end
	self.m_colorRect:SetColor(self.m_colorRGB)
	self:CallCallbacks("OnColorChanged")
end
function gui.PFMColorSelector:GetSelectedColor() return self.m_color end
gui.register("WIPFMColorSelector",gui.PFMColorSelector)
