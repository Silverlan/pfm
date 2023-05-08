--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/pfm/progressbar.lua")

util.register_class("gui.PFMTabButton",gui.Base)

function gui.PFMTabButton:__init()
	gui.Base.__init(self)
end
function gui.PFMTabButton:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,32)
	self.m_bg = gui.create("WITexturedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetMaterial("gui/pfm/tab-selected")
	self.m_bg:GetColorProperty():Link(self:GetColorProperty())

	self.m_text = gui.create("WIText",self)
	self.m_text:SetColor(Color(152,152,152))
	self.m_text:SetFont("pfm_medium")

	self.m_progressBar = gui.create("WIPFMProgressBar",self,0,self:GetHeight() -5,self:GetWidth(),5,0,1,1,1)
	self.m_progressBar:SetVisible(false)

	local elDetach = gui.create("WITexturedRect",self)
	elDetach:SetMaterial("gui/pfm/icon_detach")
	elDetach:SetName("detach_icon")
	elDetach:SetCursor(gui.CURSOR_SHAPE_HAND)
	elDetach:SizeToTexture()
	elDetach:SetSize(8,8)
	elDetach:SetPos(self:GetWidth() -elDetach:GetWidth() -3,3)
	elDetach:SetAnchor(1,0,1,0)
	elDetach:SetColor(Color(200,200,200,255))
	elDetach:AddCallback("OnCursorEntered",function() elDetach:SetColor(Color.Aqua) end)
	elDetach:AddCallback("OnCursorExited",function() elDetach:SetColor(Color(200,200,200,255)) end)
	elDetach:SetMouseInputEnabled(true)
	elDetach:AddCallback("OnMouseEvent",function(elDetach,button,state,mods)
		local frame = self:GetFrame()
		if(util.is_valid(frame) == false) then return util.EVENT_REPLY_UNHANDLED end
		if(button == input.MOUSE_BUTTON_LEFT) then
			if(state == input.STATE_PRESS) then
				time.create_simple_timer(0.0,function()
					local frame = self:IsValid() and self:GetFrame() or nil
					if(util.is_valid(frame) == false) then return end
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

	local mat = self.m_bg:GetMaterial()
	if(mat == nil) then return end
	local texInfo = mat:GetTextureInfo("diffuse_map")
	if(texInfo == nil) then return end
	self:SetSize(texInfo:GetWidth(),texInfo:GetHeight())
end
function gui.PFMTabButton:SetFrame(frame) self.m_frame = frame end
function gui.PFMTabButton:GetFrame() return self.m_frame end
function gui.PFMTabButton:GetContents() return self.m_contentsPanel end
function gui.PFMTabButton:SetContents(panel)
	self.m_contentsPanel = panel
	panel:SetVisible(false)

	panel:AddCallback("OnProgressChanged",function(el,progress)
		self:SetProgress(progress)
	end)
end
function gui.PFMTabButton:SetProgress(progress)
	if(util.is_valid(self.m_progressBar) == false) then return end
	self.m_progressBar:SetProgress(progress)
	self.m_progressBar:SetVisible(progress > 0.0)
end
function gui.PFMTabButton:GetProgress()
	return util.is_valid(self.m_progressBar) and self.m_progressBar:GetProgress() or 0.0
end
function gui.PFMTabButton:MouseCallback(button,state,mods)
	if(button == input.MOUSE_BUTTON_LEFT) then
		if(state == input.STATE_RELEASE) then
			self:CallCallbacks("OnPressed")
		end
	end
	return util.EVENT_REPLY_HANDLED
end
function gui.PFMTabButton:OnThink()
	if(self:IsActive() == false) then return end
	if(self:GetProgress() == 1.0) then self.m_progressBar:SetVisible(false) end
end
function gui.PFMTabButton:IsActive() return self.m_active end
function gui.PFMTabButton:SetActive(active)
	self.m_active = active
	if(active) then self:SetColor(Color.White)
	else self:SetColor(Color(200,200,200)) end
	if(util.is_valid(self.m_contentsPanel)) then self.m_contentsPanel:SetVisible(active) end
end
function gui.PFMTabButton:GetText()
	return util.is_valid(self.m_text) and self.m_text:GetText() or ""
end
function gui.PFMTabButton:SetText(text)
	if(util.is_valid(self.m_text)) then
		self.m_text:SetText(text)
		self.m_text:SizeToContents()
		self.m_text:SetPos(
			self:GetWidth() *0.5 -self.m_text:GetWidth() *0.5,
			self:GetHeight() *0.5 -self.m_text:GetHeight() *0.5
		)
		self.m_text:SetAnchor(0.5,0.5,0.5,0.5)
	end
end
gui.register("WIPFMTabButton",gui.PFMTabButton)
