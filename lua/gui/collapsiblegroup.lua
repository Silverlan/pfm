--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("collapsiblegrouptitlebar.lua")
include("/gui/vbox.lua")
include("/gui/hbox.lua")
include("/gui/pfm/button.lua")

util.register_class("gui.CollapsibleGroup",gui.Base)

function gui.CollapsibleGroup:__init()
	gui.Base.__init(self)
end
function gui.CollapsibleGroup:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(256,20)
	self.m_base = gui.create("WIVBox",self,0,0,self:GetWidth(),self:GetHeight())
	self.m_base:SetName("global_container")

	self.m_titleBar = gui.create("WICollapsibleGroupTitleBar",self.m_base,0,0,self.m_base:GetWidth(),self:GetHeight(),0,0,1,0)
	self.m_titleBar:SetName("titlebar")
	self.m_titleBar:AddCallback("OnCollapse",function()
		self:OnCollapse()
	end)
	self.m_titleBar:AddCallback("OnExpand",function()
		self:OnExpand()
	end)

	self.m_contents = gui.create("WIVBox",self.m_base,0,0,self.m_base:GetWidth(),self:GetHeight())
	self.m_contents:SetName("inner_contents")
	--[[self.m_bgBottom = gui.create("WIRect",self.m_base,0,self.m_base:GetBottom() -5,self.m_base:GetWidth(),5)--,0,1,1,1)
	local bgColor = Color(40,40,45)
	self.m_bgBottom:SetColor(bgColor)]]

	--[[self:AddCallback("OnTimelineUpdate",function(el,elWrapper,elTimeline)
		local x = elTimeline:ValueToXOffset(0.0)
		if(x < 0) then
			local w = elWrapper:GetWidth()
			w = w +elWrapper:GetX()
			elWrapper:SetX(0)
			elWrapper:SetWidth(w)
		end
	end)]]

	self:Collapse()
	self:SetAutoSizeToContents(false,true)
end
function gui.CollapsibleGroup:OnSizeChanged(w,h)
	if(util.is_valid(self.m_base)) then self.m_base:SetWidth(w) end
	--if(util.is_valid(self.m_contents)) then self.m_contents:SetWidth(w) end
end
function gui.CollapsibleGroup:AddGroup(groupName)
	if(util.is_valid(self.m_contents) == false) then return end
	local p = gui.create("WICollapsibleGroup",self.m_contents)
	p:SetName("group_" .. groupName)
	p:SetWidth(self.m_contents:GetWidth())
	p:SetGroupName(groupName)
	return p
end
function gui.CollapsibleGroup:Collapse()
	if(util.is_valid(self.m_titleBar)) then self.m_titleBar:Collapse() end
end
function gui.CollapsibleGroup:Expand()
	if(util.is_valid(self.m_titleBar)) then self.m_titleBar:Expand() end
end
function gui.CollapsibleGroup:OnCollapse()
	if(util.is_valid(self.m_contents)) then self.m_contents:SetVisible(false) end
end
function gui.CollapsibleGroup:OnExpand()
	if(util.is_valid(self.m_contents)) then self.m_contents:SetVisible(true) end
end
function gui.CollapsibleGroup:Toggle()
	if(util.is_valid(self.m_titleBar)) then self.m_titleBar:Toggle() end
end
function gui.CollapsibleGroup:AddElement(el)
	if(util.is_valid(self.m_contents)) then
		el:SetParent(self.m_contents)
	end
end
function gui.CollapsibleGroup:SetGroupName(name)
	if(util.is_valid(self.m_titleBar)) then self.m_titleBar:SetGroupName(name) end
end
gui.register("WICollapsibleGroup",gui.CollapsibleGroup)
