--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("tutorial_slide.lua")

locale.load("pfm_tutorials.txt")

local Element = util.register_class("gui.Tutorial", gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 64)

	self.m_slides = {}
	self.m_prevSlides = {}

	self:SetThinkingEnabled(true)

	self.m_bindingLayer = "pfm_tutorial"
	local bindingLayer = input.InputBindingLayer("pfm_tutorial")
	bindingLayer:BindKey("c", "pfm_tutorial_next")
	bindingLayer:BindKey("b", "pfm_tutorial_back")
	bindingLayer:BindKey("m", "pfm_tutorial_toggle_mute")
	bindingLayer.priority = 10000

	local pm = tool.get_filmmaker()
	if util.is_valid(pm) then
		pm:AddInputBindingLayer(self.m_bindingLayer, bindingLayer)
	end
end
function Element:OnRemove()
	self:ClearSlide()

	local pm = tool.get_filmmaker()
	if util.is_valid(pm) then
		pm:RemoveInputBindingLayer(self.m_bindingLayer)
	end
end
function Element:OnThink()
	if self.m_curSlide == nil then
		return
	end
	local slideData = self.m_slides[self.m_curSlide.identifier]
	if slideData ~= nil and slideData.clearCondition ~= nil then
		local bt = self.m_curSlide.element:GetContinueButton()
		local enabled = slideData.clearCondition(self.m_curSlide.data)
		bt:SetEnabled(enabled)
		if enabled and self.m_curSlide.data.autoContinue then
			self:NextSlide()
		end
	end
end
function Element:RegisterSlide(identifier, data)
	self.m_slides[identifier] = data
end
function Element:ClearSlide()
	if self.m_curSlide == nil then
		return
	end
	util.remove(self.m_curSlide.element)
	local slideData = self.m_slides[self.m_curSlide.identifier]
	if slideData.clear ~= nil then
		slideData.clear(self.m_curSlide.data)
	end
	self.m_curSlide = nil
end
function Element:StartSlide(identifier)
	table.insert(self.m_prevSlides, identifier)
	self:ClearSlide()
	if self.m_slides[identifier] == nil then
		return
	end
	self.m_curSlide = {
		identifier = identifier,
		element = gui.create("WITutorialSlide", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1),
		data = {},
	}
	self.m_curSlide.element:SetTutorial(self)
	local slideData = self.m_slides[identifier]
	self.m_curSlide.data.autoContinue = slideData.autoContinue
	slideData.init(self.m_curSlide.data, self.m_curSlide.element)

	local bt = self.m_curSlide.element:GetContinueButton()
	if util.is_valid(bt) then
		if slideData.clearCondition ~= nil then
			-- Disable button until clear condition has been met
			bt:SetEnabled(false)
		else
			bt:SetEnabled(true)
		end
	end

	self:UpdateButtons()
end
function Element:UpdateButtons()
	local btPrev = self.m_curSlide.element:GetBackButton()
	if util.is_valid(btPrev) then
		btPrev:SetVisible(#self.m_prevSlides > 1)
	end
	local btNext = self.m_curSlide.element:GetContinueButton()
	if util.is_valid(btNext) then
		if self.m_curSlide == nil or self.m_slides[self.m_curSlide.identifier].nextSlide == nil then
			btNext:SetVisible(false)
		else
			btNext:SetVisible(true)
		end
	end
end
function Element:EndTutorial()
	self:ClearSlide()
	self:RemoveSafely()
end
function Element:NextSlide()
	local btNext = (self.m_curSlide ~= nil) and self.m_curSlide.element:GetContinueButton() or nil
	if util.is_valid(btNext) and btNext:IsEnabled() == false then
		return
	end
	if self.m_curSlide == nil or self.m_slides[self.m_curSlide.identifier].nextSlide == nil then
		self:EndTutorial()
		return
	end
	self:StartSlide(self.m_slides[self.m_curSlide.identifier].nextSlide)
end
function Element:PreviousSlide()
	local btPrev = (self.m_curSlide ~= nil) and self.m_curSlide.element:GetBackButton() or nil
	if util.is_valid(btPrev) and btPrev:IsEnabled() == false then
		return
	end
	if #self.m_prevSlides < 2 then
		return
	end
	local identifier = self.m_prevSlides[#self.m_prevSlides - 1]
	self.m_prevSlides[#self.m_prevSlides] = nil
	self.m_prevSlides[#self.m_prevSlides] = nil
	self:StartSlide(identifier)
end
gui.register("WITutorial", Element)

Element.registered_tutorials = {}
Element.register_tutorial = function(identifier, fc)
	Element.registered_tutorials[identifier] = fc
end

Element.start_tutorial = function(identifier)
	pfm.log("Starting tutorial '" .. identifier .. "'...", pfm.LOG_CATEGORY_PFM)
	if Element.registered_tutorials[identifier] == nil then
		pfm.log(
			"Failed to start tutorial '" .. identifier .. "': Unknown tutorial!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return
	end
	local fc = Element.registered_tutorials[identifier]
	local pm = tool.get_filmmaker()
	if util.is_valid(pm) == false then
		pfm.log(
			"Failed to start tutorial '" .. identifier .. "': Filmmaker is not running!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return
	end
	util.remove(Element.tutorial_element)
	local elTut = gui.create("WITutorial", pm)
	Element.tutorial_element = elTut
	elTut:SetSize(pm:GetWidth(), pm:GetHeight())
	elTut:SetZPos(10000)
	fc(elTut, pm)
end

Element.close_tutorial = function()
	util.remove(Element.tutorial_element)
end

console.register_command("pfm_tutorial_next", function(pl, ...)
	local pm = tool.get_filmmaker()
	if util.is_valid(pm) == false then
		return
	end
	if util.is_valid(Element.tutorial_element) == false then
		return
	end
	Element.tutorial_element:NextSlide()
end)

console.register_command("pfm_tutorial_back", function(pl, ...)
	local pm = tool.get_filmmaker()
	if util.is_valid(pm) == false then
		return
	end
	if util.is_valid(Element.tutorial_element) == false then
		return
	end
	Element.tutorial_element:PreviousSlide()
end)

console.register_command("pfm_tutorial_toggle_mute", function(pl, ...)
	local audio = console.get_convar_bool("pfm_tutorial_audio_enabled")
	audio = not audio
	console.run("pfm_tutorial_audio_enabled", audio and "1" or "0")
end)
