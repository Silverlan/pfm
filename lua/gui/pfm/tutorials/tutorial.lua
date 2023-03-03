--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("tutorial_slide.lua")

local Element = util.register_class("gui.Tutorial",gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,64)

	local yOffset = -20
	local btPrev = self:CreateButton("Go Back",function() self:PreviousSlide() end)
	btPrev:SetY(self:GetHeight() -btPrev:GetHeight() +yOffset)
	btPrev:SetAnchor(0,1,0,1)
	btPrev:SetVisible(false)
	self.m_buttonPrev = btPrev

	local btNext = self:CreateButton("Continue",function() self:NextSlide() end)
	btNext:SetX(self:GetWidth() -btNext:GetWidth())
	btNext:SetY(self:GetHeight() -btNext:GetHeight() +yOffset)
	btNext:SetAnchor(1,1,1,1)
	btNext:SetEnabledColor(Color.Lime)
	btNext:SetDisabledColor(Color.Red)
	btNext:SetEnabled(false)
	self.m_buttonNext = btNext

	local btEnd = self:CreateButton("End Tutorial",function() self:EndTutorial() end)
	btEnd:SetX(self:GetWidth() -btEnd:GetWidth())
	btEnd:SetY(btNext:GetTop() -btEnd:GetHeight())
	btEnd:SetAnchor(1,1,1,1)
	self.m_buttonEnd = btEnd

	self.m_slides = {}
	self.m_prevSlides = {}

	self:SetThinkingEnabled(true)
end
function Element:CreateButton(text,f)
	local bt = gui.PFMButton.create(self,"gui/pfm/icon_cp_generic_button_large","gui/pfm/icon_cp_generic_button_large_activated",function()
		f()
		return util.EVENT_REPLY_HANDLED
	end)
	bt:SetSize(100,32)
	bt:SetText(text)
	bt:SetZPos(1)
	return bt
end
function Element:OnThink()
	if(self.m_curSlide == nil) then return end
	local slideData = self.m_slides[self.m_curSlide.identifier]
	if(slideData ~= nil and slideData.clearCondition ~= nil) then
		self.m_buttonNext:SetEnabled(slideData.clearCondition(self.m_curSlide.data))
	end
end
function Element:OnRemove()
	self:ClearSlide()
end
function Element:RegisterSlide(identifier,data)
	self.m_slides[identifier] = data
end
function Element:ClearSlide()
	if(self.m_curSlide == nil) then return end
	util.remove(self.m_curSlide.element)
	local slideData = self.m_slides[self.m_curSlide.identifier]
	if(slideData.clear ~= nil) then slideData.clear(self.m_curSlide.data) end
	self.m_curSlide = nil
end
function Element:StartSlide(identifier)
	table.insert(self.m_prevSlides,identifier)
	self:ClearSlide()
	if(self.m_slides[identifier] == nil) then return end
	self.m_curSlide = {
		identifier = identifier,
		element = gui.create("WITutorialSlide",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1),
		data = {}
	}
	self.m_slides[identifier].init(self.m_curSlide.data,self.m_curSlide.element)

	local slideData = self.m_slides[identifier]
	if(slideData.clearCondition ~= nil) then
		-- Disable button until clear condition has been met
		self.m_buttonNext:SetEnabled(false)
	else self.m_buttonNext:SetEnabled(true) end

	self:UpdateButtons()
end
function Element:UpdateButtons()
	self.m_buttonPrev:SetVisible(#self.m_prevSlides > 1)
	if(self.m_curSlide == nil or self.m_slides[self.m_curSlide.identifier].nextSlide == nil) then
		self.m_buttonNext:SetVisible(false)
	else
		self.m_buttonNext:SetVisible(true)
	end
end
function Element:EndTutorial()
	self:ClearSlide()
	self:RemoveSafely()
end
function Element:NextSlide()
	if(self.m_curSlide == nil or self.m_slides[self.m_curSlide.identifier].nextSlide == nil) then
		self:EndTutorial()
		return
	end
	self:StartSlide(self.m_slides[self.m_curSlide.identifier].nextSlide)
end
function Element:PreviousSlide()
	if(#self.m_prevSlides < 2) then return end
	local identifier = self.m_prevSlides[#self.m_prevSlides -1]
	self.m_prevSlides[#self.m_prevSlides] = nil
	self.m_prevSlides[#self.m_prevSlides] = nil
	self:StartSlide(identifier)
end
gui.register("WITutorial",Element)
