--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/pfm/progressbar.lua")
include("button.lua")

local Element = util.register_class("gui.PFMTabButton", gui.PFMBaseButton)
function Element:OnInitialize()
	gui.PFMBaseButton.OnInitialize(self)

	self:SetSize(128, 32)

	self:SetType(gui.PFMBaseButton.BUTTON_TYPE_TAB)

	self.m_progressBar = gui.create("WIPFMProgressBar", self, 0, self:GetHeight() - 5, self:GetWidth(), 5, 0, 1, 1, 1)
	self.m_progressBar:SetVisible(false)

	local elDetach = gui.create("WITexturedRect", self)
	elDetach:SetMaterial("gui/pfm/icon_detach")
	elDetach:SetName("detach_icon")
	elDetach:SetCursor(gui.CURSOR_SHAPE_HAND)
	elDetach:SizeToTexture()
	elDetach:SetSize(8, 8)
	elDetach:SetPos(self:GetWidth() - elDetach:GetWidth() - 3, 3)
	elDetach:SetAnchor(1, 0, 1, 0)
	elDetach:AddStyleClass("overlay")
	elDetach:AddCallback("OnCursorEntered", function()
		elDetach:SetColor(Color.Aqua)
	end)
	elDetach:AddCallback("OnCursorExited", function()
		elDetach:RefreshSkin()
	end)
	elDetach:SetMouseInputEnabled(true)
	elDetach:AddCallback("OnMouseEvent", function(elDetach, button, state, mods)
		local frame = self:GetFrame()
		if util.is_valid(frame) == false then
			return util.EVENT_REPLY_UNHANDLED
		end
		if button == input.MOUSE_BUTTON_LEFT then
			if state == input.STATE_PRESS then
				time.create_simple_timer(0.0, function()
					local frame = self:IsValid() and self:GetFrame() or nil
					if util.is_valid(frame) == false then
						return
					end
					frame:DetachTab(self)
				end)
			end
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)

	self:SetMouseInputEnabled(true)

	self:SetActive(false)
	self:EnableThinking()

	self:SetSize(132, 28)
end
function Element:SetFrame(frame)
	self.m_frame = frame
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
gui.register("WIPFMTabButton", Element)
