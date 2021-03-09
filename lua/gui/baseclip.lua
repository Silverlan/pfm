--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("selectionoutline.lua")

util.register_class("gui.BaseClip",gui.Base)

gui.BaseClip.TITLE_COLOR = Color.White
gui.BaseClip.TITLE_COLOR_SELECTED = Color(63,53,20)
gui.BaseClip.OUTLINE_COLOR = Color(182,182,182)

function gui.BaseClip:__init()
	gui.Base.__init(self)
end
function gui.BaseClip:OnInitialize()
	gui.Base.OnInitialize(self)

	local w = 128
	local h = 23
	self:SetSize(w,h)

	self.m_bg = gui.create("WIRect",self,0,0,w,h,0,0,1,1)
	self.m_bg:SetName("background")
	self.m_bg:SetColor(Color(121,121,121))

	self.m_bgOutline = gui.create("WIOutlinedRect",self,0,0,w,h,0,0,1,1)
	self.m_bgOutline:SetName("outline")
	self.m_bgOutline:SetColor(gui.BaseClip.OUTLINE_COLOR)
	self.m_bgOutline:SetOutlineWidth(2)

	self.m_selection = gui.create("WISelectionOutline",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_selection:SetVisible(false)
	self.m_selection:SetZPos(1)

	self.m_text = gui.create("WIText",self,4,0,w -8,14,0,0,1,0)
	self.m_text:SetFont("pfm_small")
	self.m_text:SetColor(gui.BaseClip.TITLE_COLOR)
	self.m_text:SetZPos(2)

	self:SetSelected(false)
end
function gui.BaseClip:SetText(text)
	if(util.is_valid(self.m_text) == false) then return end
	self.m_text:SetText(text)
	self.m_text:SizeToContents()
end
function gui.BaseClip:IsSelected() return self.m_selected end
function gui.BaseClip:SetSelected(selected)
	if(selected == self:IsSelected()) then return end
	self.m_selected = selected
	self.m_selection:SetVisible(selected)
	if(self.m_text:IsValid()) then
		self.m_text:SetColor(selected and Color(63,53,20) or Color.White)
	end
	if(selected) then self:CallCallbacks("OnSelected")
	else self:CallCallbacks("OnDeselected") end
end
