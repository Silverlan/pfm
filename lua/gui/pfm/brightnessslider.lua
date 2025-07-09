-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("locator.lua")

util.register_class("gui.PFMBrightnessSlider", gui.Base)

local TEX_BRIGHTNESS_GRADIENT =
	prosper.create_gradient_texture(16, 256, prosper.FORMAT_R8G8B8A8_UNORM, Vector2(0, -1), {
		{ offset = 0.0, color = Color.White },
		{ offset = 1.0, color = Color.Black },
	})
function gui.PFMBrightnessSlider:__init()
	gui.Base.__init(self)
end
function gui.PFMBrightnessSlider:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(15, 150)
	local bg = gui.create("WITexturedRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	bg:SetTexture(TEX_BRIGHTNESS_GRADIENT)

	local locator = gui.create("WIPFMLocator", self)
	local cursor = locator:Wrap("WIPFMSliderCursor")
	cursor:CenterToParentX()
	cursor:SetType(gui.PFMSliderCursor.TYPE_VERTICAL)
	cursor:AddCallback("OnValueChanged", function(el, value, fraction)
		self:CallCallbacks("OnBrightnessChanged", 1.0 - fraction)
	end)
	cursor:AddCallback("OnUserInputStarted", function()
		self:CallCallbacks("OnUserInputStarted")
	end)
	cursor:AddCallback("OnUserInputEnded", function()
		self:CallCallbacks("OnUserInputEnded")
	end)
	self.m_locator = locator
	self.m_cursor = cursor
	self:SetMouseInputEnabled(true)
end
function gui.PFMBrightnessSlider:MouseCallback(button, state, mods)
	local cursorPos = self.m_locator:GetCursorPos()
	self.m_cursor:InjectMouseInput(cursorPos, button, state, mods)
	self.m_cursor:CallCallbacks("OnCursorMoved", cursorPos.x, cursorPos.y)
	return util.EVENT_REPLY_HANDLED
end
function gui.PFMBrightnessSlider:SetBrightness(brightness)
	self.m_cursor:SetFraction(1.0 - brightness)
end
function gui.PFMBrightnessSlider:GetBrightness()
	return 1.0 - self.m_cursor:GetFraction()
end
gui.register("WIPFMBrightnessSlider", gui.PFMBrightnessSlider)
