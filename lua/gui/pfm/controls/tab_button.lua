-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/pfm/widgets/progress_bar.lua")
include("button.lua")

local Element = util.register_class("gui.PFMTabButton", gui.PFMBaseButton)
function Element:OnInitialize()
	gui.PFMBaseButton.OnInitialize(self)

	self:ApplySize(128, 32)

	self:SetType(gui.PFMBaseButton.BUTTON_TYPE_TAB)

	self.m_progressBar = gui.create("pfm_progress_bar", self, 0, self:GetHeight() - 5, self:GetWidth(), 5, 0, 1, 1, 1)
	self.m_progressBar:SetVisible(false)

	self:SetMouseInputEnabled(true)

	self:SetActive(false)
	self:EnableThinking()

	self:SetSize(132, 28)

	gui.enable_drag_and_drop(self, "Panel", function(elGhost)
		elGhost:SetAlpha(128)
		local droppedOnTabBar = false
		elGhost:AddCallback("OnDragDropped", function(elGhost, elHover)
			droppedOnTabBar = true
			local targetFrame = elHover:FindAncestorByClass("pfm_frame")
			if(targetFrame == nil) then return end
			local frame = self:GetFrame()
			if(util.is_same_object(frame, targetFrame)) then return end
			frame:MovePanelToFrame(self.m_panelIdentifier, targetFrame)
		end)
		elGhost:AddCallback("OnDragStopped", function(elGhost)
			if(droppedOnTabBar) then return end
			time.create_simple_timer(0.0, function()
				local frame = self:IsValid() and self:GetFrame() or nil
				if util.is_valid(frame) == false then
					return
				end
				frame:DetachTab(self)
			end)
		end)
	end)
end
function Element:SetFrame(frame, identifier)
	self.m_frame = frame
	self.m_panelIdentifier = identifier
end
function Element:GetFrame()
	return self.m_frame
end
function Element:GetContents()
	return self.m_contentsPanel
end
function Element:SetContents(panel)
	self.m_contentsPanel = panel
	panel:SetVisible(false)

	panel:AddCallback("OnProgressChanged", function(el, progress)
		self:SetProgress(progress)
	end)
end
function Element:SetProgress(progress)
	if util.is_valid(self.m_progressBar) == false then
		return
	end
	self.m_progressBar:SetProgress(progress)
	self.m_progressBar:SetVisible(progress > 0.0)
end
function Element:GetProgress()
	return util.is_valid(self.m_progressBar) and self.m_progressBar:GetProgress() or 0.0
end
function Element:MouseCallback(button, state, mods)
	if button == input.MOUSE_BUTTON_LEFT then
		if state == input.STATE_RELEASE then
			self:CallCallbacks("OnPressed")
		end
	end
	return util.EVENT_REPLY_HANDLED
end
function Element:OnThink()
	if self:IsActive() == false then
		return
	end
	if self:GetProgress() == 1.0 then
		self.m_progressBar:SetVisible(false)
	end
end
function Element:IsActive()
	return self:IsPressed()
end
function Element:SetActive(active)
	self:SetPressed(active)
end
function Element:OnActiveStateChanged(pressed)
	if util.is_valid(self.m_contentsPanel) then
		self.m_contentsPanel:SetVisible(pressed)
	end
end
gui.register("pfm_tab_button", Element)
