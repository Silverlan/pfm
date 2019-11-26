--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/fonts.lua")
include("selectionoutline.lua")

util.register_class("gui.GenericClip",gui.Base)

function gui.GenericClip:__init()
	gui.Base.__init(self)
end
function gui.GenericClip:OnInitialize()
	gui.Base.OnInitialize(self)

	local w = 128
	local h = 23
	self:SetSize(w,h)

	self.m_bg = gui.create("WIRect",self,0,0,w,h,0,0,1,1)
	self.m_bg:SetColor(Color(50,127,50))

	self.m_bgOutline = gui.create("WIOutlinedRect",self,0,0,w,h,0,0,1,1)
	self.m_bgOutline:SetColor(Color(152,152,152))
	self.m_bgOutline:SetOutlineWidth(2)

	self.m_selection = gui.create("WISelectionOutline",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_selection:SetVisible(false)

	self.m_text = gui.create("WIText",self,4,2,w -8,14,0,0,1,0)
	self.m_text:SetFont("pfm_small")
	self.m_text:SetColor(Color.White)

	self:SetMouseInputEnabled(true)
	self:AddCallback("OnMousePressed",function()
		self:SetSelected(true)
	end)
end
function gui.GenericClip:SetText(text)
	if(util.is_valid(self.m_text) == false) then return end
	self.m_text:SetText(text)
	self.m_text:SizeToContents()
end
function gui.GenericClip:SetSelected(selected)
	self.m_selection:SetVisible(selected)
	if(self.m_text:IsValid()) then
		self.m_text:SetColor(selected and Color(63,53,20) or Color.White)
	end
	if(selected) then self:CallCallbacks("OnSelected")
	else self:CallCallbacks("OnDeselected") end
end
gui.register("WIGenericClip",gui.GenericClip)
