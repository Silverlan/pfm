--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("button.lua")
include("/gui/vbox.lua")
include("/gui/hbox.lua")
include("/gui/resizer.lua")

util.register_class("gui.PFMElementViewer",gui.Base)

function gui.PFMElementViewer:__init()
	gui.Base.__init(self)
end
function gui.PFMElementViewer:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,128)

	self.m_bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetColor(Color(54,54,54))

	self.navBar = gui.create("WIHBox",self)
	self:InitializeNavigationBar()

	self.navBar:SetHeight(32)
	self.navBar:SetAnchor(0,0,1,0)

	self.m_btTools = gui.PFMButton.create(self,"gui/pfm/icon_gear","gui/pfm/icon_gear_activated",function()
		print("PRESS")
	end)
	self.m_btTools:SetX(self:GetWidth() -self.m_btTools:GetWidth())

	self.m_contents = gui.create("WIHBox",self,
		0,self.m_btTools:GetBottom(),self:GetWidth(),self:GetHeight() -self.m_btTools:GetBottom(),
		0,0,1,1
	)
	self.m_contents:SetFixedSize(true)

	local treeVBox = gui.create("WIVBox",self.m_contents)
	treeVBox:SetFixedSize(true)
	local resizer = gui.create("WIResizer",self.m_contents)
	local dataVBox = gui.create("WIVBox",self.m_contents)
	dataVBox:SetFixedSize(true)

	local function create_header_button(text,parent)
		local pHeader = gui.create("WIRect",parent,0,0,parent:GetWidth(),21,0,0,1,0)
		pHeader:SetColor(Color(35,35,35))
		local pHeaderText = gui.create("WIText",pHeader)
		pHeaderText:SetColor(Color(152,152,152))
		pHeaderText:SetFont("pfm_medium")
		pHeaderText:SetText(text)
		pHeaderText:SizeToContents()
		pHeader:AddCallback("SetSize",function()
			if(pHeaderText:IsValid() == false) then return end
			pHeaderText:SetPos(pHeader:GetWidth() *0.5 -pHeaderText:GetWidth() *0.5,pHeader:GetHeight() *0.5 -pHeaderText:GetHeight() *0.5)
		end)
	end
	create_header_button("Tree",treeVBox)
	create_header_button("Data",dataVBox)

	self.m_tree = gui.create("WITreeList",treeVBox,0,0,treeVBox:GetWidth(),treeVBox:GetHeight(),0,0,1,1)
	self.m_data = gui.create("WITable",dataVBox,0,0,dataVBox:GetWidth(),dataVBox:GetHeight(),0,0,1,1)

	self.m_data:SetRowHeight(self.m_tree:GetRowHeight())
	self.m_data:SetSelectable(true)

	self.m_treeElementToDataElement = {}
end
function gui.PFMElementViewer:UpdateDataElementPositions()
	if(util.is_valid(self.m_tree) == false) then return end
	local c = 0
	for elTree,elData in pairs(self.m_treeElementToDataElement) do
		c = c +1
		if(elTree:IsValid() and elData:IsValid()) then
			elData:SetPos(0,elTree:GetAbsolutePos().y -self.m_tree:GetAbsolutePos().y)
		else self.m_treeElementToDataElement[elTree] = nil end
	end
end
function gui.PFMElementViewer:PopulateFromUDMData(rootNode)
	if(util.is_valid(self.m_tree) == false) then return end
	self:AddUDMNode(rootNode,"root",self.m_tree,self.m_tree)
	self.m_tree:Update()
	self:UpdateDataElementPositions()
end
function gui.PFMElementViewer:AddUDMNode(node,name,elTreeParent,elTreePrevious)
	if(util.is_valid(self.m_data) == false) then return end
	local elTreeChild
	local text
	if(node:IsElement()) then
		elTreeChild = elTreeParent:AddItem(name,function(elTree)
			local elTreePrevious = elTree
			for name,child in pairs(node:GetChildren()) do
				elTreePrevious = self:AddUDMNode(child,name,elTree,elTreePrevious)
			end
			self:UpdateDataElementPositions()
		end)
		text = node:GetTypeName()
	else
		elTreeChild = elTreeParent:AddItem(name)
		elTreeChild:Collapse()
		text = node:ToASCIIString()
	end

	local pRow = self.m_data:AddRow()
	if(node:GetType() == udm.ATTRIBUTE_TYPE_BOOL) then
		local el = gui.create("WICheckbox")
		pRow:InsertElement(0,el)
		el:SetChecked(node:GetValue())
	else
		pRow:SetValue(0,text)
	end
	if(node:IsAttribute()) then
		pRow:AddCallback("OnDoubleClick",function()
			local pEntry = gui.create("WITextEntry")
			pEntry:SetSize(pRow:GetSize())
			pEntry:SetAnchor(0,0,1,1)
			pEntry:SetText(node:ToASCIIString())
			pRow:InsertElement(0,pEntry)

			pEntry:RequestFocus()
			pEntry:AddCallback("OnTextEntered",function()
				pEntry:RemoveSafely()
				local newValue = pEntry:GetText()
				node:LoadFromASCIIString(newValue)
			end)
		end)
	end
	local pRowParent = self.m_treeElementToDataElement[elTreePrevious]
	if(util.is_valid(pRowParent)) then
		self.m_data:MoveRow(pRow,pRowParent)
	end
	pRowParent = pRow
	self.m_treeElementToDataElement[elTreeChild] = pRow

	--
	elTreeChild:AddCallback("OnRemove",function()
		if(self.m_data:IsValid() and pRow:IsValid()) then
			self.m_data:RemoveRow(pRow:GetRowIndex())
		end
	end)

	if(node:IsAttribute()) then
		node:AddChangeListener(function(newVal)
			if(pRow:IsValid()) then pRow:SetValue(0,node:ToASCIIString()) end
		end)
	end
	return elTreeChild
end
function gui.PFMElementViewer:OnSizeChanged(w,h)
	if(util.is_valid(self.m_btTools)) then self.m_btTools:SetX(self:GetWidth() -self.m_btTools:GetWidth()) end
end
function gui.PFMElementViewer:InitializeNavigationBar()
	self.m_btHome = gui.PFMButton.create(self.navBar,"gui/pfm/icon_nav_home","gui/pfm/icon_nav_home_activated",function()
		print("PRESS")
	end)
	gui.create("WIBase",self.navBar):SetSize(5,1) -- Gap
	self.m_btUp = gui.PFMButton.create(self.navBar,"gui/pfm/icon_nav_up","gui/pfm/icon_nav_up_activated",function()
		print("PRESS")
	end)
	gui.create("WIBase",self.navBar):SetSize(5,1) -- Gap
	self.m_btBack = gui.PFMButton.create(self.navBar,"gui/pfm/icon_nav_back","gui/pfm/icon_nav_back_activated",function()
		print("PRESS")
	end)
	gui.create("WIBase",self.navBar):SetSize(5,1) -- Gap
	self.m_btForward = gui.PFMButton.create(self.navBar,"gui/pfm/icon_nav_forward","gui/pfm/icon_nav_forward_activated",function()
		print("PRESS")
	end)
end
gui.register("WIPFMElementViewer",gui.PFMElementViewer)
