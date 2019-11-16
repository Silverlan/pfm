--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/fonts.lua")
include("/gui/vbox.lua")
include("/gui/pfm/button.lua")

util.register_class("gui.CollapsibleGroup",gui.Base)

function gui.CollapsibleGroup:__init()
	gui.Base.__init(self)
end
function gui.CollapsibleGroup:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(256,25)
	self.m_base = gui.create("WIVBox",self,0,0,self:GetWidth(),0)
	self.m_base:AddCallback("SetSize",function()
		self:SetHeight(self.m_base:GetHeight())
	end)

	self.m_bgTop = gui.create("WIRect",self.m_base,0,0,self.m_base:GetWidth(),20,0,0,1,0)
	self.m_contents = gui.create("WIVBox",self.m_base,0,0,self.m_base:GetWidth(),0)
	self.m_bgBottom = gui.create("WIRect",self.m_base,0,self.m_base:GetBottom() -5,self.m_base:GetWidth(),5,0,1,1,1)
	local bgColor = Color(40,40,45)
	self.m_bgTop:SetColor(bgColor)
	self.m_bgBottom:SetColor(bgColor)

	self.m_button = gui.PFMButton.create(self,"gui/pfm/arrow_right","gui/pfm/arrow_right",function()
		print("TODO")
	end)
	self.m_button:SetPos(7,8)
	self.m_button:AddCallback("OnMousePressed",function()
		self:Toggle()
	end)
	self.m_button:SetMouseInputEnabled(true)

	self.m_name = gui.create("WIText",self,36,6)
	self.m_name:SetFont("pfm_medium")
	self.m_name:SetColor(Color.White)

	self:Collapse()
end
function gui.CollapsibleGroup:OnSizeChanged(w,h)
	if(util.is_valid(self.m_base)) then self.m_base:SetWidth(w) end
	if(util.is_valid(self.m_contents)) then self.m_contents:SetWidth(w) end
end
function gui.CollapsibleGroup:Collapse()
	if(util.is_valid(self.m_contents)) then self.m_contents:SetVisible(false) end
	if(util.is_valid(self.m_button)) then
		self.m_button:SetMaterials("gui/pfm/arrow_right","gui/pfm/arrow_right")
	end
end
function gui.CollapsibleGroup:Expand()
	if(util.is_valid(self.m_contents)) then self.m_contents:SetVisible(true) end
	if(util.is_valid(self.m_button)) then
		self.m_button:SetMaterials("gui/pfm/arrow_down","gui/pfm/arrow_down")
	end
end
function gui.CollapsibleGroup:Toggle()
	if(util.is_valid(self.m_contents) == false) then return end
	if(self.m_contents:IsVisible()) then self:Collapse()
	else self:Expand() end
end
function gui.CollapsibleGroup:AddElement(el)
	if(util.is_valid(self.m_contents)) then
		el:SetParent(self.m_contents)
	end
end
function gui.CollapsibleGroup:SetGroupName(name)
	if(util.is_valid(self.m_name)) then
		self.m_name:SetText(name)
		self.m_name:SizeToContents()
	end
end
gui.register("WICollapsibleGroup",gui.CollapsibleGroup)
