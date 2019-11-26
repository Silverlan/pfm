--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/fonts.lua")

util.register_class("gui.CollapsibleGroupTitleBar",gui.Base)

function gui.CollapsibleGroupTitleBar:__init()
	gui.Base.__init(self)
end
function gui.CollapsibleGroupTitleBar:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(256,20)
	self.m_bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_contents = gui.create("WIHBox",self,0,0,self:GetWidth(),20,0,0,1,0)
	self.m_bg:SetColor(Color(40,40,45))
	
	gui.create("WIBase",self.m_contents,0,0,7,1) -- Gap
	self.m_collapsed = false
	self.m_button = gui.PFMButton.create(self.m_contents,"gui/pfm/arrow_right","gui/pfm/arrow_right",function()
		self:Toggle()
	end)
	self.m_button:SetY(8)
	self.m_button:SetMouseInputEnabled(true)

	gui.create("WIBase",self.m_contents,0,0,24,1) -- Gap
	self.m_name = gui.create("WIText",self.m_contents,0,6)
	self.m_name:SetFont("pfm_medium")
	self.m_name:SetColor(Color(152,152,152))
end
function gui.CollapsibleGroupTitleBar:Collapse()
	self.m_collapsed = true
	if(util.is_valid(self.m_button)) then self.m_button:SetMaterials("gui/pfm/arrow_right","gui/pfm/arrow_right") end
	self:CallCallbacks("OnCollapse")
end
function gui.CollapsibleGroupTitleBar:Expand()
	self.m_collapsed = false
	if(util.is_valid(self.m_button)) then self.m_button:SetMaterials("gui/pfm/arrow_down","gui/pfm/arrow_down") end
	self:CallCallbacks("OnExpand")
end
function gui.CollapsibleGroupTitleBar:Toggle()
	if(self.m_collapsed) then self:Expand()
	else self:Collapse() end
end
function gui.CollapsibleGroupTitleBar:SetGroupName(name)
	if(util.is_valid(self.m_name)) then
		self.m_name:SetText(name)
		self.m_name:SizeToContents()
	end
end
gui.register("WICollapsibleGroupTitleBar",gui.CollapsibleGroupTitleBar)
