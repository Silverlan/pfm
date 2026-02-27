-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("tutorial_slide.lua")

locale.load("pfm_tutorials.txt")

local Element = util.register_class("gui.Tutorial", gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 64)

	self.m_curSlideIndex = 0
	self.m_totalSlideCount = 0
	self.m_slides = {}
	self.m_prevSlides = {}
	self.m_tutorialData = {}

	self:SetThinkingEnabled(true)
	self:SetAudioEnabled(true)

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
function Element:IsAudioEnabled()
	return self.m_audioEnabled
end
function Element:SetAudioEnabled(enabled)
	self.m_audioEnabled = enabled
end
function Element:GetCurrentSlideIndex()
	return self.m_curSlideIndex
end
function Element:GetTotalSlideCount()
	return self.m_totalSlideCount
end
function Element:OnThink()
	if self.m_curSlide == nil then
		return
	end
	local slideData = self.m_slides[self.m_curSlide.identifier]
	if slideData ~= nil and slideData.clearCondition ~= nil then
		local bt = self.m_curSlide.element:GetContinueButton()
		local enabled = slideData.clearCondition(self.m_tutorialData, self.m_curSlide.data, self.m_curSlide.element)
		if enabled and bt:IsEnabled() == false then
            local playInfo = sound.PlayInfo()
            playInfo.flags = bit.bor(playInfo.flags, sound.FCREATE_MONO)
            playInfo.gain = 0.5
            playInfo.pitch = 1.0
			sound.play("ui/tutorial_success", sound.TYPE_EFFECT, playInfo)
		end
		bt:SetEnabled(enabled)
		if enabled and self.m_curSlide.data.autoContinue then
			self:NextSlide()
		end
	end
end
function Element:RegisterSlide(identifier, data)
	self.m_slides[identifier] = data
	self.m_totalSlideCount = self.m_totalSlideCount + 1
end
function Element:ClearSlide()
	if self.m_curSlide == nil then
		return
	end
	util.remove(self.m_curSlide.element)
	local slideData = self.m_slides[self.m_curSlide.identifier]
	if slideData.clear ~= nil then
		slideData.clear(self.m_tutorialData, self.m_curSlide.data)
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
		element = gui.create("tutorial_slide", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1),
		data = {},
	}
	self.m_curSlide.element:SetIdentifier(identifier)
	self.m_curSlide.element:SetTutorial(self)
	local slideData = self.m_slides[identifier]
	self.m_curSlide.data.autoContinue = slideData.autoContinue
	slideData.init(self.m_tutorialData, self.m_curSlide.data, self.m_curSlide.element)
	self.m_curSlide.element:UpdateCurrentSlideText(self:GetCurrentSlideIndex(), self:GetTotalSlideCount())

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
	self.m_curSlideIndex = self.m_curSlideIndex + 1
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
	self.m_curSlideIndex = self.m_curSlideIndex - 1
	local identifier = self.m_prevSlides[#self.m_prevSlides - 1]
	self.m_prevSlides[#self.m_prevSlides] = nil
	self.m_prevSlides[#self.m_prevSlides] = nil
	self:StartSlide(identifier)
end
gui.register("tutorial", Element)

Element.registered_tutorials = Element.registered_tutorials or {}
Element.register_tutorial = function(identifier, infoFileLocation, fc)
	locale.load("pfm_tut_" .. identifier .. ".txt")

	Element.registered_tutorials[identifier] = Element.registered_tutorials[identifier] or {}
	local tutorial = Element.registered_tutorials[identifier]
	tutorial.start = fc
	tutorial.path = infoFileLocation
end

Element.start_tutorial = function(identifier)
	pfm.log("Starting tutorial '" .. identifier .. "'...", pfm.LOG_CATEGORY_PFM)
	local tutorial = Element.registered_tutorials[identifier]
	if tutorial == nil or tutorial.start == nil then
		pfm.log(
			"Failed to start tutorial '" .. identifier .. "': Unknown tutorial!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return
	end
	local fc = Element.registered_tutorials[identifier].start
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
	local elTut = gui.create("tutorial", pm)
	Element.tutorial_element = elTut
	Element.tutorial_identifier = identifier
	elTut:SetSize(pm:GetWidth(), pm:GetHeight())
	elTut:SetAnchor(0, 0, 1, 1)
	elTut:SetZPos(10000)
	fc(elTut, pm)
end

Element.get_current_tutorial_identifier = function()
	return Element.tutorial_identifier
end

Element.close_tutorial = function()
	util.remove(Element.tutorial_element)
	Element.tutorial_identifier = nil
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
