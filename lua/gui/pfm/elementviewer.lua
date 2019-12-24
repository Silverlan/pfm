--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("button.lua")
include("treeview.lua")
include("/gui/vbox.lua")
include("/gui/hbox.lua")
include("/gui/resizer.lua")
include("/pfm/history.lua")

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
		print("TODO")
	end)
	self.m_btTools:SetX(self:GetWidth() -self.m_btTools:GetWidth())

	self.m_contents = gui.create("WIHBox",self,
		0,self.m_btTools:GetBottom(),self:GetWidth(),self:GetHeight() -self.m_btTools:GetBottom(),
		0,0,1,1
	)
	self.m_contents:SetAutoFillContents(true)

	local treeVBox = gui.create("WIVBox",self.m_contents)
	treeVBox:SetFixedSize(true)
	local resizer = gui.create("WIResizer",self.m_contents)
	local dataVBox = gui.create("WIVBox",self.m_contents)
	dataVBox:SetFixedSize(true)

	local function create_header_text(text,parent)
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
	create_header_text(locale.get_text("tree"),treeVBox)
	create_header_text(locale.get_text("data"),dataVBox)

	self.m_tree = gui.create("WIPFMTreeView",treeVBox,0,0,treeVBox:GetWidth(),treeVBox:GetHeight(),0,0,1,1)
	self.m_tree:SetSelectable(gui.Table.SELECTABLE_MODE_SINGLE)
	self.m_data = gui.create("WIPFMTreeView",dataVBox,0,0,dataVBox:GetWidth(),dataVBox:GetHeight(),0,0,1,1)
	self.m_data:SetSelectable(gui.Table.SELECTABLE_MODE_SINGLE)

	self.m_treeElementToDataElement = {}
	self.m_history = pfm.History()
	self.m_history:AddCallback("OnPositionChanged",function(item,index)
		if(item ~= nil) then self:PopulateFromUDMData(item) end
		if(util.is_valid(self.m_btBack)) then self.m_btBack:SetEnabled(index > 1) end
		if(util.is_valid(self.m_btForward)) then self.m_btForward:SetEnabled(index < #self:GetHistory()) end
		if(util.is_valid(self.m_btUp)) then self.m_btUp:SetVisible(true) end -- TODO
	end)
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
	self.m_tree:Clear()
	self:AddUDMNode(rootNode,rootNode:GetName(),self.m_tree,self.m_tree)
	self.m_tree:Update()
	self:UpdateDataElementPositions()
end
function gui.PFMElementViewer:Setup(rootNode)
	self.m_rootNode = rootNode
	self:GetHistory():Clear()
	self:GetHistory():Add(rootNode)
end
function gui.PFMElementViewer:GetHistory() return self.m_history end
function gui.PFMElementViewer:MakeElementRoot(element)
	self:GetHistory():Add(element)
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
		elTreeChild:AddCallback("OnMouseEvent",function(elTreeChild,button,state,mods)
			if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
				local pContext = gui.open_context_menu()
				if(util.is_valid(pContext) == false) then return end
				pContext:SetPos(input.get_cursor_pos())
				pContext:AddItem(locale.get_text("pfm_make_root"),function()
					self:MakeElementRoot(node)
				end)
				pContext:Update()
			end
		end)
		text = node:GetTypeName()
	else
		elTreeChild = elTreeParent:AddItem(name)
		elTreeChild:Collapse()
		text = node:ToASCIIString()
	end

	local itemParent = self.m_treeElementToDataElement[elTreePrevious]
	local insertIndex
	if(util.is_valid(itemParent)) then
		insertIndex = itemParent:GetParent():FindChildIndex(itemParent)
		if(insertIndex ~= nil) then insertIndex = insertIndex +1 end
	end
	local item = self.m_data:AddItem(text,nil,insertIndex)
	--[[if(node:GetType() == udm.ATTRIBUTE_TYPE_BOOL) then
		local el = gui.create("WICheckbox")
		pRow:InsertElement(0,el)
		el:SetChecked(node:GetValue())
	else
		pRow:SetValue(0,text)
	end]]
	if(node:IsAttribute()) then
		--[[item:AddCallback("OnDoubleClick",function()
			local pEntry = gui.create("WITextEntry")
			pEntry:SetSize(item:GetSize())
			pEntry:SetAnchor(0,0,1,1)
			pEntry:SetText(node:ToASCIIString())
			item:InsertElement(0,pEntry)

			pEntry:RequestFocus()
			pEntry:AddCallback("OnTextEntered",function()
				pEntry:RemoveSafely()
				local newValue = pEntry:GetText()
				node:LoadFromASCIIString(newValue)
			end)
		end)]]
	end
	itemParent = item
	self.m_treeElementToDataElement[elTreeChild] = item

	--
	elTreeChild:AddCallback("OnRemove",function()
		if(self.m_data:IsValid() and item:IsValid()) then
			self.m_data:GetRoot():RemoveItem(item)
		end
	end)

	if(node:IsAttribute()) then
		node:AddChangeListener(function(newVal)
			-- TODO
			--if(item:IsValid()) then item:SetValue(0,node:ToASCIIString()) end
		end)
	end
	return elTreeChild
end
function gui.PFMElementViewer:OnSizeChanged(w,h)
	if(util.is_valid(self.m_btTools)) then self.m_btTools:SetX(self:GetWidth() -self.m_btTools:GetWidth()) end
end
function gui.PFMElementViewer:InitializeNavigationBar()
	self.m_btHome = gui.PFMButton.create(self.navBar,"gui/pfm/icon_nav_home","gui/pfm/icon_nav_home_activated",function()
		if(self.m_rootNode == nil) then return end
		self:GetHistory():Clear()
		self:GetHistory():Add(self.m_rootNode)
	end)
	gui.create("WIBase",self.navBar):SetSize(5,1) -- Gap

	self.m_btUp = gui.PFMButton.create(self.navBar,"gui/pfm/icon_nav_up","gui/pfm/icon_nav_up_activated",function()
		print("TODO")
	end)
	self.m_btUp:SetupContextMenu(function(pContext)
		print("TODO")
	end)

	gui.create("WIBase",self.navBar):SetSize(5,1) -- Gap

	self.m_btBack = gui.PFMButton.create(self.navBar,"gui/pfm/icon_nav_back","gui/pfm/icon_nav_back_activated",function()
		self:GetHistory():GoBack()
	end)
	self.m_btBack:SetupContextMenu(function(pContext)
		local history = self:GetHistory()
		local pos = history:GetCurrentPosition()
		if(pos > 1) then
			for i=pos -1,1,-1 do
				local el = history:Get(i)
				pContext:AddItem(el:GetName(),function()
					history:SetCurrentPosition(i)
				end)
			end
		end
		pContext:AddLine()
		pContext:AddItem(locale.get_text("pfm_reset_history"),function()
			history:Clear()
		end)
	end)

	gui.create("WIBase",self.navBar):SetSize(5,1) -- Gap

	self.m_btForward = gui.PFMButton.create(self.navBar,"gui/pfm/icon_nav_forward","gui/pfm/icon_nav_forward_activated",function()
		self:GetHistory():GoForward()
	end)
	self.m_btForward:SetupContextMenu(function(pContext)
		local history = self:GetHistory()
		local pos = history:GetCurrentPosition()
		local numItems = #history
		if(pos < numItems) then
			for i=pos +1,numItems do
				local el = history:Get(i)
				pContext:AddItem(el:GetName(),function()
					history:SetCurrentPosition(i)
				end)
			end
		end
		pContext:AddLine()
		pContext:AddItem(locale.get_text("pfm_reset_history"),function()
			history:Clear()
		end)
	end)
end
gui.register("WIPFMElementViewer",gui.PFMElementViewer)
