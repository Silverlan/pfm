--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/vbox.lua")
include("/pfm/fonts.lua")

util.register_class("gui.PFMTreeView",gui.Base)

function gui.PFMTreeView:__init()
	gui.Base.__init(self)
end
function gui.PFMTreeView:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,19)
	self.m_rootElement = gui.create("WIPFMTreeViewElement",self)
	self.m_rootElement:SetWidth(self:GetWidth())
	self.m_rootElement:SetText("ROOT")

	self:SetAutoSizeToContents(false,true)
end
function gui.PFMTreeView:OnSizeChanged(w,h)
	if(util.is_valid(self.m_rootElement) == false) then return end
	self.m_rootElement:SetWidth(w)
end
function gui.PFMTreeView:GetRoot() return self.m_rootElement end
gui.register("WIPFMTreeView",gui.PFMTreeView)

------------------------

util.register_class("gui.PFMTreeViewElement",gui.Base)

function gui.PFMTreeViewElement:__init()
	gui.Base.__init(self)
end
function gui.PFMTreeViewElement:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,19)

	self.m_items = {}

	self.m_box = gui.create("WIVBox",self,0,0,self:GetWidth(),self:GetHeight())
	self.m_contents = gui.create("WIRect",self.m_box,0,0,self:GetWidth(),self:GetHeight(),0,0,1,0)

	--[[local box = gui.create("WIVBox",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,0)
	box:SetFixedWidth(true)
	self.m_bg = gui.create("WIRect",box,0,0,self:GetWidth(),self:GetHeight(),0,0,1,0)
	self.m_bg:SetColor(Color(math.random(128,255),math.random(128,255),math.random(128,255)))
	self.m_contents = gui.create("WIVBox",box,21,0)]]

	--self:Collapse()
	self:SetAutoSizeToContents(false,true) -- ????????
end
function gui.PFMTreeViewElement:OnSizeChanged(w,h)
	if(util.is_valid(self.m_box) == false) then return end
	print("SETTING NEW WIDTH TO: ",w)
	self.m_box:SetWidth(w)
	print(self.m_box:GetWidth(),self.m_box == _x)
end
function gui.PFMTreeViewElement:GetItems() return self.m_items end
function gui.PFMTreeViewElement:IsCollapsed() return self.m_contents:IsVisible() == false end
function gui.PFMTreeViewElement:Toggle()
	if(self:IsCollapsed()) then self:Expand()
	else self:Collapse() end
end
function gui.PFMTreeViewElement:Collapse()
	self.m_contents:SetVisible(false)
end
function gui.PFMTreeViewElement:Expand()
	self.m_contents:SetVisible(true)
end
function gui.PFMTreeViewElement:Clear()
	for _,item in ipairs(self.m_items) do
		if(item:IsValid()) then item:Remove() end
	end
	self.m_items = {}
end
function gui.PFMTreeViewElement:SetText(text)
	if(util.is_valid(self.m_text) == false) then
		self.m_text = gui.create("WIText",self.m_contents)
		self.m_text:SetColor(Color.Black)
	end
	self.m_text:SetText(text)
	self.m_text:SizeToContents()
end
function gui.PFMTreeViewElement:AddItem(text,fPopulate)
	local item = gui.create("WIPFMTreeViewElement",self.m_box)
	item:SetText(text)
	item.m_fPopulate = fPopulate
	table.insert(self.m_items,item)
end
gui.register("WIPFMTreeViewElement",gui.PFMTreeViewElement)
